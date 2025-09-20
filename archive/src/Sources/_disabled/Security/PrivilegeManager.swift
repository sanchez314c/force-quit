import Foundation
import Security
import ServiceManagement
import OSLog

// SWARM 2.0 ForceQUIT - Multi-Tier Security Architecture
// Tier 1: Sandboxed operations (90% use cases)
// Tier 2: Privileged helper (advanced operations)

@MainActor
class PrivilegeManager: ObservableObject {
    // MARK: - Published Properties
    @Published var authorizationStatus: AuthorizationStatus = .notRequested
    @Published var helperStatus: HelperStatus = .notInstalled
    @Published var availablePermissions: Set<Permission> = []
    @Published var lastError: SecurityError?
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.forceQUIT.app", category: "Security")
    private var authorizationRef: AuthorizationRef?
    private let helperToolLabel = "com.forceQUIT.helper"
    
    init() {
        checkInitialPermissions()
        checkHelperStatus()
    }
    
    deinit {
        if let authRef = authorizationRef {
            AuthorizationFree(authRef, kAuthorizationFlagDefaults)
        }
    }
    
    // MARK: - Permission Checking
    private func checkInitialPermissions() {
        // Check what permissions we currently have
        availablePermissions = []
        
        // Basic user-level permissions (always available)
        availablePermissions.insert(.userProcesses)
        
        // Check for additional permissions
        if canAccessSystemEvents() {
            availablePermissions.insert(.systemEvents)
        }
        
        if hasAdminRights() {
            availablePermissions.insert(.adminOperations)
        }
        
        logger.info("Available permissions: \\(availablePermissions)")
    }
    
    private func canAccessSystemEvents() -> Bool {
        // Check if we can access system events for app monitoring
        let workspace = NSWorkspace.shared
        return workspace.runningApplications.count > 0
    }
    
    private func hasAdminRights() -> Bool {
        // Check if user is in admin group
        let adminGroup = getgrgid(80) // admin group ID on macOS
        return adminGroup != nil
    }
    
    // MARK: - Authorization Requests
    func requestBasicAuthorization() async -> Bool {
        authorizationStatus = .requesting
        
        do {
            let success = try await createAuthorization()
            if success {
                authorizationStatus = .authorized
                availablePermissions.insert(.basicOperations)
                logger.info("Basic authorization granted")
                return true
            } else {
                authorizationStatus = .denied
                logger.warning("Basic authorization denied")
                return false
            }
        } catch {
            authorizationStatus = .failed
            lastError = .authorizationFailed(error.localizedDescription)
            logger.error("Authorization failed: \\(error.localizedDescription)")
            return false
        }
    }
    
    func requestAdminAuthorization() async -> Bool {
        authorizationStatus = .requesting
        
        do {
            let success = try await createAdminAuthorization()
            if success {
                authorizationStatus = .authorizedAdmin
                availablePermissions.insert(.adminOperations)
                availablePermissions.insert(.systemProcesses)
                logger.info("Admin authorization granted")
                return true
            } else {
                authorizationStatus = .denied
                logger.warning("Admin authorization denied")
                return false
            }
        } catch {
            authorizationStatus = .failed
            lastError = .adminAuthorizationFailed(error.localizedDescription)
            logger.error("Admin authorization failed: \\(error.localizedDescription)")
            return false
        }
    }
    
    private func createAuthorization() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            var authRef: AuthorizationRef?
            
            let status = AuthorizationCreate(nil, nil, kAuthorizationFlagDefaults, &authRef)
            
