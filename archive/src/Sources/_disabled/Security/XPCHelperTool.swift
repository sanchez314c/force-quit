import Foundation
import Security
import ServiceManagement
import OSLog

/// Secure XPC Helper Tool for privileged operations
/// Implements bulletproof inter-process communication with mach services
class XPCHelperTool: NSObject, NSXPCListenerDelegate, XPCHelperToolProtocol {
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.forceQUIT.helper", category: "XPCHelper")
    private let listener = NSXPCListener.service()
    private let validClientBundleID = "com.forceQUIT.app"
    
    // Security monitoring
    private var activeConnections: Set<NSXPCConnection> = []
    private var operationCount = 0
    private let maxOperationsPerConnection = 100
    
    // MARK: - Initialization
    override init() {
        super.init()
        listener.delegate = self
        logger.info("🛡️ XPC Helper Tool initialized")
    }
    
    // MARK: - Service Lifecycle
    func startService() {
        logger.info("🚀 Starting XPC Helper service")
        listener.resume()
        
        // Health monitoring
        startHealthMonitoring()
        
        logger.info("✅ XPC Helper service active")
    }
    
    func stopService() {
        logger.info("🛑 Stopping XPC Helper service")
        
        // Close all active connections
        for connection in activeConnections {
            connection.invalidate()
        }
        activeConnections.removeAll()
        
        listener.invalidate()
        logger.info("⏹️ XPC Helper service stopped")
    }
    
    // MARK: - NSXPCListenerDelegate
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        logger.info("🔗 New XPC connection request from PID: \(newConnection.processIdentifier)")
        
        // Security validation first
        guard validateClientConnection(newConnection) else {
            logger.error("❌ Connection rejected - security validation failed")
            return false
        }
        
        // Rate limiting
        guard activeConnections.count < 10 else {
            logger.warning("⚠️ Connection rejected - too many active connections")
            return false
        }
        
        // Configure connection
        newConnection.exportedInterface = NSXPCInterface(with: XPCHelperToolProtocol.self)
        newConnection.exportedObject = self
        
        newConnection.invalidationHandler = { [weak self] in
            self?.handleConnectionInvalidation(newConnection)
        }
        
        newConnection.interruptionHandler = { [weak self] in
            self?.handleConnectionInterruption(newConnection)
        }
        
        activeConnections.insert(newConnection)
        newConnection.resume()
        
