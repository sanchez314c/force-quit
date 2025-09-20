//
//  AuthorizationManager.swift
//  ForceQUIT Security Framework
//
//  Comprehensive authorization and permission management system
//  Handles SMJobBless helper tool installation, user authentication,
//  privilege escalation, and secure XPC communication workflows.
//

import Foundation
import AuthorizationServices
import ServiceManagement
import Security
import OSLog

@MainActor
public class AuthorizationManager: ObservableObject {
    public static let shared = AuthorizationManager()
    
    private let logger = Logger(subsystem: "com.forcequit.security", category: "AuthorizationManager")
    
    @Published public private(set) var authorizationState: AuthorizationState = .unknown
    @Published public private(set) var helperToolStatus: HelperToolStatus = .unknown
    @Published public private(set) var availablePrivileges: Set<Privilege> = []
    @Published public private(set) var xpcConnection: NSXPCConnection?
    
    // Authorization state tracking
    public enum AuthorizationState: String, CaseIterable {
        case unknown = "unknown"
        case unauthorized = "unauthorized"
        case userLevel = "user_level"
        case adminLevel = "admin_level"
        case systemLevel = "system_level"
        
        var canPerformSystemOperations: Bool {
            switch self {
            case .adminLevel, .systemLevel:
                return true
            default:
                return false
            }
        }
        
        var requiresElevation: Bool {
            switch self {
            case .unknown, .unauthorized, .userLevel:
                return true
            default:
                return false
            }
        }
    }
    
    public enum HelperToolStatus: String, CaseIterable {
        case unknown = "unknown"
        case notInstalled = "not_installed"
        case installing = "installing"
        case installed = "installed"
        case compromised = "compromised"
        case outdated = "outdated"
        
        var isOperational: Bool {
            return self == .installed
        }
    }
    
    public enum Privilege: String, CaseIterable {
        // Process management privileges
        case terminateUserProcesses = "terminate_user_processes"
        case terminateSystemProcesses = "terminate_system_processes"
        case accessProcessInfo = "access_process_info"
        case modifyProcessPriority = "modify_process_priority"
        
        // System control privileges
        case systemRestart = "system_restart"
        case systemShutdown = "system_shutdown"
        case systemSleep = "system_sleep"
        
        // File system privileges
        case readSystemFiles = "read_system_files"
        case writeSystemFiles = "write_system_files"
        case modifyPermissions = "modify_permissions"
        
        // Network privileges
        case networkMonitoring = "network_monitoring"
        case firewallControl = "firewall_control"
        
        // Advanced privileges
        case helperToolInstallation = "helper_tool_installation"
        case rootAccess = "root_access"
        
        var requiresHelperTool: Bool {
            switch self {
            case .terminateSystemProcesses, .systemRestart, .systemShutdown,
                 .writeSystemFiles, .modifyPermissions, .rootAccess:
                return true
            default:
                return false
            }
        }
        
        var description: String {
            switch self {
            case .terminateUserProcesses:
                return "Terminate user applications"
            case .terminateSystemProcesses:
                return "Terminate system processes"
            case .accessProcessInfo:
                return "Access detailed process information"
            case .modifyProcessPriority:
                return "Modify process priority levels"
            case .systemRestart:
                return "Restart the system"
            case .systemShutdown:
                return "Shutdown the system"
            case .systemSleep:
                return "Put system to sleep"
            case .readSystemFiles:
                return "Read system configuration files"
            case .writeSystemFiles:
                return "Modify system configuration"
            case .modifyPermissions:
                return "Change file and directory permissions"
            case .networkMonitoring:
                return "Monitor network connections"
            case .firewallControl:
                return "Control system firewall"
            case .helperToolInstallation:
                return "Install privileged helper tools"
            case .rootAccess:
                return "Perform root-level operations"
            }
        }
    }
    
    // Helper tool configuration
    private let helperToolIdentifier = "com.forcequit.helper"
    private let helperToolBundleIdentifier = "com.forcequit.helper"
    private let maxConnectionAttempts = 3
    private let connectionTimeout: TimeInterval = 10.0
    
    // Authorization rights
    private let authorizationRights = [
        "system.privilege.admin": kAuthorizationRuleAuthenticateAsAdmin,
        "system.processes.terminate": kAuthorizationRuleAuthenticateAsAdmin,
        "system.restart": kAuthorizationRuleAuthenticateAsAdmin
    ]
    
