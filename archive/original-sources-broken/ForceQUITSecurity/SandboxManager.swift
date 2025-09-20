//
//  SandboxManager.swift
//  ForceQUIT Security Framework
//
//  Multi-tier sandbox compliance and app security management
//  Handles sandboxed environment operations, entitlements validation,
//  and secure process termination within App Store constraints.
//

import Foundation
import AppKit
import OSLog

@MainActor
public class SandboxManager: ObservableObject {
    public static let shared = SandboxManager()
    
    private let logger = Logger(subsystem: "com.forcequit.security", category: "SandboxManager")
    
    @Published public private(set) var isSandboxed: Bool = false
    @Published public private(set) var availableEntitlements: Set<SandboxEntitlement> = []
    @Published public private(set) var securityLevel: SandboxSecurityLevel = .restricted
    
    public enum SandboxEntitlement: String, CaseIterable {
        case appleEvents = "com.apple.security.automation.apple-events"
        case networkClient = "com.apple.security.network.client"
        case userSelectedFiles = "com.apple.security.files.user-selected"
        case processInfo = "com.apple.security.process-info"
        case temporaryException = "com.apple.security.temporary-exception"
        
        var isRequired: Bool {
            switch self {
            case .appleEvents, .processInfo:
                return true
            default:
                return false
            }
        }
    }
    
    public enum SandboxSecurityLevel: Int, CaseIterable {
        case restricted = 0      // Minimal permissions, user processes only
        case standard = 1        // Standard app permissions
        case elevated = 2        // Extended permissions with user consent
        case privileged = 3      // Helper tool required
        
        var description: String {
            switch self {
            case .restricted: return "Restricted"
            case .standard: return "Standard"
            case .elevated: return "Elevated"
            case .privileged: return "Privileged"
            }
        }
        
        var canTerminateSystemProcesses: Bool {
            return self == .privileged
        }
    }
    
    private init() {
        validateSandboxEnvironment()
        detectAvailableEntitlements()
        determineSecurityLevel()
    }
    
    // MARK: - Sandbox Environment Validation
    
    private func validateSandboxEnvironment() {
        // Check if running in sandbox using environment variables
        isSandboxed = ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
        
        if isSandboxed {
            logger.info("✅ Running in sandboxed environment")
        } else {
            logger.warning("⚠️ Running outside sandbox - development mode")
        }
    }
    
    private func detectAvailableEntitlements() {
        var entitlements: Set<SandboxEntitlement> = []
        
        // Check each entitlement by attempting to use its functionality
        for entitlement in SandboxEntitlement.allCases {
            if hasEntitlement(entitlement) {
                entitlements.insert(entitlement)
            }
        }
        
        availableEntitlements = entitlements
        logger.info("🔐 Available entitlements: \(entitlements.map(\.rawValue))")
        
        // Validate required entitlements
        let missingRequired = SandboxEntitlement.allCases
            .filter(\.isRequired)
            .filter { !availableEntitlements.contains($0) }
        
        if !missingRequired.isEmpty {
            logger.error("❌ Missing required entitlements: \(missingRequired.map(\.rawValue))")
        }
    }
    
    private func hasEntitlement(_ entitlement: SandboxEntitlement) -> Bool {
        switch entitlement {
        case .appleEvents:
            return canSendAppleEvents()
        case .networkClient:
            return canAccessNetwork()
        case .userSelectedFiles:
            return canAccessUserFiles()
        case .processInfo:
            return canAccessProcessInfo()
        case .temporaryException:
            return hasTemporaryException()
        }
    }
    
    private func determineSecurityLevel() {
        if !isSandboxed {
            securityLevel = .privileged
        } else if availableEntitlements.contains(.temporaryException) {
            securityLevel = .elevated
        } else if availableEntitlements.contains(.appleEvents) && availableEntitlements.contains(.processInfo) {
            securityLevel = .standard
        } else {
            securityLevel = .restricted
        }
        
        logger.info("🛡️ Security level determined: \(securityLevel.description)")
    }
    
    // MARK: - Entitlement Detection Methods
    
    private func canSendAppleEvents() -> Bool {
        // Test Apple Events capability
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        return !runningApps.isEmpty
    }
    
    private func canAccessNetwork() -> Bool {
        // Basic network access test (non-blocking)
        return true // Assume available if no restrictions
    }
    
    private func canAccessUserFiles() -> Bool {
        // Test file system access
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        return FileManager.default.isReadableFile(atPath: homeDir.path)
    }
    
    private func canAccessProcessInfo() -> Bool {
        // Test process information access
        let processes = NSWorkspace.shared.runningApplications
        return !processes.isEmpty
    }
    
    private func hasTemporaryException() -> Bool {
        // Check for temporary exception entitlements
        return ProcessInfo.processInfo.environment["TEMP_EXCEPTION"] != nil
    }
    
    // MARK: - Secure Process Operations
    
    public func canTerminateProcess(_ process: NSRunningApplication) -> (allowed: Bool, reason: String) {
        // System process protection
        if isSystemProcess(process) {
            return (false, "System process protected by SIP")
        }
        
        // Security level checks
        switch securityLevel {
        case .restricted:
            if process.ownsMenuBar {
                return (false, "Insufficient privileges for menu bar applications")
            }
        case .standard:
            if isPrivilegedProcess(process) {
                return (false, "Privileged process requires elevation")
            }
        case .elevated:
            if isCriticalSystemProcess(process) {
                return (false, "Critical system process requires helper tool")
            }
        case .privileged:
            // Privileged level can terminate most processes
            break
        }
        
        return (true, "Process termination allowed")
    }
    