            if status == errAuthorizationSuccess {
                self.authorizationRef = authRef
                continuation.resume(returning: true)
            } else {
                continuation.resume(returning: false)
            }
        }
    }
    
    private func createAdminAuthorization() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            var authRef: AuthorizationRef?
            
            // Create authorization rights for admin operations
            let rightName = kAuthorizationRightExecute
            let rightNamePtr = rightName.withCString { $0 }
            
            var authItem = AuthorizationItem(
                name: rightNamePtr,
                valueLength: 0,
                value: nil,
                flags: 0
            )
            
            var authRights = AuthorizationRights(count: 1, items: &authItem)
            
            let flags: AuthorizationFlags = [
                .interactionAllowed,
                .extendRights,
                .preAuthorize
            ]
            
            let status = AuthorizationCreate(&authRights, nil, flags, &authRef)
            
            switch status {
            case errAuthorizationSuccess:
                self.authorizationRef = authRef
                continuation.resume(returning: true)
            case errAuthorizationCanceled:
                logger.info("User canceled authorization request")
                continuation.resume(returning: false)
            case errAuthorizationDenied:
                logger.warning("Authorization denied by system")
                continuation.resume(returning: false)
            case errAuthorizationInvalidSet:
                logger.error("Invalid authorization set")
                continuation.resume(throwing: SecurityError.authorizationFailed("Invalid authorization set"))
            default:
                logger.error("Authorization failed with status: \(status)")
                continuation.resume(throwing: SecurityError.authorizationFailed("System authorization error: \(status)"))
            }
        }
    }
    
    // MARK: - Helper Tool Management
    private func checkHelperStatus() {
        // Check if privileged helper tool is installed
        var cfError: Unmanaged<CFError>?
        
        let helperExists = SMJobCopyDictionary(
            kSMDomainSystemLaunchd,
            helperToolLabel as CFString
        ) != nil
        
        if let cfError = cfError {
            let error = cfError.takeRetainedValue()
            logger.error("Error checking helper status: \\(error)")
            helperStatus = .error
        } else if helperExists {
            helperStatus = .installed
            availablePermissions.insert(.helperTool)
        } else {
            helperStatus = .notInstalled
        }
    }
    
    func installHelperTool() async -> Bool {
        guard let authRef = authorizationRef else {
            logger.error("No authorization reference available for helper tool installation")
            lastError = .insufficientPermissions
            return false
        }
        
        helperStatus = .installing
        
        var cfError: Unmanaged<CFError>?
        let success = SMJobBless(
            kSMDomainSystemLaunchd,
            helperToolLabel as CFString,
            authRef,
            &cfError
        )
        
        if success {
            helperStatus = .installed
            availablePermissions.insert(.helperTool)
            logger.info("Helper tool installed successfully")
            return true
        } else {
            helperStatus = .error
            
            if let cfError = cfError {
                let error = cfError.takeRetainedValue()
                let errorDescription = CFErrorCopyDescription(error) as String? ?? "Unknown installation error"
                let errorCode = CFErrorGetCode(error)
                
                lastError = .helperInstallationFailed("\(errorDescription) (Code: \(errorCode))")
                logger.error("Helper installation failed: \(errorDescription) (Code: \(errorCode))")
            } else {
                lastError = .helperInstallationFailed("Unknown error occurred during installation")
                logger.error("Helper installation failed with unknown error")
            }
            return false
        }
    }
    
    // MARK: - Permission Validation
    func canTerminateProcess(_ processInfo: ProcessInfo) -> Bool {
        switch processInfo.securityLevel {
        case .low:
            // User processes - always allowed with basic permissions
            return availablePermissions.contains(.userProcesses)
            
        case .medium:
            // Background agents - requires basic authorization
            return availablePermissions.contains(.basicOperations)
            
        case .high:
            // System processes - requires admin authorization
            return availablePermissions.contains(.adminOperations)
        }
    }
    
    func requiresAdminForProcess(_ processInfo: ProcessInfo) -> Bool {
        return processInfo.securityLevel == .high
    }
    
    func isProtectedProcess(_ processInfo: ProcessInfo) -> Bool {
        // Processes that should never be terminated
        let protectedBundleIds = [
            "com.apple.loginwindow",
            "com.apple.WindowServer", 
            "com.apple.securityd",
            "com.forceQUIT.app" // Don't terminate ourselves!
        ]
        
        if let bundleId = processInfo.bundleIdentifier {
            return protectedBundleIds.contains(bundleId)
        }
        
        // Also protect based on process name
        let protectedNames = [
            "kernel_task",
            "launchd",
            "loginwindow",
            "WindowServer"
        ]
        
        return protectedNames.contains(processInfo.name)
    }
    
    // MARK: - Secure Operations
    func secureTerminateProcess(_ processInfo: ProcessInfo) async -> TerminationResult {
        // Validate permissions first
        guard canTerminateProcess(processInfo) else {
            logger.warning("Insufficient permissions to terminate \\(processInfo.name)")
            return .insufficientPermissions
        }
        
        // Check if process is protected
        guard !isProtectedProcess(processInfo) else {
            logger.warning("Attempted to terminate protected process: \\(processInfo.name)")
            return .protectedProcess
        }
        
        // Log the operation for audit trail
        logger.info("Terminating process: \\(processInfo.name) (PID: \\(processInfo.pid))")
        
        // Attempt graceful termination first
        if let app = NSWorkspace.shared.runningApplications.first(where: { 
            $0.processIdentifier == processInfo.pid 
        }) {
            
            // Try graceful termination (SIGTERM)
            let gracefulSuccess = app.terminate()
            
            if gracefulSuccess {
                logger.info("Process \\(processInfo.name) terminated gracefully")
                return .success
            } else {
                // Force termination if graceful fails (SIGKILL)
                logger.warning("Graceful termination failed for \\(processInfo.name), using force")
                let forceSuccess = app.forceTerminate()
                
                if forceSuccess {
                    logger.info("Process \\(processInfo.name) force terminated")
                    return .success
                } else {
                    logger.error("Failed to force terminate \\(processInfo.name)")
                    return .failed
                }
            }
        } else {
            logger.error("Process \\(processInfo.name) not found")
            return .processNotFound
        }
    }
    
    // MARK: - Security Validation
    func validateSystemIntegrity() -> SystemIntegrityStatus {
        // Perform security checks to ensure system integrity
        var issues: [String] = []
        
        // Check SIP status
        if !isSystemIntegrityProtectionEnabled() {
            issues.append("System Integrity Protection is disabled")
        }
        
        // Check for suspicious process activity
        if detectSuspiciousActivity() {
            issues.append("Suspicious process activity detected")
        }
        
        // Check authorization status
        if authorizationStatus == .failed {
            issues.append("Authorization system failure")
        }
        
        return SystemIntegrityStatus(
            isHealthy: issues.isEmpty,
            issues: issues,
            checkedAt: Date()
        )
    }
    
    private func isSystemIntegrityProtectionEnabled() -> Bool {
        // Check SIP status via system call
        // In a real implementation, this would check SIP status
        return true // Assume SIP is enabled
    }
    
    private func detectSuspiciousActivity() -> Bool {
        // Check for suspicious patterns in process behavior
        // This is a simplified check
        return false
    }
}

