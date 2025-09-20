import Foundation
import AppKit
import os.log
import Security
import ServiceManagement

/// SWARM 2.0 ForceQUIT - Advanced Permission Manager
/// Comprehensive system access control and privilege management
/// Handles authentication, authorization, and elevated permission requests

class PermissionManager: ObservableObject {
    // MARK: - Properties
    @Published private(set) var currentPermissionLevel: PermissionLevel = .user
    @Published private(set) var hasFullSystemAccess: Bool = false
    @Published private(set) var permissionStatus: [PermissionType: PermissionStatus] = [:]
    @Published private(set) var lastPermissionCheck: Date = Date()
    
    private let logger = Logger(subsystem: "com.forcequit.app", category: "PermissionManager")
    
    // Authentication context
    private var authContext: AuthorizationRef?
    private let authRights: [String] = [
        "system.privilege.admin",
        "system.preferences",
        "com.apple.ServiceManagement.daemons.modify"
    ]
    
    // Permission checking timer
    private var permissionCheckTimer: Timer?
    private let permissionCheckInterval: TimeInterval = 60.0 // Check every minute
    
    // MARK: - Initialization
    init() {
        setupAuthorizationContext()
        performInitialPermissionCheck()
        startPeriodicPermissionChecks()
    }
    
    deinit {
        cleanupAuthorizationContext()
        permissionCheckTimer?.invalidate()
    }
    
    // MARK: - Public Interface
    
    /// Request specific permissions from the user
    func requestPermissions(_ permissions: Set<PermissionType>) async -> PermissionRequestResult {
        logger.info("Requesting permissions: \(permissions.map(\.rawValue).joined(separator: ", "), privacy: .public)")
        
        var results: [PermissionType: Bool] = [:]
        var errors: [PermissionType: PermissionError] = [:]
        
        for permission in permissions {
            do {
                let granted = try await requestSinglePermission(permission)
                results[permission] = granted
                
                if granted {
                    await updatePermissionStatus(permission, status: .granted)
                } else {
                    await updatePermissionStatus(permission, status: .denied)
                }
            } catch {
                let permissionError = error as? PermissionError ?? .unknown
                errors[permission] = permissionError
                await updatePermissionStatus(permission, status: .error(permissionError))
            }
        }
        
        // Update overall permission level
        await updateCurrentPermissionLevel()
        
        let allGranted = results.values.allSatisfy { $0 }
        
        return PermissionRequestResult(
            success: allGranted,
            grantedPermissions: Set(results.compactMap { $0.value ? $0.key : nil }),
            deniedPermissions: Set(results.compactMap { !$0.value ? $0.key : nil }),
            errors: errors
        )
    }
    
    /// Check if we have a specific permission
    func hasPermission(_ permission: PermissionType) -> Bool {
        return permissionStatus[permission]?.isGranted ?? false
    }
    
    /// Check if we can terminate processes with elevated privileges
    func canTerminateElevatedProcesses() -> Bool {
        return hasPermission(.processTermination) && 
               (currentPermissionLevel == .administrator || currentPermissionLevel == .root)
    }
    
    /// Request administrator privileges using Authorization Services
    func requestAdministratorPrivileges(reason: String = "ForceQUIT needs administrator privileges to terminate system processes") async -> Bool {
        logger.info("Requesting administrator privileges")
        
        guard let authRef = authContext else {
            logger.error("No authorization context available")
            return false
        }
        
        let authItem = AuthorizationItem(
            name: kAuthorizationRightExecute,
            valueLength: 0,
            value: nil,
            flags: 0
        )
        
        var authRights = AuthorizationRights(count: 1, items: [authItem].withUnsafeBufferPointer { $0.baseAddress })
        
        let flags: AuthorizationFlags = [
            .interactionAllowed,
            .preAuthorize,
            .extendRights
        ]
        
        let status = AuthorizationCopyRights(
            authRef,
            &authRights,
            nil,
            flags,
            nil
        )
        
        let success = status == errAuthorizationSuccess
        
        if success {
            await updateCurrentPermissionLevel()
            logger.info("Administrator privileges granted")
        } else {
            logger.warning("Administrator privileges denied: \(status)")
        }
        
        return success
    }
    
