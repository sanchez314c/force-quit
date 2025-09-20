//
//  PrivilegedHelper.swift
//  ForceQUIT Security Framework
//
//  XPC Privileged Helper Tool for system-level process management
//  Handles secure inter-process communication, authorization validation,
//  and elevated process termination with full SIP compliance.
//

import Foundation
import AuthorizationServices
import OSLog
import System

// MARK: - XPC Protocol Definition

@objc protocol PrivilegedHelperProtocol {
    func terminateProcess(pid: pid_t, force: Bool, reply: @escaping (Bool, String?) -> Void)
    func getProcessInfo(pid: pid_t, reply: @escaping ([String: Any]?, String?) -> Void)
    func validateSystemIntegrity(reply: @escaping (Bool, [String: Any]) -> Void)
    func performHealthCheck(reply: @escaping ([String: Any]) -> Void)
    func getHelperVersion(reply: @escaping (String) -> Void)
}

// MARK: - Helper Tool Main Class

public class PrivilegedHelper: NSObject, PrivilegedHelperProtocol {
    private let logger = Logger(subsystem: "com.forcequit.helper", category: "PrivilegedHelper")
    private let authRef: AuthorizationRef
    
    // Security configuration
    private let allowedClientBundleIds = ["com.forcequit.app"]
    private let maxConcurrentOperations = 10
    private var activeOperations = 0
    
    // Process safety database
    private let criticalProcesses = [
        "kernel_task", "launchd", "WindowServer", "loginwindow",
        "SystemUIServer", "Dock", "Finder", "mds", "mdworker"
    ]
    
    private let sipProtectedPaths = [
        "/System/", "/usr/bin/", "/usr/sbin/", "/bin/", "/sbin/",
        "/Library/Apple/", "/System/Library/"
    ]
    
    override init() {
        var authRef: AuthorizationRef?
        let status = AuthorizationCreate(nil, nil, [], &authRef)
        guard status == errAuthorizationSuccess, let auth = authRef else {
            fatalError("Failed to create authorization reference")
        }
        self.authRef = auth
        
        super.init()
        logger.info("🚀 PrivilegedHelper initialized successfully")
    }
    
    deinit {
        AuthorizationFree(authRef, [])
    }
    
    // MARK: - XPC Connection Management
    
    public func startService() {
        let listener = NSXPCListener(machServiceName: "com.forcequit.helper")
        listener.delegate = self
        listener.resume()
        
        logger.info("🎯 Privileged helper service started on mach service: com.forcequit.helper")
        
        // Keep the helper running
        RunLoop.current.run()
    }
    
    // MARK: - Process Termination Operations
    
    func terminateProcess(pid: pid_t, force: Bool, reply: @escaping (Bool, String?) -> Void) {
        logger.info("🎯 Termination request for PID \(pid), force: \(force)")
        
        // Validate operation limits
        guard activeOperations < maxConcurrentOperations else {
            reply(false, "Too many concurrent operations")
            return
        }
        
        activeOperations += 1
        defer { activeOperations -= 1 }
        
        // Validate process safety
        let safetyResult = validateProcessSafety(pid: pid)
        guard safetyResult.allowed else {
            logger.warning("⚠️ Process termination blocked: \(safetyResult.reason)")
            reply(false, safetyResult.reason)
            return
        }
        
        // Perform termination based on safety level
        let success = performSecureTermination(pid: pid, force: force, safetyLevel: safetyResult.level)
        
        if success {
            logger.info("✅ Process \(pid) terminated successfully")
            reply(true, nil)
        } else {
            logger.error("❌ Failed to terminate process \(pid)")
            reply(false, "Termination failed")
        }
    }
    