    private init() {
        initializeAuthorizationManager()
    }
    
    // MARK: - Authorization Manager Initialization
    
    private func initializeAuthorizationManager() {
        logger.info("🔐 Initializing Authorization Manager")
        
        Task {
            await determineCurrentAuthorizationLevel()
            await checkHelperToolStatus()
            await evaluateAvailablePrivileges()
            
            logger.info("✅ Authorization Manager initialized")
        }
    }
    
    private func determineCurrentAuthorizationLevel() async {
        // Check current user privileges
        let currentUID = getuid()
        let currentGID = getgid()
        
        if currentUID == 0 {
            authorizationState = .systemLevel
            logger.info("🔑 System-level authorization detected")
        } else if await canPerformAdminOperations() {
            authorizationState = .adminLevel
            logger.info("🔑 Admin-level authorization detected")
        } else {
            authorizationState = .userLevel
            logger.info("🔑 User-level authorization detected")
        }
    }
    
    private func canPerformAdminOperations() async -> Bool {
        // Test admin privileges by attempting to create authorization
        var authRef: AuthorizationRef?
        let status = AuthorizationCreate(nil, nil, [], &authRef)
        
        guard status == errAuthorizationSuccess, let auth = authRef else {
            return false
        }
        
        defer { AuthorizationFree(auth, []) }
        
        // Test admin right
        var authItem = AuthorizationItem(
            name: kAuthorizationRightExecute,
            valueLength: 0,
            value: nil,
            flags: 0
        )
        
        var authRights = AuthorizationRights(count: 1, items: &authItem)
        let flags: AuthorizationFlags = [.extendRights, .preAuthorize]
        
        let testStatus = AuthorizationCopyRights(auth, &authRights, nil, flags, nil)
        return testStatus == errAuthorizationSuccess
    }
    
    private func checkHelperToolStatus() async {
        logger.info("🔍 Checking helper tool status")
        
        // Check if helper tool is installed
        if await isHelperToolInstalled() {
            // Verify helper tool integrity
            if await validateHelperToolIntegrity() {
                // Test helper tool connectivity
                if await testHelperToolConnection() {
                    helperToolStatus = .installed
                    logger.info("✅ Helper tool is installed and operational")
                } else {
                    helperToolStatus = .compromised
                    logger.warning("⚠️ Helper tool installed but not responding")
                }
            } else {
                helperToolStatus = .compromised
                logger.error("❌ Helper tool integrity validation failed")
            }
        } else {
            helperToolStatus = .notInstalled
            logger.info("ℹ️ Helper tool not installed")
        }
    }
    
    private func isHelperToolInstalled() async -> Bool {
        // Check if helper tool is registered with launchd
        let helperPlistPath = "/Library/LaunchDaemons/\(helperToolIdentifier).plist"
        return FileManager.default.fileExists(atPath: helperPlistPath)
    }
    
    private func validateHelperToolIntegrity() async -> Bool {
        // Validate helper tool binary signature
        guard let helperURL = getHelperToolURL() else {
            return false
        }
        
        var staticCode: SecStaticCode?
        let status = SecStaticCodeCreateWithPath(helperURL as CFURL, [], &staticCode)
        guard status == errSecSuccess, let code = staticCode else {
            return false
        }
        
        let validateStatus = SecStaticCodeCheckValidity(code, [], nil)
        return validateStatus == errSecSuccess
    }
    
    private func testHelperToolConnection() async -> Bool {
        do {
            let connection = try await establishXPCConnection()
            let helper = connection.remoteObjectProxyWithErrorHandler { error in
                self.logger.error("❌ Helper tool connection error: \(error)")
            } as? PrivilegedHelperProtocol
            
            guard let helper = helper else { return false }
            
            // Test basic helper functionality
            return await withCheckedContinuation { continuation in
                helper.getHelperVersion { version in
                    continuation.resume(returning: !version.isEmpty)
                }
            }
        } catch {
            logger.error("❌ Failed to test helper tool connection: \(error)")
            return false
        }
    }
    
    private func getHelperToolURL() -> URL? {
        // Get helper tool executable URL
        return URL(fileURLWithPath: "/Library/PrivilegedHelperTools/\(helperToolIdentifier)")
    }
    