// MARK: - Security Enums and Types
enum AuthorizationStatus {
    case notRequested
    case requesting
    case authorized
    case authorizedAdmin
    case denied
    case failed
    
    var description: String {
        switch self {
        case .notRequested: return "Not requested"
        case .requesting: return "Requesting..."
        case .authorized: return "Authorized"
        case .authorizedAdmin: return "Admin authorized"
        case .denied: return "Denied"
        case .failed: return "Failed"
        }
    }
}

enum HelperStatus {
    case notInstalled
    case installing
    case installed
    case error
    
    var description: String {
        switch self {
        case .notInstalled: return "Not installed"
        case .installing: return "Installing..."
        case .installed: return "Installed"
        case .error: return "Error"
        }
    }
}

enum Permission: String, CaseIterable {
    case userProcesses = "User Processes"
    case systemEvents = "System Events"
    case basicOperations = "Basic Operations"
    case adminOperations = "Admin Operations"
    case systemProcesses = "System Processes"
    case helperTool = "Helper Tool"
}

enum SecurityError: LocalizedError {
    case authorizationFailed(String)
    case adminAuthorizationFailed(String)
    case helperInstallationFailed(String)
    case insufficientPermissions
    case protectedProcess
    
    var errorDescription: String? {
        switch self {
        case .authorizationFailed(let message):
            return "Authorization failed: \\(message)"
        case .adminAuthorizationFailed(let message):
            return "Admin authorization failed: \\(message)"
        case .helperInstallationFailed(let message):
            return "Helper installation failed: \\(message)"
        case .insufficientPermissions:
            return "Insufficient permissions for this operation"
        case .protectedProcess:
            return "Cannot terminate protected system process"
        }
    }
}

enum TerminationResult {
    case success
    case insufficientPermissions
    case protectedProcess
    case processNotFound
    case failed
    
    var description: String {
        switch self {
        case .success: return "Process terminated successfully"
        case .insufficientPermissions: return "Insufficient permissions"
        case .protectedProcess: return "Protected process cannot be terminated"
        case .processNotFound: return "Process not found"
        case .failed: return "Termination failed"
        }
    }
}

struct SystemIntegrityStatus {
    let isHealthy: Bool
    let issues: [String]
    let checkedAt: Date
}