    /// Execute command with elevated privileges
    func executeWithElevatedPrivileges(command: String, arguments: [String] = []) async throws -> String {
        guard hasPermission(.processTermination) else {
            throw PermissionError.insufficientPermissions
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
            process.arguments = ["-n"] + [command] + arguments // -n = non-interactive
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            process.terminationHandler = { process in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    let error = PermissionError.elevatedCommandFailed(output)
                    continuation.resume(throwing: error)
                }
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: PermissionError.processExecutionFailed(error))
            }
        }
    }
    
    /// Check current system access level
    func checkSystemAccessLevel() async -> SystemAccessLevel {
        let isAdmin = hasPermission(.administratorRights)
        let canAccessAllProcesses = hasPermission(.fullSystemAccess)
        let canModifySystemProcesses = hasPermission(.processTermination)
        
        if canAccessAllProcesses && canModifySystemProcesses && isAdmin {
            return .full
        } else if canModifySystemProcesses && isAdmin {
            return .elevated
        } else if canAccessAllProcesses || isAdmin {
            return .limited
        } else {
            return .basic
        }
    }
    
    /// Refresh all permission statuses
    func refreshPermissions() async {
        logger.info("Refreshing all permissions")
        
        for permission in PermissionType.allCases {
            let status = await checkPermissionStatus(permission)
            await updatePermissionStatus(permission, status: status)
        }
        
        await updateCurrentPermissionLevel()
        await MainActor.run {
            lastPermissionCheck = Date()
        }
    }
    
    // MARK: - Private Implementation
    
    private func setupAuthorizationContext() {
        let status = AuthorizationCreate(nil, nil, [], &authContext)
        
        if status != errAuthorizationSuccess {
            logger.error("Failed to create authorization context: \(status)")
        } else {
            logger.info("Authorization context created successfully")
        }
    }
    
    private func cleanupAuthorizationContext() {
        if let authRef = authContext {
            AuthorizationFree(authRef, [])
            authContext = nil
        }
    }
    
    private func performInitialPermissionCheck() {
        Task {
            await refreshPermissions()
        }
    }
    
    private func startPeriodicPermissionChecks() {
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: permissionCheckInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshPermissions()
            }
        }
    }
    
    private func requestSinglePermission(_ permission: PermissionType) async throws -> Bool {
        switch permission {
        case .processTermination:
            return await requestProcessTerminationPermission()
        case .fullSystemAccess:
            return await requestFullSystemAccessPermission()
        case .administratorRights:
            return await requestAdministratorRightsPermission()
        case .accessibility:
            return await requestAccessibilityPermission()
        case .automation:
            return await requestAutomationPermission()
        }
    }
    
    private func requestProcessTerminationPermission() async -> Bool {
        // Check if we can send signals to other processes
        let testPID: pid_t = 1 // launchd - safe to test signal 0
        let result = kill(testPID, 0)
        
        if result == 0 {
            return true
        } else {
            // Try to get admin privileges
            return await requestAdministratorPrivileges(
                reason: "ForceQUIT needs permission to terminate processes"
            )
        }
    }
    
    private func requestFullSystemAccessPermission() async -> Bool {
        // Check system events access (requires Full Disk Access)
        let testPath = "/private/var/db/systemstats"
        let accessible = FileManager.default.isReadableFile(atPath: testPath)
        
        if !accessible {
            // Show alert to user about Full Disk Access
            await showSystemPreferencesAlert(for: .fullSystemAccess)
        }
        
        return accessible
    }
    
    private func requestAdministratorRightsPermission() async -> Bool {
        return await requestAdministratorPrivileges(
            reason: "ForceQUIT needs administrator rights for enhanced functionality"
        )
    }
    
    private func requestAccessibilityPermission() async -> Bool {
        let accessible = AXIsProcessTrusted()
        
        if !accessible {
            // Prompt for accessibility access
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
            AXIsProcessTrustedWithOptions(options as CFDictionary)
        }
        
        // Check again after prompt
        return AXIsProcessTrusted()
    }
    
    private func requestAutomationPermission() async -> Bool {
        // Test Apple Events access by trying to get frontmost application
        let workspace = NSWorkspace.shared
        let frontmostApp = workspace.frontmostApplication
        
        return frontmostApp != nil
    }
    
    private func checkPermissionStatus(_ permission: PermissionType) async -> PermissionStatus {
        switch permission {
        case .processTermination:
            let hasPermission = kill(1, 0) == 0
            return hasPermission ? .granted : .denied
            
        case .fullSystemAccess:
            let testPath = "/private/var/db/systemstats"
            let hasAccess = FileManager.default.isReadableFile(atPath: testPath)
            return hasAccess ? .granted : .denied
            
        case .administratorRights:
            guard let authRef = authContext else { return .denied }
            
            let authItem = AuthorizationItem(
                name: kAuthorizationRightExecute,
                valueLength: 0,
                value: nil,
                flags: 0
            )
            
            var authRights = AuthorizationRights(count: 1, items: [authItem].withUnsafeBufferPointer { $0.baseAddress })
            
            let status = AuthorizationCopyRights(
                authRef,
                &authRights,
                nil,
                [.preAuthorize],
                nil
            )
            
            return status == errAuthorizationSuccess ? .granted : .denied
            
        case .accessibility:
            return AXIsProcessTrusted() ? .granted : .denied
            
        case .automation:
            let workspace = NSWorkspace.shared
            return workspace.frontmostApplication != nil ? .granted : .denied
        }
    }
    
    @MainActor
    private func updatePermissionStatus(_ permission: PermissionType, status: PermissionStatus) {
        permissionStatus[permission] = status
        
        // Update hasFullSystemAccess flag
        hasFullSystemAccess = permissionStatus[.fullSystemAccess]?.isGranted == true
        
        logger.debug("Permission \(permission.rawValue, privacy: .public) status: \(status.description, privacy: .public)")
    }
    
    @MainActor
    private func updateCurrentPermissionLevel() {
        let hasAdmin = hasPermission(.administratorRights)
        let hasFullAccess = hasPermission(.fullSystemAccess)
        let hasProcessTermination = hasPermission(.processTermination)
        
        if hasFullAccess && hasAdmin && hasProcessTermination {
            currentPermissionLevel = .root
        } else if hasAdmin && hasProcessTermination {
            currentPermissionLevel = .administrator
        } else if hasProcessTermination {
            currentPermissionLevel = .elevated
        } else {
            currentPermissionLevel = .user
        }
        
        logger.info("Current permission level: \(currentPermissionLevel.rawValue, privacy: .public)")
    }
    
    private func showSystemPreferencesAlert(for permission: PermissionType) async {
        await MainActor.run {
            let alert = NSAlert()
            alert.messageText = "Permission Required"
            alert.informativeText = "ForceQUIT needs \(permission.displayName) to function properly. Please grant this permission in System Preferences."
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                // Open System Preferences to relevant section
                let urlString: String
                switch permission {
                case .fullSystemAccess:
                    urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
                case .accessibility:
                    urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
                case .automation:
                    urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
                default:
                    urlString = "x-apple.systempreferences:com.apple.preference.security"
                }
                
                if let url = URL(string: urlString) {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}

// MARK: - Supporting Types

enum PermissionType: String, CaseIterable {
    case processTermination = "ProcessTermination"
    case fullSystemAccess = "FullSystemAccess"
    case administratorRights = "AdministratorRights"
    case accessibility = "Accessibility"
    case automation = "Automation"
    
    var displayName: String {
        switch self {
        case .processTermination: return "Process Termination"
        case .fullSystemAccess: return "Full System Access"
        case .administratorRights: return "Administrator Rights"
        case .accessibility: return "Accessibility"
        case .automation: return "Automation"
        }
    }
    
    var description: String {
        switch self {
        case .processTermination:
            return "Permission to terminate running processes"
        case .fullSystemAccess:
            return "Full disk access to monitor all system processes"
        case .administratorRights:
            return "Administrator privileges for system operations"
        case .accessibility:
            return "Accessibility API access for enhanced control"
        case .automation:
            return "Automation permission for application control"
        }
    }
    
    var systemImage: String {
        switch self {
        case .processTermination: return "stop.circle"
        case .fullSystemAccess: return "internaldrive"
        case .administratorRights: return "person.badge.key"
        case .accessibility: return "accessibility"
        case .automation: return "gearshape.2"
        }
    }
}

enum PermissionLevel: String, CaseIterable {
    case user = "User"
    case elevated = "Elevated"
    case administrator = "Administrator"
    case root = "Root"
    
    var description: String {
        switch self {
        case .user: return "Standard user permissions"
        case .elevated: return "Elevated permissions for process control"
        case .administrator: return "Administrator privileges"
        case .root: return "Full system access"
        }
    }
    
    var systemImage: String {
        switch self {
        case .user: return "person"
        case .elevated: return "person.crop.circle.badge.plus"
        case .administrator: return "person.badge.key"
        case .root: return "crown"
        }
    }
}

enum PermissionStatus: Equatable {
    case pending
    case granted
    case denied
    case error(PermissionError)
    
    var isGranted: Bool {
        if case .granted = self { return true }
        return false
    }
    
    var description: String {
        switch self {
        case .pending: return "Pending"
        case .granted: return "Granted"
        case .denied: return "Denied"
        case .error(let error): return "Error: \(error.localizedDescription)"
        }
    }
}

enum PermissionError: Error, LocalizedError {
    case insufficientPermissions
    case authorizationFailed
    case userCancelled
    case systemDenied
    case elevatedCommandFailed(String)
    case processExecutionFailed(Error)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .insufficientPermissions:
            return "Insufficient permissions to perform this operation"
        case .authorizationFailed:
            return "Authorization failed"
        case .userCancelled:
            return "User cancelled the permission request"
        case .systemDenied:
            return "System denied the permission request"
        case .elevatedCommandFailed(let output):
            return "Elevated command failed: \(output)"
        case .processExecutionFailed(let error):
            return "Process execution failed: \(error.localizedDescription)"
        case .unknown:
            return "Unknown permission error"
        }
    }
}

enum SystemAccessLevel: String, CaseIterable {
    case basic = "Basic"
    case limited = "Limited"
    case elevated = "Elevated"
    case full = "Full"
    
    var description: String {
        switch self {
        case .basic: return "Basic user access"
        case .limited: return "Limited system access"
        case .elevated: return "Elevated system access"
        case .full: return "Full system access"
        }
    }
    
    var systemImage: String {
        switch self {
        case .basic: return "lock"
        case .limited: return "lock.open"
        case .elevated: return "key"
        case .full: return "key.horizontal"
        }
    }
}

struct PermissionRequestResult {
    let success: Bool
    let grantedPermissions: Set<PermissionType>
    let deniedPermissions: Set<PermissionType>
    let errors: [PermissionType: PermissionError]
    
    var hasAnyPermissions: Bool {
        !grantedPermissions.isEmpty
    }
    
    var allPermissionsGranted: Bool {
        deniedPermissions.isEmpty && errors.isEmpty
    }
}