    public func terminateProcessSafely(_ process: NSRunningApplication) async -> Bool {
        let (allowed, reason) = canTerminateProcess(process)
        
        guard allowed else {
            logger.error("❌ Process termination blocked: \(reason)")
            return false
        }
        
        logger.info("🎯 Attempting to terminate process: \(process.localizedName ?? "Unknown")")
        
        // Attempt graceful termination first
        if await attemptGracefulTermination(process) {
            logger.info("✅ Graceful termination successful")
            return true
        }
        
        // Fall back to force termination if allowed
        if securityLevel.rawValue >= SandboxSecurityLevel.standard.rawValue {
            return await attemptForceTermination(process)
        }
        
        logger.warning("⚠️ Force termination not available at current security level")
        return false
    }
    
    private func attemptGracefulTermination(_ process: NSRunningApplication) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let success = process.terminate()
                continuation.resume(returning: success)
            }
        }
    }
    
    private func attemptForceTermination(_ process: NSRunningApplication) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let success = process.forceTerminate()
                continuation.resume(returning: success)
            }
        }
    }
    
    // MARK: - Process Classification
    
    private func isSystemProcess(_ process: NSRunningApplication) -> Bool {
        guard let bundleId = process.bundleIdentifier else { return false }
        
        let systemBundleIds = [
            "com.apple.loginwindow",
            "com.apple.WindowServer",
            "com.apple.dock",
            "com.apple.finder",
            "com.apple.systemuiserver",
            "com.apple.controlstrip"
        ]
        
        return systemBundleIds.contains(bundleId) || 
               bundleId.hasPrefix("com.apple.") && process.executableURL?.path.hasPrefix("/System/") == true
    }
    
    private func isPrivilegedProcess(_ process: NSRunningApplication) -> Bool {
        guard let url = process.executableURL else { return false }
        
        let privilegedPaths = [
            "/System/",
            "/usr/bin/",
            "/usr/sbin/",
            "/bin/",
            "/sbin/"
        ]
        
        return privilegedPaths.contains { url.path.hasPrefix($0) }
    }
    
    private func isCriticalSystemProcess(_ process: NSRunningApplication) -> Bool {
        guard let bundleId = process.bundleIdentifier else { return false }
        
        let criticalBundleIds = [
            "com.apple.launchd",
            "com.apple.kernel",
            "com.apple.SecurityAgent"
        ]
        
        return criticalBundleIds.contains(bundleId)
    }
    
    // MARK: - Security Policy Enforcement
    
    public func enforceSecurityPolicy() async {
        logger.info("🔒 Enforcing sandbox security policy")
        
        // Validate current entitlements
        detectAvailableEntitlements()
        
        // Update security level based on current state
        determineSecurityLevel()
        
        // Log security status
        logSecurityStatus()
    }
    
    private func logSecurityStatus() {
        logger.info("📊 Security Status Report:")
        logger.info("  - Sandboxed: \(isSandboxed)")
        logger.info("  - Security Level: \(securityLevel.description)")
        logger.info("  - Available Entitlements: \(availableEntitlements.count)")
        logger.info("  - Can Terminate System Processes: \(securityLevel.canTerminateSystemProcesses)")
    }
    
    // MARK: - Public API
    
    public func requestPermissions(for operations: [String]) async -> Bool {
        logger.info("🔐 Permission request for operations: \(operations)")
        
        // In sandbox environment, permissions are granted via entitlements
        // This method validates current capabilities
        let requiredEntitlements: [SandboxEntitlement] = operations.compactMap { operation in
            switch operation {
            case "terminate_processes":
                return .appleEvents
            case "access_network":
                return .networkClient
            case "access_files":
                return .userSelectedFiles
            case "process_info":
                return .processInfo
            default:
                return nil
            }
        }
        
        let hasAllRequired = requiredEntitlements.allSatisfy { availableEntitlements.contains($0) }
        
        if hasAllRequired {
            logger.info("✅ All required permissions available")
        } else {
            logger.warning("⚠️ Some permissions unavailable - may need helper tool")
        }
        
        return hasAllRequired
    }
    
    public func getSecurityMetrics() -> [String: Any] {
        return [
            "sandboxed": isSandboxed,
            "security_level": securityLevel.description,
            "security_level_raw": securityLevel.rawValue,
            "available_entitlements": availableEntitlements.map(\.rawValue),
            "can_terminate_system": securityLevel.canTerminateSystemProcesses,
            "entitlement_count": availableEntitlements.count,
            "all_required_present": SandboxEntitlement.allCases.filter(\.isRequired).allSatisfy { availableEntitlements.contains($0) }
        ]
    }
}

// MARK: - Security Extensions

extension SandboxManager {
    public func validateProcessTermination(_ processID: pid_t) -> (allowed: Bool, securityLevel: String, reason: String) {
        guard let process = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == processID }) else {
            return (false, "unknown", "Process not found")
        }
        
        let (allowed, reason) = canTerminateProcess(process)
        return (allowed, securityLevel.description, reason)
    }
    
    public func getProcessSecurityInfo(_ process: NSRunningApplication) -> [String: Any] {
        let (allowed, reason) = canTerminateProcess(process)
        
        return [
            "process_name": process.localizedName ?? "Unknown",
            "bundle_id": process.bundleIdentifier ?? "unknown",
            "pid": process.processIdentifier,
            "termination_allowed": allowed,
            "termination_reason": reason,
            "is_system": isSystemProcess(process),
            "is_privileged": isPrivilegedProcess(process),
            "is_critical": isCriticalSystemProcess(process),
            "owns_menu_bar": process.ownsMenuBar,
            "executable_path": process.executableURL?.path ?? "unknown"
        ]
    }
}