    private func evaluateAvailablePrivileges() async {
        var privileges: Set<Privilege> = []
        
        // Evaluate each privilege
        for privilege in Privilege.allCases {
            if await canGrantPrivilege(privilege) {
                privileges.insert(privilege)
            }
        }
        
        availablePrivileges = privileges
        logger.info("📊 Available privileges: \(privileges.count)/\(Privilege.allCases.count)")
    }
    
    private func canGrantPrivilege(_ privilege: Privilege) async -> Bool {
        switch privilege {
        case .terminateUserProcesses, .accessProcessInfo:
            return authorizationState.rawValue != "unauthorized"
            
        case .terminateSystemProcesses, .systemRestart, .systemShutdown:
            return authorizationState.canPerformSystemOperations && helperToolStatus.isOperational
            
        case .helperToolInstallation:
            return authorizationState.canPerformSystemOperations
            
        case .rootAccess:
            return authorizationState == .systemLevel
            
        default:
            return authorizationState.canPerformSystemOperations
        }
    }
    
    // MARK: - Helper Tool Management
    
    public func installHelperTool() async -> Bool {
        logger.info("🔧 Installing helper tool")
        
        guard authorizationState.canPerformSystemOperations else {
            logger.error("❌ Insufficient privileges to install helper tool")
            return false
        }
        
        helperToolStatus = .installing
        
        do {
            let success = try await performHelperToolInstallation()
            if success {
                helperToolStatus = .installed
                await evaluateAvailablePrivileges()
                logger.info("✅ Helper tool installed successfully")
            } else {
                helperToolStatus = .notInstalled
                logger.error("❌ Helper tool installation failed")
            }
            return success
        } catch {
            helperToolStatus = .notInstalled
            logger.error("❌ Helper tool installation error: \(error)")
            return false
        }
    }
    
    private func performHelperToolInstallation() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            // Create authorization reference
            var authRef: AuthorizationRef?
            let authStatus = AuthorizationCreate(nil, nil, [], &authRef)
            
            guard authStatus == errAuthorizationSuccess, let auth = authRef else {
                continuation.resume(throwing: NSError(domain: "AuthorizationError", code: Int(authStatus)))
                return
            }
            
            defer { AuthorizationFree(auth, []) }
            
            // Define authorization rights
            var authItem = AuthorizationItem(
                name: kAuthorizationRightExecute,
                valueLength: 0,
                value: nil,
                flags: 0
            )
            
            var authRights = AuthorizationRights(count: 1, items: &authItem)
            let flags: AuthorizationFlags = [.interactionAllowed, .extendRights, .preAuthorize]
            
            // Request authorization
            let rightsStatus = AuthorizationCopyRights(auth, &authRights, nil, flags, nil)
            guard rightsStatus == errAuthorizationSuccess else {
                continuation.resume(throwing: NSError(domain: "AuthorizationError", code: Int(rightsStatus)))
                return
            }
            
            // Install helper using SMJobBless
            var error: Unmanaged<CFError>?
            let success = SMJobBless(
                kSMDomainSystemLaunchd,
                helperToolIdentifier as CFString,
                auth,
                &error
            )
            