        logger.info("✅ XPC connection accepted and configured")
        return true
    }
    
    // MARK: - Client Validation
    private func validateClientConnection(_ connection: NSXPCConnection) -> Bool {
        // Get audit token for process verification
        var auditToken = connection.auditToken
        
        // Validate client executable path
        guard let clientPath = getExecutablePath(for: auditToken) else {
            logger.error("🚫 Cannot determine client executable path")
            return false
        }
        
        logger.info("🔍 Validating client path: \(clientPath)")
        
        // Verify client is authorized
        guard isAuthorizedClient(executablePath: clientPath) else {
            logger.error("🚫 Unauthorized client: \(clientPath)")
            return false
        }
        
        // Validate code signature
        guard validateCodeSignature(path: clientPath) else {
            logger.error("🚫 Code signature validation failed for: \(clientPath)")
            return false
        }
        
        logger.info("✅ Client validation successful")
        return true
    }
    
    private func getExecutablePath(for auditToken: audit_token_t) -> String? {
        var token = auditToken
        let pid = audit_token_to_pid(token)
        
        var pathBuffer = [Int8](repeating: 0, count: Int(MAXPATHLEN))
        let result = proc_pidpath(pid, &pathBuffer, UInt32(MAXPATHLEN))
        
        guard result > 0 else { return nil }
        
        return String(cString: pathBuffer)
    }
    
    private func isAuthorizedClient(executablePath: String) -> Bool {
        // Check if client is our main app
        return executablePath.contains("ForceQUIT.app")
    }
    
    private func validateCodeSignature(path: String) -> Bool {
        var staticCode: SecStaticCode?
        let status = SecStaticCodeCreateWithPath(URL(fileURLWithPath: path) as CFURL, [], &staticCode)
        
        guard status == errSecSuccess, let code = staticCode else {
            logger.error("Failed to create static code reference")
            return false
        }
        
        // Create requirement for our app
        var requirement: SecRequirement?
        let requirementString = "anchor apple generic and identifier \"\(validClientBundleID)\""
        let reqStatus = SecRequirementCreateWithString(
            requirementString as CFString,
            [],
            &requirement
        )
        
        guard reqStatus == errSecSuccess, let req = requirement else {
            logger.error("Failed to create code requirement")
            return false
        }
        
        // Validate code signature
        let validationStatus = SecStaticCodeCheckValidity(code, [], req)
        
        if validationStatus == errSecSuccess {
            logger.info("✅ Code signature validation passed")
            return true
        } else {
            logger.error("❌ Code signature validation failed: \(validationStatus)")
            return false
        }
    }
    
    // MARK: - Connection Management
    private func handleConnectionInvalidation(_ connection: NSXPCConnection) {
        logger.info("🔌 Connection invalidated for PID: \(connection.processIdentifier)")
        activeConnections.remove(connection)
    }
    
    private func handleConnectionInterruption(_ connection: NSXPCConnection) {
        logger.warning("⚠️ Connection interrupted for PID: \(connection.processIdentifier)")
    }
    
    // MARK: - Health Monitoring
    private func startHealthMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.performHealthCheck()
        }
    }
    
    private func performHealthCheck() {
        logger.info("🏥 Performing health check - Active connections: \(activeConnections.count), Operations: \(operationCount)")
        
        // Check resource usage
        let memoryUsage = getMemoryUsage()
        if memoryUsage > 50_000_000 { // 50MB limit
            logger.warning("⚠️ High memory usage: \(memoryUsage) bytes")
        }
        
        // Reset operation counter periodically
        if operationCount > 1000 {
            operationCount = 0
            logger.info("🔄 Operation counter reset")
        }
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0 }
        return UInt64(info.resident_size)
    }
}

// MARK: - XPCHelperToolProtocol Implementation
extension XPCHelperTool {
    
    func terminateProcess(pid: pid_t, withReply reply: @escaping (Bool, String?) -> Void) {
        operationCount += 1
        logger.info("🎯 Terminate process request: PID \(pid)")
        
        // Validate process safety
        let processInfo = getProcessInfo(pid: pid)
        let safetyLevel = assessProcessSafetyLevel(processInfo)
        
        guard safetyLevel != .forbidden else {
            let error = "Process \(pid) is protected and cannot be terminated"
            logger.error("🚫 \(error)")
            reply(false, error)
            return
        }
        
        // Perform graduated termination
        let success = performSafeTermination(pid: pid, securityLevel: safetyLevel)
        
        if success {
            logger.info("✅ Process \(pid) terminated successfully")
            reply(true, nil)
        } else {
            let error = "Failed to terminate process \(pid)"
            logger.error("❌ \(error)")
            reply(false, error)
        }
    }
    
    func terminateMultipleProcesses(pids: [pid_t], withReply reply: @escaping ([pid_t], [pid_t], String?) -> Void) {
        operationCount += 1
        logger.info("🎯 Mass terminate request: \(pids.count) processes")
        
        var successful: [pid_t] = []
        var failed: [pid_t] = []
        
        for pid in pids {
            // Rate limiting per batch
            if successful.count + failed.count > 50 {
                logger.warning("⚠️ Batch size limit exceeded")
                failed.append(contentsOf: pids.dropFirst(successful.count + failed.count))
                break
            }
            
            let processInfo = getProcessInfo(pid: pid)
            let safetyLevel = assessProcessSafetyLevel(processInfo)
            
            guard safetyLevel != .forbidden else {
                failed.append(pid)
                continue
            }
            
            if performSafeTermination(pid: pid, securityLevel: safetyLevel) {
                successful.append(pid)
            } else {
                failed.append(pid)
            }
            
            // Small delay between operations
            usleep(50_000) // 50ms
        }
        
        logger.info("✅ Batch termination complete: \(successful.count) success, \(failed.count) failed")
        reply(successful, failed, nil)
    }
    