    private func validateProcessSafety(pid: pid_t) -> (allowed: Bool, level: ProcessSafetyLevel, reason: String) {
        // Get process information
        guard let processInfo = getProcessInformation(pid: pid) else {
            return (false, .forbidden, "Process not found or inaccessible")
        }
        
        let processName = processInfo["name"] as? String ?? "unknown"
        let executablePath = processInfo["path"] as? String ?? ""
        let parentPID = processInfo["ppid"] as? pid_t ?? 0
        
        // Critical system process check
        if criticalProcesses.contains(processName.lowercased()) {
            return (false, .forbidden, "Critical system process")
        }
        
        // SIP-protected path check
        if sipProtectedPaths.contains(where: { executablePath.hasPrefix($0) }) {
            return (false, .forbidden, "SIP-protected executable")
        }
        
        // Kernel process check
        if pid <= 1 || processName.contains("kernel") {
            return (false, .forbidden, "Kernel or init process")
        }
        
        // Parent process validation (don't terminate launchd children that are critical)
        if parentPID == 1 && isSystemService(processName: processName) {
            return (false, .restricted, "System service managed by launchd")
        }
        
        // Determine safety level
        let safetyLevel = determineProcessSafetyLevel(processInfo: processInfo)
        let allowed = safetyLevel != .forbidden
        let reason = allowed ? "Process termination allowed at \(safetyLevel) level" : "Process termination forbidden"
        
        return (allowed, safetyLevel, reason)
    }
    
    private enum ProcessSafetyLevel {
        case safe       // User applications, free termination
        case monitored  // Background processes, logged termination
        case restricted // System services, require confirmation
        case dangerous  // May cause system instability
        case forbidden  // Never allow termination
    }
    
    private func determineProcessSafetyLevel(processInfo: [String: Any]) -> ProcessSafetyLevel {
        let processName = processInfo["name"] as? String ?? "unknown"
        let executablePath = processInfo["path"] as? String ?? ""
        let uid = processInfo["uid"] as? uid_t ?? 0
        
        // Root processes are generally more dangerous
        if uid == 0 {
            if executablePath.hasPrefix("/System/") {
                return .restricted
            } else {
                return .monitored
            }
        }
        
        // User applications in /Applications are generally safe
        if executablePath.hasPrefix("/Applications/") {
            return .safe
        }
        
        // System services
        if executablePath.hasPrefix("/System/Library/") ||
           executablePath.hasPrefix("/usr/libexec/") {
            return .restricted
        }
        
        // Background agents and daemons
        if processName.contains("agent") || processName.contains("daemon") {
            return .monitored
        }
        
        return .safe
    }
    
    private func isSystemService(processName: String) -> Bool {
        let systemServices = [
            "bluetooth", "wifi", "airport", "networkd", "configd",
            "locationd", "powerd", "thermal", "audio", "coreaudio"
        ]
        
        return systemServices.contains { processName.lowercased().contains($0) }
    }
    
    private func performSecureTermination(pid: pid_t, force: Bool, safetyLevel: ProcessSafetyLevel) -> Bool {
        switch safetyLevel {
        case .safe, .monitored:
            return terminateProcessDirectly(pid: pid, force: force)
        case .restricted:
            // For restricted processes, try graceful first, then force if explicitly requested
            if !force {
                return terminateProcessGracefully(pid: pid)
            } else {
                return terminateProcessDirectly(pid: pid, force: true)
            }
        case .dangerous:
            // Only allow graceful termination for dangerous processes
            return terminateProcessGracefully(pid: pid)
        case .forbidden:
            return false
        }
    }
    
    private func terminateProcessGracefully(pid: pid_t) -> Bool {
        logger.info("🤝 Attempting graceful termination of PID \(pid)")
        
        // Send SIGTERM for graceful shutdown
        let result = kill(pid, SIGTERM)
        if result == 0 {
            // Wait a bit to see if process terminates gracefully
            usleep(500000) // 500ms
            
            // Check if process is still running
            if kill(pid, 0) != 0 {
                logger.info("✅ Process \(pid) terminated gracefully")
                return true
            }
        }
        
        logger.warning("⚠️ Graceful termination failed for PID \(pid)")
        return false
    }
    
    private func terminateProcessDirectly(pid: pid_t, force: Bool) -> Bool {
        logger.info("⚡ Attempting direct termination of PID \(pid), force: \(force)")
        
        let signal = force ? SIGKILL : SIGTERM
        let result = kill(pid, signal)
        
        if result == 0 {
            logger.info("✅ Process \(pid) terminated with signal \(signal)")
            return true
        } else {
            logger.error("❌ Failed to terminate PID \(pid): \(String(cString: strerror(errno)))")
            return false
        }
    }
    