            if let error = error?.takeRetainedValue() {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: success)
            }
        }
    }
    
    public func uninstallHelperTool() async -> Bool {
        logger.info("🗑️ Uninstalling helper tool")
        
        guard helperToolStatus == .installed || helperToolStatus == .compromised else {
            logger.warning("⚠️ Helper tool not installed")
            return true
        }
        
        do {
            let success = try await performHelperToolUninstallation()
            if success {
                helperToolStatus = .notInstalled
                await evaluateAvailablePrivileges()
                logger.info("✅ Helper tool uninstalled successfully")
            } else {
                logger.error("❌ Helper tool uninstallation failed")
            }
            return success
        } catch {
            logger.error("❌ Helper tool uninstallation error: \(error)")
            return false
        }
    }
    
    private func performHelperToolUninstallation() async throws -> Bool {
        // Remove helper tool using SMJobRemove
        return try await withCheckedThrowingContinuation { continuation in
            var authRef: AuthorizationRef?
            let authStatus = AuthorizationCreate(nil, nil, [], &authRef)
            
            guard authStatus == errAuthorizationSuccess, let auth = authRef else {
                continuation.resume(throwing: NSError(domain: "AuthorizationError", code: Int(authStatus)))
                return
            }
            
            defer { AuthorizationFree(auth, []) }
            
            let success = SMJobRemove(
                kSMDomainSystemLaunchd,
                helperToolIdentifier as CFString,
                auth,
                true
            ) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: true)
                }
            }
            
            if !success {
                continuation.resume(returning: false)
            }
        }
    }
    
    // MARK: - XPC Communication
    
    public func getHelperConnection() async throws -> NSXPCConnection {
        if let existingConnection = xpcConnection, existingConnection.isValid {
            return existingConnection
        }
        
        let connection = try await establishXPCConnection()
        xpcConnection = connection
        return connection
    }
    
    private func establishXPCConnection() async throws -> NSXPCConnection {
        logger.info("🔗 Establishing XPC connection to helper tool")
        
        guard helperToolStatus.isOperational else {
            throw AuthorizationError.helperToolNotAvailable
        }
        
        let connection = NSXPCConnection(machServiceName: helperToolIdentifier, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: PrivilegedHelperProtocol.self)
        
        connection.invalidationHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.logger.warning("⚠️ XPC connection invalidated")
                self?.xpcConnection = nil
            }
        }
        
        connection.interruptionHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.logger.warning("⚠️ XPC connection interrupted")
                self?.xpcConnection = nil
            }
        }
        
        connection.resume()
        
        // Test connection
        let isConnected = await testXPCConnection(connection)
        guard isConnected else {
            connection.invalidate()
            throw AuthorizationError.connectionFailed
        }
        
        logger.info("✅ XPC connection established")
        return connection
    }
    
    private func testXPCConnection(_ connection: NSXPCConnection) async -> Bool {
        return await withCheckedContinuation { continuation in
            let helper = connection.remoteObjectProxyWithErrorHandler { error in
                self.logger.error("❌ XPC connection test failed: \(error)")
                continuation.resume(returning: false)
            } as? PrivilegedHelperProtocol
            
            helper?.performHealthCheck { _ in
                continuation.resume(returning: true)
            }
            
            // Timeout after connection timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + connectionTimeout) {
                continuation.resume(returning: false)
            }
        }
    }
    
    // MARK: - Privilege Management
    
    public func requestPrivilege(_ privilege: Privilege) async -> Bool {
        logger.info("🔐 Requesting privilege: \(privilege.rawValue)")
        
        // Check if privilege is already available
        if availablePrivileges.contains(privilege) {
            logger.info("✅ Privilege already available")
            return true
        }
        
        // Check if privilege requires helper tool
        if privilege.requiresHelperTool && !helperToolStatus.isOperational {
            logger.info("⚡ Privilege requires helper tool installation")
            
            let installSuccess = await installHelperTool()
            guard installSuccess else {
                logger.error("❌ Failed to install required helper tool")
                return false
            }
        }
        
        // Request user authorization if needed
        if await requiresUserAuthorization(for: privilege) {
            let authSuccess = await requestUserAuthorization(for: privilege)
            guard authSuccess else {
                logger.error("❌ User authorization denied")
                return false
            }
        }
        
        // Re-evaluate privileges after changes
        await evaluateAvailablePrivileges()
        
        let granted = availablePrivileges.contains(privilege)
        if granted {
            logger.info("✅ Privilege granted: \(privilege.rawValue)")
        } else {
            logger.error("❌ Failed to grant privilege: \(privilege.rawValue)")
        }
        
        return granted
    }
    
    private func requiresUserAuthorization(for privilege: Privilege) async -> Bool {
        switch privilege {
        case .terminateSystemProcesses, .systemRestart, .systemShutdown,
             .writeSystemFiles, .helperToolInstallation, .rootAccess:
            return true
        default:
            return false
        }
    }
    
    private func requestUserAuthorization(for privilege: Privilege) async -> Bool {
        logger.info("👤 Requesting user authorization for privilege: \(privilege.rawValue)")
        
        return await withCheckedContinuation { continuation in
            // Create authorization reference
            var authRef: AuthorizationRef?
            let status = AuthorizationCreate(nil, nil, [], &authRef)
            
            guard status == errAuthorizationSuccess, let auth = authRef else {
                continuation.resume(returning: false)
                return
            }
            
            defer { AuthorizationFree(auth, []) }
            
            // Create authorization item
            let rightName = getAuthorizationRight(for: privilege)
            var authItem = AuthorizationItem(
                name: rightName,
                valueLength: 0,
                value: nil,
                flags: 0
            )
            
            var authRights = AuthorizationRights(count: 1, items: &authItem)
            
            // Request rights with user interaction
            let flags: AuthorizationFlags = [
                .interactionAllowed,
                .extendRights,
                .preAuthorize
            ]
            
            let rightsStatus = AuthorizationCopyRights(auth, &authRights, nil, flags, nil)
            continuation.resume(returning: rightsStatus == errAuthorizationSuccess)
        }
    }
    
    private func getAuthorizationRight(for privilege: Privilege) -> String {
        switch privilege {
        case .terminateSystemProcesses:
            return "system.processes.terminate"
        case .systemRestart, .systemShutdown:
            return "system.restart"
        case .writeSystemFiles, .rootAccess:
            return "system.privilege.admin"
        case .helperToolInstallation:
            return "system.privilege.admin"
        default:
            return kAuthorizationRightExecute
        }
    }
    
    // MARK: - Elevation Workflows
    
    public func requestElevationIfNeeded(for operation: String) async -> Bool {
        logger.info("⬆️ Checking if elevation needed for operation: \(operation)")
        
        // Determine required privilege for operation
        let requiredPrivilege = mapOperationToPrivilege(operation)
        
        // Request privilege if needed
        if let privilege = requiredPrivilege {
            return await requestPrivilege(privilege)
        }
        
        // No specific privilege needed
        return true
    }
    
    private func mapOperationToPrivilege(_ operation: String) -> Privilege? {
        switch operation.lowercased() {
        case "terminate user process", "terminate user processes":
            return .terminateUserProcesses
        case "terminate system process", "terminate system processes":
            return .terminateSystemProcesses
        case "system restart":
            return .systemRestart
        case "system shutdown":
            return .systemShutdown
        case "install helper tool":
            return .helperToolInstallation
        case "root access":
            return .rootAccess
        default:
            return nil
        }
    }
    
    // MARK: - Security Validation
    
    public func validateAuthorizationState() async -> Bool {
        logger.info("🔍 Validating authorization state")
        
        // Re-check authorization level
        await determineCurrentAuthorizationLevel()
        
        // Re-check helper tool status
        await checkHelperToolStatus()
        
        // Re-evaluate privileges
        await evaluateAvailablePrivileges()
        
        let isValid = authorizationState != .unknown && authorizationState != .unauthorized
        
        if isValid {
            logger.info("✅ Authorization state validation passed")
        } else {
            logger.error("❌ Authorization state validation failed")
        }
        
        return isValid
    }
    
    // MARK: - Public API
    
    public func getAuthorizationReport() -> [String: Any] {
        return [
            "timestamp": Date().timeIntervalSince1970,
            "authorization_state": authorizationState.rawValue,
            "helper_tool_status": helperToolStatus.rawValue,
            "can_perform_system_operations": authorizationState.canPerformSystemOperations,
            "requires_elevation": authorizationState.requiresElevation,
            "helper_tool_operational": helperToolStatus.isOperational,
            "available_privileges": availablePrivileges.map { privilege in
                [
                    "name": privilege.rawValue,
                    "description": privilege.description,
                    "requires_helper_tool": privilege.requiresHelperTool
                ]
            },
            "xpc_connection_active": xpcConnection?.isValid ?? false
        ]
    }
    
    public func hasPrivilege(_ privilege: Privilege) -> Bool {
        return availablePrivileges.contains(privilege)
    }
    
    public func canPerformSystemOperations() -> Bool {
        return authorizationState.canPerformSystemOperations
    }
    
    public func isHelperToolOperational() -> Bool {
        return helperToolStatus.isOperational
    }
}

// MARK: - Authorization Errors

public enum AuthorizationError: Error, LocalizedError {
    case authorizationFailed
    case helperToolNotAvailable
    case connectionFailed
    case privilegeNotGranted
    case userCancelled
    
    public var errorDescription: String? {
        switch self {
        case .authorizationFailed:
            return "Authorization request failed"
        case .helperToolNotAvailable:
            return "Privileged helper tool is not available"
        case .connectionFailed:
            return "Failed to establish XPC connection"
        case .privilegeNotGranted:
            return "Required privilege was not granted"
        case .userCancelled:
            return "User cancelled authorization request"
        }
    }
}