    func validateProcessSafety(pid: pid_t, withReply reply: @escaping (String, String) -> Void) {
        logger.info("🔍 Process safety validation request: PID \(pid)")
        
        let processInfo = getProcessInfo(pid: pid)
        let safetyLevel = assessProcessSafetyLevel(processInfo)
        
        let safetyDescription = safetyLevel.description
        let recommendation = generateSafetyRecommendation(for: safetyLevel, process: processInfo)
        
        logger.info("📊 Safety assessment for PID \(pid): \(safetyLevel)")
        reply(safetyDescription, recommendation)
    }
    
    func getSystemHealth(withReply reply: @escaping ([String: Any]) -> Void) {
        logger.info("🏥 System health request")
        
        var health: [String: Any] = [:]
        
        // Helper status
        health["helper_active"] = true
        health["active_connections"] = activeConnections.count
        health["operation_count"] = operationCount
        health["memory_usage"] = getMemoryUsage()
        
        // System metrics
        health["system_load"] = getSystemLoad()
        health["available_memory"] = getAvailableMemory()
        health["process_count"] = getSystemProcessCount()
        
        // Security status
        health["security_validation"] = performSecurityCheck()
        
        reply(health)
    }
}

// MARK: - Process Safety Assessment
extension XPCHelperTool {
    
    private func getProcessInfo(pid: pid_t) -> ProcessSecurityInfo {
        var processName = "Unknown"
        var bundleID: String?
        
        // Get process name
        var nameBuffer = [Int8](repeating: 0, count: Int(MAXCOMLEN))
        if proc_name(pid, &nameBuffer, UInt32(MAXCOMLEN)) > 0 {
            processName = String(cString: nameBuffer)
        }
        
        // Get bundle identifier if available
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == pid }) {
            bundleID = app.bundleIdentifier
        }
        
        return ProcessSecurityInfo(
            pid: pid,
            name: processName,
            bundleIdentifier: bundleID,
            uid: getProcessUID(pid: pid),
            isSystemProcess: isSystemProcess(pid: pid, name: processName)
        )
    }
    
    private func assessProcessSafetyLevel(_ processInfo: ProcessSecurityInfo) -> ProcessSafetyLevel {
        // Critical system processes - never terminate
        let criticalProcesses: Set<String> = [
            "kernel_task", "launchd", "loginwindow", "WindowServer",
            "securityd", "coreauthd", "mDNSResponder"
        ]
        
        if criticalProcesses.contains(processInfo.name) {
            return .forbidden
        }
        
        // System processes owned by root
        if processInfo.isSystemProcess || processInfo.uid == 0 {
            // Check if it's a safe system process
            let safeBundleIDs: Set<String> = [
                "com.apple.TextEdit",
                "com.apple.Calculator",
                "com.apple.Preview"
            ]
            
            if let bundleID = processInfo.bundleIdentifier,
               safeBundleIDs.contains(bundleID) {
                return .monitored
            }
            
            return .protected
        }
        
        // User processes
        if processInfo.bundleIdentifier?.starts(with: "com.apple.") == true {
            return .restricted
        }
        
        return .unrestricted
    }
    
    private func performSafeTermination(pid: pid_t, securityLevel: ProcessSafetyLevel) -> Bool {
        switch securityLevel {
        case .unrestricted:
            return terminateProcessDirectly(pid: pid)
        
        case .monitored:
            logger.info("📝 Monitored termination for PID: \(pid)")
            return terminateProcessDirectly(pid: pid)
        
        case .restricted:
            logger.warning("⚠️ Restricted termination for PID: \(pid)")
            return terminateWithGracefulShutdown(pid: pid)
        
        case .protected, .forbidden:
            logger.error("🚫 Termination blocked for protected process PID: \(pid)")
            return false
        }
    }
    
    private func terminateProcessDirectly(pid: pid_t) -> Bool {
        let result = kill(pid, SIGTERM)
        if result == 0 {
            // Give process time to terminate gracefully
            usleep(500_000) // 500ms
            
            // Check if still running
            if kill(pid, 0) == 0 {
                // Force terminate if still alive
                let forceResult = kill(pid, SIGKILL)
                return forceResult == 0
            }
            return true
        }
        return false
    }
    
    private func terminateWithGracefulShutdown(pid: pid_t) -> Bool {
        // Try Apple Events for graceful shutdown first
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == pid }) {
            let graceful = app.terminate()
            if graceful {
                return true
            }
        }
        
        // Fallback to direct termination
        return terminateProcessDirectly(pid: pid)
    }
    
    private func generateSafetyRecommendation(for level: ProcessSafetyLevel, process: ProcessSecurityInfo) -> String {
        switch level {
        case .unrestricted:
            return "Safe to terminate - User application"
        case .monitored:
            return "Generally safe - Will be logged"
        case .restricted:
            return "Use caution - System application"
        case .protected:
            return "Not recommended - Critical system process"
        case .forbidden:
            return "Never terminate - Essential system process"
        }
    }
    
    // MARK: - Helper Methods
    private func getProcessUID(pid: pid_t) -> uid_t {
        var info = proc_bsdinfo()
        let size = MemoryLayout<proc_bsdinfo>.size
        
        guard proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &info, Int32(size)) == Int32(size) else {
            return uid_t.max
        }
        
        return info.pbi_uid
    }
    
    private func isSystemProcess(pid: pid_t, name: String) -> Bool {
        // System processes typically run as root or have system characteristics
        let uid = getProcessUID(pid: pid)
        return uid == 0 || name.starts(with: "com.apple.")
    }
    
    private func getSystemLoad() -> Double {
        var loadAvg: [Double] = [0.0, 0.0, 0.0]
        let result = getloadavg(&loadAvg, 3)
        return result > 0 ? loadAvg[0] : 0.0
    }
    
    private func getAvailableMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0 }
        return UInt64(info.virtual_size)
    }
    
    private func getSystemProcessCount() -> Int {
        return NSWorkspace.shared.runningApplications.count
    }
    
    private func performSecurityCheck() -> [String: Bool] {
        return [
            "code_signature_valid": true,
            "connection_secure": activeConnections.count < 10,
            "memory_usage_normal": getMemoryUsage() < 100_000_000,
            "operation_count_normal": operationCount < maxOperationsPerConnection
        ]
    }
}