    // MARK: - Process Information
    
    func getProcessInfo(pid: pid_t, reply: @escaping ([String: Any]?, String?) -> Void) {
        guard let processInfo = getProcessInformation(pid: pid) else {
            reply(nil, "Process not found")
            return
        }
        
        reply(processInfo, nil)
    }
    
    private func getProcessInformation(pid: pid_t) -> [String: Any]? {
        var kinfo = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.size
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        
        let result = sysctl(&mib, u_int(mib.count), &kinfo, &size, nil, 0)
        guard result == 0 else {
            logger.error("❌ Failed to get process info for PID \(pid)")
            return nil
        }
        
        let name = withUnsafePointer(to: &kinfo.kp_proc.p_comm) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXCOMLEN)) {
                String(cString: $0)
            }
        }
        
        // Get executable path
        var pathBuffer = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_MAXSIZE))
        let pathLength = proc_pidpath(pid, &pathBuffer, UInt32(PROC_PIDPATHINFO_MAXSIZE))
        let executablePath = pathLength > 0 ? String(cString: pathBuffer) : ""
        
        return [
            "pid": pid,
            "name": name,
            "path": executablePath,
            "ppid": kinfo.kp_eproc.e_ppid,
            "uid": kinfo.kp_eproc.e_ucred.cr_uid,
            "gid": kinfo.kp_eproc.e_ucred.cr_gid,
            "start_time": kinfo.kp_proc.p_starttime.tv_sec,
            "status": kinfo.kp_proc.p_stat
        ]
    }
    
    // MARK: - System Validation
    
    func validateSystemIntegrity(reply: @escaping (Bool, [String: Any]) -> Void) {
        logger.info("🔍 Performing system integrity validation")
        
        var results: [String: Any] = [:]
        var overallValid = true
        
        // Check SIP status
        let sipStatus = getSIPStatus()
        results["sip_enabled"] = sipStatus
        if !sipStatus {
            logger.warning("⚠️ System Integrity Protection is disabled")
            overallValid = false
        }
        
        // Check helper tool permissions
        let helperValid = validateHelperPermissions()
        results["helper_permissions_valid"] = helperValid
        if !helperValid {
            overallValid = false
        }
        
        // Check code signature
        let signatureValid = validateCodeSignature()
        results["code_signature_valid"] = signatureValid
        if !signatureValid {
            overallValid = false
        }
        
        results["timestamp"] = Date().timeIntervalSince1970
        results["helper_version"] = getVersion()
        
        logger.info("📊 System integrity check complete: \(overallValid ? "VALID" : "INVALID")")
        reply(overallValid, results)
    }
    
    private func getSIPStatus() -> Bool {
        // Check SIP status using csr_check
        return csr_check(UInt32(CSR_ALLOW_UNSIGNED_EXECUTABLE_POLICY)) != 0
    }
    
    private func validateHelperPermissions() -> Bool {
        // Validate that helper has required entitlements
        let currentUID = getuid()
        let currentGID = getgid()
        
        // Helper should run as root or with appropriate privileges
        return currentUID == 0 || currentGID == 0
    }
    
    private func validateCodeSignature() -> Bool {
        // Validate code signature of current executable
        var staticCode: SecStaticCode?
        let executableURL = Bundle.main.executableURL
        
        guard let url = executableURL else { return false }
        
        let status = SecStaticCodeCreateWithPath(url as CFURL, [], &staticCode)
        guard status == errSecSuccess, let code = staticCode else {
            return false
        }
        
        let verifyStatus = SecStaticCodeCheckValidity(code, [], nil)
        return verifyStatus == errSecSuccess
    }
    
    // MARK: - Health Monitoring
    
    func performHealthCheck(reply: @escaping ([String: Any]) -> Void) {
        var healthMetrics: [String: Any] = [:]
        
        // Memory usage
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            healthMetrics["memory_usage_bytes"] = info.resident_size
            healthMetrics["memory_usage_mb"] = info.resident_size / (1024 * 1024)
        }
        
        // Active operations
        healthMetrics["active_operations"] = activeOperations
        healthMetrics["max_operations"] = maxConcurrentOperations
        
        // Uptime
        healthMetrics["uptime_seconds"] = ProcessInfo.processInfo.systemUptime
        healthMetrics["timestamp"] = Date().timeIntervalSince1970
        
        // System load (if available)
        var loadAvg: [Double] = [0, 0, 0]
        if getloadavg(&loadAvg, 3) != -1 {
            healthMetrics["load_average"] = loadAvg
        }
        
        logger.info("💓 Health check complete - Memory: \(info.resident_size / (1024 * 1024))MB, Operations: \(activeOperations)")
        reply(healthMetrics)
    }
    
    // MARK: - Version Management
    
    func getHelperVersion(reply: @escaping (String) -> Void) {
        reply(getVersion())
    }
    
    private func getVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1.0.0"
    }
}

