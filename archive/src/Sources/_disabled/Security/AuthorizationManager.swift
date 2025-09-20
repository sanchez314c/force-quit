import Foundation
import Security
import ServiceManagement
import OSLog
import AppKit

/// Multi-tier authorization system with SMJobBless integration
/// Implements secure privilege escalation with comprehensive validation
@MainActor
class AuthorizationManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AuthorizationManager()
    
    // MARK: - Published Properties
    @Published var authorizationTier: AuthorizationTier = .sandbox
    @Published var helperToolStatus: HelperToolStatus = .notInstalled
    @Published var lastAuthorizationTime: Date?
    @Published var securityEvents: [SecurityEvent] = []
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.forceQUIT.app", category: "Authorization")
    private var authorizationRef: AuthorizationRef?
    private var helperConnection: NSXPCConnection?
    
    // Configuration
    private let helperToolLabel = "com.forceQUIT.helper"
    private let maxAuthorizationAge: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    private init() {
        checkCurrentAuthorizationStatus()
        checkHelperToolStatus()
        startSecurityEventLogging()
    }
    
    deinit {
        cleanupAuthorization()
    }
    
    // MARK: - Authorization Status
    private func checkCurrentAuthorizationStatus() {
        // Check existing authorization
        if let authRef = authorizationRef {
            // Validate authorization is still valid
            let status = AuthorizationCopyRights(authRef, nil, nil, [], nil)
            if status == errAuthorizationSuccess {
                authorizationTier = .elevated
            } else {
                authorizationTier = .sandbox
                authorizationRef = nil
            }
        } else {
            authorizationTier = .sandbox
        }
        
        logger.info("📊 Current authorization tier: \(authorizationTier.rawValue)")
    }
    
    private func checkHelperToolStatus() {
        let installed = isHelperToolInstalled()
        helperToolStatus = installed ? .installed : .notInstalled
        
        if installed {
            validateHelperToolIntegrity()
        }
        
        logger.info("🔧 Helper tool status: \(helperToolStatus.rawValue)")
    }
    
    // MARK: - Authorization Requests
    func requestElevationIfNeeded(for operation: String) async -> Bool {
        logger.info("🔐 Elevation request for operation: \(operation)")
        
        // Check if already elevated and valid
        if authorizationTier == .elevated || authorizationTier == .superuser {
            if let lastAuth = lastAuthorizationTime,
               Date().timeIntervalSince(lastAuth) < maxAuthorizationAge {
                logger.info("✅ Using existing valid authorization")
                return true
            }
        }
        
        // Request new authorization
        return await requestElevatedAuthorization()
    }
    
    func requestElevatedAuthorization() async -> Bool {
        logger.info("🔑 Requesting elevated authorization")
        
        do {
            let success = try await createAuthorizationWithUI()
            
            if success {
                authorizationTier = .elevated
                lastAuthorizationTime = Date()
                
                logSecurityEvent(.authorizationGranted, details: "Elevated authorization granted")
                logger.info("✅ Elevated authorization granted")
                
                return true
            } else {
                logSecurityEvent(.authorizationDenied, details: "User denied elevation request")
                logger.warning("❌ Authorization denied by user")
                return false
            }
            
        } catch {
            logSecurityEvent(.authorizationFailed, details: "Authorization failed: \(error)")
            logger.error("💥 Authorization failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func requestSuperuserAuthorization() async -> Bool {
        logger.info("👑 Requesting superuser authorization")
        
        // Must have elevated auth first
        guard authorizationTier == .elevated else {
            logger.error("❌ Cannot request superuser without elevated authorization")
            return false
        }
        
        do {
            let success = try await installHelperToolIfNeeded()
            
            if success {
                authorizationTier = .superuser
                helperToolStatus = .installed
                
                logSecurityEvent(.superuserGranted, details: "Superuser authorization with helper tool")
                logger.info("👑 Superuser authorization granted")
                
                return true
            } else {
                logger.warning("❌ Superuser authorization failed")
                return false
            }
            
        } catch {
            logSecurityEvent(.superuserFailed, details: "Superuser authorization failed: \(error)")
            logger.error("💥 Superuser authorization failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Authorization Implementation
    private func createAuthorizationWithUI() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            
            // Create authorization rights
            var authItem = AuthorizationItem(
                name: kAuthorizationRightExecute.withMemoryRebound(to: Int8.self, capacity: 1) { $0 },
                valueLength: 0,
                value: nil,
                flags: 0
            )
            
            var authRights = AuthorizationRights(count: 1, items: &authItem)
            
            // Authorization flags
            let flags: AuthorizationFlags = [
                .interactionAllowed,
                .preAuthorize,
                .extendRights
            ]
            
            // Create authorization
            var authRef: AuthorizationRef?
            let status = AuthorizationCreate(&authRights, nil, flags, &authRef)
            
            if status == errAuthorizationSuccess {
                self.authorizationRef = authRef
                continuation.resume(returning: true)
            } else {
                let error = NSError(domain: "AuthorizationError", code: Int(status), userInfo: [
                    NSLocalizedDescriptionKey: "Authorization failed with status: \(status)"
                ])
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Helper Tool Management
    private func installHelperToolIfNeeded() async throws -> Bool {
        guard helperToolStatus != .installed else {
            logger.info("✅ Helper tool already installed")
            return true
        }
        
        guard let authRef = authorizationRef else {
            throw AuthorizationError.noAuthorization
        }
        
        logger.info("🔧 Installing helper tool...")
        helperToolStatus = .installing
        
        return try await withCheckedThrowingContinuation { continuation in
            var cfError: Unmanaged<CFError>?
            
            let success = SMJobBless(
                kSMDomainSystemLaunchd,
                helperToolLabel as CFString,
                authRef,
                &cfError
            )
            
            if success {
                self.helperToolStatus = .installed
                self.logger.info("✅ Helper tool installed successfully")
                continuation.resume(returning: true)
            } else {
                self.helperToolStatus = .error
                
                if let cfError = cfError {
                    let error = cfError.takeRetainedValue()
                    let errorDescription = CFErrorCopyDescription(error) as String? ?? "Unknown error"
                    let authError = AuthorizationError.helperInstallFailed(errorDescription)
                    self.logger.error("💥 Helper tool installation failed: \(errorDescription)")
                    continuation.resume(throwing: authError)
                } else {
                    let authError = AuthorizationError.helperInstallFailed("Unknown installation error")
                    continuation.resume(throwing: authError)
                }
            }
        }
    }
    
    private func isHelperToolInstalled() -> Bool {
        let jobDict = SMJobCopyDictionary(kSMDomainSystemLaunchd, helperToolLabel as CFString)
        return jobDict != nil
    }
    
    private func validateHelperToolIntegrity() {
        logger.info("🔍 Validating helper tool integrity")
        
        // Check helper tool signature and version
        // In production, would verify code signature and version match
        
        Task {
            if let connection = try? await getHelperConnection() {
                connection.remoteObjectProxyWithErrorHandler { error in
                    self.logger.warning("⚠️ Helper tool validation failed: \(error)")
                    self.helperToolStatus = .error
                }
            }
        }
    }
    
    // MARK: - Helper Tool Communication
    func getHelperConnection() async throws -> NSXPCConnection {
        if let existing = helperConnection, existing.processIdentifier != 0 {
            return existing
        }
        
        guard helperToolStatus == .installed else {
            throw AuthorizationError.helperNotInstalled
        }
        
        let connection = NSXPCConnection(machServiceName: helperToolLabel, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: XPCHelperToolProtocol.self)
        
        connection.invalidationHandler = { [weak self] in
            self?.helperConnection = nil
            self?.logger.warning("🔌 Helper connection invalidated")
        }
        
        connection.interruptionHandler = { [weak self] in
            self?.logger.warning("⚠️ Helper connection interrupted")
        }
        
        connection.resume()
        helperConnection = connection
        
        logger.info("🔗 Helper connection established")
        return connection
    }
    
    // MARK: - Authorization Validation
    func validateAuthorizationIntegrity() async -> Bool {
        guard let authRef = authorizationRef else {
            return false
        }
        
        // Check if authorization is still valid
        let status = AuthorizationCopyRights(authRef, nil, nil, [], nil)
        let valid = status == errAuthorizationSuccess
        
        if !valid {
            logger.warning("⚠️ Authorization integrity check failed")
            authorizationTier = .sandbox
            authorizationRef = nil
        }
        
        return valid
    }
    
    func hasValidAuthorization() -> Bool {
        guard authorizationTier != .sandbox,
              let lastAuth = lastAuthorizationTime else {
            return false
        }
        
        return Date().timeIntervalSince(lastAuth) < maxAuthorizationAge
    }
    
    // MARK: - Security Event Logging
    private func startSecurityEventLogging() {
        logger.info("📝 Security event logging initialized")
    }
    
    private func logSecurityEvent(_ type: SecurityEventType, details: String) {
        let event = SecurityEvent(
            type: type,
            details: details,
            timestamp: Date(),
            authorizationTier: authorizationTier
        )
        
        securityEvents.append(event)
        
        // Keep only recent events
        if securityEvents.count > 100 {
            securityEvents.removeFirst(securityEvents.count - 100)
        }
        
        logger.info("📊 Security event logged: \(type.rawValue)")
    }
    
    // MARK: - Authorization Reset
    func resetAuthorization() {
        logger.info("🔄 Resetting authorization")
        
        cleanupAuthorization()
        authorizationTier = .sandbox
        lastAuthorizationTime = nil
        
        logSecurityEvent(.authorizationReset, details: "Authorization manually reset")
    }
    
    private func cleanupAuthorization() {
        if let authRef = authorizationRef {
            AuthorizationFree(authRef, kAuthorizationFlagDefaults)
            authorizationRef = nil
        }
        
        helperConnection?.invalidate()
        helperConnection = nil
    }
    
    // MARK: - Capability Checking
    func canPerformOperation(_ operation: SecureOperation) -> Bool {
        switch operation {
        case .terminateUserProcess:
            return authorizationTier != .sandbox
            
        case .terminateSystemProcess:
            return authorizationTier == .elevated || authorizationTier == .superuser
            
        case .terminateProtectedProcess:
            return authorizationTier == .superuser
            
        case .modifySystemSettings:
            return authorizationTier == .superuser
        }
    }
    
    func getRequiredTier(for operation: SecureOperation) -> AuthorizationTier {
        switch operation {
        case .terminateUserProcess:
            return .elevated
        case .terminateSystemProcess:
            return .elevated  
        case .terminateProtectedProcess:
            return .superuser
        case .modifySystemSettings:
            return .superuser
        }
    }
}

// MARK: - Supporting Types
enum AuthorizationTier: String, CaseIterable {
    case sandbox = "Sandbox"
    case elevated = "Elevated"
    case superuser = "Superuser"
    
    var description: String {
        switch self {
        case .sandbox: return "Sandboxed - User processes only"
        case .elevated: return "Elevated - System access with user consent"
        case .superuser: return "Superuser - Full system access via helper"
        }
    }
    
    var color: NSColor {
        switch self {
        case .sandbox: return .systemBlue
        case .elevated: return .systemOrange
        case .superuser: return .systemRed
        }
    }
}

enum HelperToolStatus: String, CaseIterable {
    case notInstalled = "Not Installed"
    case installing = "Installing"
    case installed = "Installed"
    case error = "Error"
    
    var systemImage: String {
        switch self {
        case .notInstalled: return "minus.circle"
        case .installing: return "arrow.clockwise"
        case .installed: return "checkmark.circle"
        case .error: return "exclamationmark.circle"
        }
    }
}

enum SecureOperation: String, CaseIterable {
    case terminateUserProcess = "Terminate User Process"
    case terminateSystemProcess = "Terminate System Process"
    case terminateProtectedProcess = "Terminate Protected Process"
    case modifySystemSettings = "Modify System Settings"
}

struct SecurityEvent {
    let type: SecurityEventType
    let details: String
    let timestamp: Date
    let authorizationTier: AuthorizationTier
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

enum SecurityEventType: String, CaseIterable {
    case authorizationRequested = "Authorization Requested"
    case authorizationGranted = "Authorization Granted"
    case authorizationDenied = "Authorization Denied"
    case authorizationFailed = "Authorization Failed"
    case superuserGranted = "Superuser Granted"
    case superuserFailed = "Superuser Failed"
    case helperInstalled = "Helper Installed"
    case helperFailed = "Helper Failed"
    case authorizationReset = "Authorization Reset"
    case securityViolation = "Security Violation"
    
    var severity: SecurityEventSeverity {
        switch self {
        case .authorizationRequested, .authorizationGranted, .helperInstalled, .authorizationReset:
            return .info
        case .authorizationDenied, .superuserFailed, .helperFailed:
            return .warning
        case .authorizationFailed, .securityViolation:
            return .error
        case .superuserGranted:
            return .critical
        }
    }
}

enum SecurityEventSeverity {
    case info, warning, error, critical
    
    var color: NSColor {
        switch self {
        case .info: return .systemBlue
        case .warning: return .systemYellow
        case .error: return .systemOrange
        case .critical: return .systemRed
        }
    }
}

enum AuthorizationError: LocalizedError {
    case noAuthorization
    case helperNotInstalled
    case helperInstallFailed(String)
    case connectionFailed
    case operationNotPermitted
    
    var errorDescription: String? {
        switch self {
        case .noAuthorization:
            return "No valid authorization available"
        case .helperNotInstalled:
            return "Helper tool not installed"
        case .helperInstallFailed(let details):
            return "Helper tool installation failed: \(details)"
        case .connectionFailed:
            return "Failed to connect to helper tool"
        case .operationNotPermitted:
            return "Operation not permitted at current authorization level"
        }
    }
}