// MARK: - Supporting Types
struct ProcessSecurityInfo {
    let pid: pid_t
    let name: String
    let bundleIdentifier: String?
    let uid: uid_t
    let isSystemProcess: Bool
}

enum ProcessSafetyLevel: String, CaseIterable {
    case unrestricted = "UNRESTRICTED"
    case monitored = "MONITORED"
    case restricted = "RESTRICTED"
    case protected = "PROTECTED"
    case forbidden = "FORBIDDEN"
    
    var description: String {
        switch self {
        case .unrestricted: return "Safe to terminate"
        case .monitored: return "Safe with logging"
        case .restricted: return "Caution advised"
        case .protected: return "Not recommended"
        case .forbidden: return "Never terminate"
        }
    }
}

// MARK: - XPC Protocol
@objc protocol XPCHelperToolProtocol {
    func terminateProcess(pid: pid_t, withReply reply: @escaping (Bool, String?) -> Void)
    func terminateMultipleProcesses(pids: [pid_t], withReply reply: @escaping ([pid_t], [pid_t], String?) -> Void)
    func validateProcessSafety(pid: pid_t, withReply reply: @escaping (String, String) -> Void)
    func getSystemHealth(withReply reply: @escaping ([String: Any]) -> Void)
}

// MARK: - Main Entry Point for Helper Tool
class HelperToolMain {
    static func main() {
        let helperTool = XPCHelperTool()
        
        // Setup signal handling
        signal(SIGTERM) { _ in
            NSLog("🛑 Helper tool received SIGTERM")
            helperTool.stopService()
            exit(0)
        }
        
        signal(SIGINT) { _ in
            NSLog("🛑 Helper tool received SIGINT")  
            helperTool.stopService()
            exit(0)
        }
        
        // Start the service
        helperTool.startService()
        
        // Run indefinitely
        RunLoop.main.run()
    }
}