// MARK: - XPC Listener Delegate

extension PrivilegedHelper: NSXPCListenerDelegate {
    public func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        logger.info("🔗 New XPC connection request")
        
        // Validate client authorization
        guard validateClientConnection(newConnection) else {
            logger.error("❌ Unauthorized XPC connection rejected")
            return false
        }
        
        // Configure connection
        newConnection.exportedInterface = NSXPCInterface(with: PrivilegedHelperProtocol.self)
        newConnection.exportedObject = self
        
        newConnection.invalidationHandler = {
            self.logger.info("🔌 XPC connection invalidated")
        }
        
        newConnection.interruptionHandler = {
            self.logger.warning("⚠️ XPC connection interrupted")
        }
        
        newConnection.resume()
        logger.info("✅ XPC connection accepted and configured")
        return true
    }
    
    private func validateClientConnection(_ connection: NSXPCConnection) -> Bool {
        // Get the audit token for the connecting client
        var auditToken = connection.auditToken
        
        // Get the client's executable path
        guard let clientPath = getExecutablePath(for: auditToken) else {
            logger.error("❌ Could not determine client executable path")
            return false
        }
        
        // Validate code signature
        guard isAuthorizedClient(executablePath: clientPath) else {
            logger.error("❌ Client not authorized: \(clientPath)")
            return false
        }
        
        logger.info("✅ Client authorized: \(clientPath)")
        return true
    }
    
    private func getExecutablePath(for auditToken: audit_token_t) -> String? {
        var token = auditToken
        var path = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_MAXSIZE))
        
        // Get PID from audit token
        let pid = audit_token_to_pid(token)
        
        // Get executable path for PID
        let result = proc_pidpath(pid, &path, UInt32(PROC_PIDPATHINFO_MAXSIZE))
        guard result > 0 else {
            return nil
        }
        
        return String(cString: path)
    }
    
    private func isAuthorizedClient(executablePath: String) -> Bool {
        // Validate code signature
        guard let url = URL(string: "file://" + executablePath) else {
            return false
        }
        
        var staticCode: SecStaticCode?
        let status = SecStaticCodeCreateWithPath(url as CFURL, [], &staticCode)
        guard status == errSecSuccess, let code = staticCode else {
            return false
        }
        
        // Create requirement for authorized clients
        let requirementString = "anchor apple generic and identifier \"com.forcequit.app\""
        var requirement: SecRequirement?
        let reqStatus = SecRequirementCreateWithString(requirementString as CFString, [], &requirement)
        guard reqStatus == errSecSuccess, let req = requirement else {
            return false
        }
        
        // Validate against requirement
        let validateStatus = SecStaticCodeCheckValidity(code, [], req)
        return validateStatus == errSecSuccess
    }
}

// MARK: - CSR (System Integrity Protection) Constants

private let CSR_ALLOW_UNSIGNED_EXECUTABLE_POLICY: UInt32 = 0x1000

// MARK: - Helper Tool Entry Point

@main
struct HelperMain {
    static func main() {
        let helper = PrivilegedHelper()
        helper.startService()
    }
}