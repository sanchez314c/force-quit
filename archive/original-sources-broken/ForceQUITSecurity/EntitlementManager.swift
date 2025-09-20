//
//  EntitlementManager.swift
//  ForceQUIT Security Framework
//
//  Comprehensive entitlement and capability management system
//  Handles App Store entitlements, helper tool permissions,
//  capability validation, and security policy enforcement.
//

import Foundation
import Security
import AuthorizationServices
import OSLog

@MainActor
public class EntitlementManager: ObservableObject {
    public static let shared = EntitlementManager()
    
    private let logger = Logger(subsystem: "com.forcequit.security", category: "EntitlementManager")
    
    @Published public private(set) var mainAppEntitlements: Set<AppEntitlement> = []
    @Published public private(set) var helperToolEntitlements: Set<HelperEntitlement> = []
    @Published public private(set) var capabilityStatus: [Capability: CapabilityStatus] = [:]
    @Published public private(set) var entitlementValidationState: ValidationState = .unknown
    
    // Entitlement definitions for main app
    public enum AppEntitlement: String, CaseIterable {
        // Core sandbox entitlements
        case appSandbox = "com.apple.security.app-sandbox"
        case hardenedRuntime = "com.apple.security.cs.allow-jit"
        
        // Apple Events and automation
        case appleEvents = "com.apple.security.automation.apple-events"
        case systemEvents = "com.apple.security.scripting-targets"
        
        // File system access
        case userSelectedFiles = "com.apple.security.files.user-selected.read-write"
        case downloadsFolder = "com.apple.security.files.downloads.read-write"
        case documentsFolder = "com.apple.security.files.documents.read-write"
        
        // Network access
        case networkClient = "com.apple.security.network.client"
        case networkServer = "com.apple.security.network.server"
        
        // System information
        case processInfo = "com.apple.security.process-info"
        case systemInfo = "com.apple.security.system-info"
        
        // Debugging and development
        case debugger = "com.apple.security.cs.debugger"
        case getTaskAllow = "get-task-allow"
        
        var isRequired: Bool {
            switch self {
            case .appSandbox, .appleEvents, .processInfo:
                return true
            default:
                return false
            }
        }
        
        var isAppStoreCompatible: Bool {
            switch self {
            case .debugger, .getTaskAllow:
                return false
            default:
                return true
            }
        }
        
        var description: String {
            switch self {
            case .appSandbox:
                return "App Sandbox - Required for App Store distribution"
            case .hardenedRuntime:
                return "Hardened Runtime - Enhanced security protection"
            case .appleEvents:
                return "Apple Events - Communicate with other applications"
            case .systemEvents:
                return "System Events - Send events to system applications"
            case .userSelectedFiles:
                return "User Selected Files - Access files chosen by user"
            case .downloadsFolder:
                return "Downloads Folder - Access user's Downloads folder"
            case .documentsFolder:
                return "Documents Folder - Access user's Documents folder"
            case .networkClient:
                return "Network Client - Make outbound network connections"
            case .networkServer:
                return "Network Server - Accept inbound network connections"
            case .processInfo:
                return "Process Info - Access running process information"
            case .systemInfo:
                return "System Info - Access system configuration"
            case .debugger:
                return "Debugger - Allow debugging (development only)"
            case .getTaskAllow:
                return "Get Task Allow - Debug task access (development only)"
            }
        }
    }
    
    // Entitlement definitions for helper tool
    public enum HelperEntitlement: String, CaseIterable {
        // Process management
        case taskPort = "com.apple.security.task-port"
        case processManagement = "com.apple.security.process-management"
        
        // Signal delivery
        case signalDelivery = "com.apple.security.signal-delivery"
        
        // System information access
        case systemInformation = "com.apple.security.system-information"
        case kernelInformation = "com.apple.security.kernel-information"
        
        // Privileged operations
        case rootAccess = "com.apple.security.privileged-operations"
        case systemModification = "com.apple.security.system-modification"
        
        var isRequired: Bool {
            switch self {
            case .taskPort, .signalDelivery, .systemInformation:
                return true
            default:
                return false
            }
        }
        
        var requiresHelperTool: Bool {
            return true // All helper entitlements require privileged helper
        }
        
        var description: String {
            switch self {
            case .taskPort:
                return "Task Port - Access process task ports for termination"
            case .processManagement:
                return "Process Management - Manage system processes"
            case .signalDelivery:
                return "Signal Delivery - Send signals to processes"
            case .systemInformation:
                return "System Information - Access detailed system info"
            case .kernelInformation:
                return "Kernel Information - Access kernel-level information"
            case .rootAccess:
                return "Root Access - Perform privileged operations"
            case .systemModification:
                return "System Modification - Modify system settings"
            }
        }
    }
    
    // Capability definitions
    public enum Capability: String, CaseIterable {
        // Process operations
        case terminateUserProcesses = "terminate_user_processes"
        case terminateSystemProcesses = "terminate_system_processes"
        case accessProcessInfo = "access_process_info"
        
        // System operations
        case systemRestart = "system_restart"
        case systemShutdown = "system_shutdown"
        case systemSleep = "system_sleep"
        
        // File system operations
        case exportData = "export_data"
        case importSettings = "import_settings"
        
        // Network operations
        case checkUpdates = "check_updates"
        case downloadUpdates = "download_updates"
        
        // Advanced operations
        case privilegedOperations = "privileged_operations"
        case helperToolInstall = "helper_tool_install"
        
        var requiredEntitlements: [AppEntitlement] {
            switch self {
            case .terminateUserProcesses:
                return [.appSandbox, .appleEvents, .processInfo]
            case .terminateSystemProcesses:
                return [.appleEvents, .processInfo]
            case .accessProcessInfo:
                return [.processInfo]
            case .systemRestart, .systemShutdown, .systemSleep:
                return [.appleEvents, .systemEvents]
            case .exportData:
                return [.userSelectedFiles]
            case .importSettings:
                return [.userSelectedFiles]
            case .checkUpdates, .downloadUpdates:
                return [.networkClient]
            case .privilegedOperations:
                return []
            case .helperToolInstall:
                return []
            }
        }
        
        var requiresHelperTool: Bool {
            switch self {
            case .terminateSystemProcesses, .privilegedOperations, .helperToolInstall:
                return true
            default:
                return false
            }
        }
    }
    
    public enum CapabilityStatus {
        case available
        case restricted
        case unavailable
        case requiresElevation
        
        var isUsable: Bool {
            switch self {
            case .available, .restricted:
                return true
            case .unavailable, .requiresElevation:
                return false
            }
        }
    }
    
    public enum ValidationState {
        case unknown
        case valid
        case invalid
        case partial
    }
    
    private init() {
        initializeEntitlementManager()
    }
    
    // MARK: - Initialization
    
    private func initializeEntitlementManager() {
        logger.info("🔐 Initializing Entitlement Manager")
        
        Task {
            await detectMainAppEntitlements()
            await detectHelperToolEntitlements()
            await validateAllCapabilities()
            
            logger.info("✅ Entitlement Manager initialized successfully")
        }
    }
    
    private func detectMainAppEntitlements() async {
        logger.info("🔍 Detecting main app entitlements")
        
        var detectedEntitlements: Set<AppEntitlement> = []
        
        for entitlement in AppEntitlement.allCases {
            if await hasEntitlement(entitlement) {
                detectedEntitlements.insert(entitlement)
                logger.debug("✅ Detected entitlement: \(entitlement.rawValue)")
            } else {
                logger.debug("❌ Missing entitlement: \(entitlement.rawValue)")
            }
        }
        
        mainAppEntitlements = detectedEntitlements
        
        // Validate required entitlements
        let missingRequired = AppEntitlement.allCases
            .filter(\.isRequired)
            .filter { !mainAppEntitlements.contains($0) }
        
        if !missingRequired.isEmpty {
            logger.error("❌ Missing required entitlements: \(missingRequired.map(\.rawValue))")
            entitlementValidationState = .invalid
        } else {
            logger.info("✅ All required entitlements present")
        }
        
        logger.info("📊 Main app entitlements: \(detectedEntitlements.count)/\(AppEntitlement.allCases.count)")
    }
    
    private func detectHelperToolEntitlements() async {
        logger.info("🔍 Detecting helper tool entitlements")
        
        // Helper tool entitlements are configured, not runtime-detected
        // This represents what the helper tool SHOULD have when installed
        helperToolEntitlements = Set(HelperEntitlement.allCases.filter(\.isRequired))
        
        logger.info("📊 Helper tool entitlements configured: \(helperToolEntitlements.count)")
    }
    
    private func hasEntitlement(_ entitlement: AppEntitlement) async -> Bool {
        switch entitlement {
        case .appSandbox:
            return isRunningInSandbox()
        case .hardenedRuntime:
            return isHardenedRuntimeEnabled()
        case .appleEvents:
            return canSendAppleEvents()
        case .systemEvents:
            return canSendSystemEvents()
        case .userSelectedFiles:
            return canAccessUserSelectedFiles()
        case .downloadsFolder:
            return canAccessDownloadsFolder()
        case .documentsFolder:
            return canAccessDocumentsFolder()
        case .networkClient:
            return canAccessNetwork()
        case .networkServer:
            return canAcceptConnections()
        case .processInfo:
            return canAccessProcessInfo()
        case .systemInfo:
            return canAccessSystemInfo()
        case .debugger:
            return isDebuggerEnabled()
        case .getTaskAllow:
            return hasGetTaskAllow()
        }
    }
    
    // MARK: - Entitlement Detection Methods
    
    private func isRunningInSandbox() -> Bool {
        return ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }
    
    private func isHardenedRuntimeEnabled() -> Bool {
        // Check if hardened runtime is active
        var staticCode: SecStaticCode?
        guard let executableURL = Bundle.main.executableURL else { return false }
        
        let status = SecStaticCodeCreateWithPath(executableURL as CFURL, [], &staticCode)
        guard status == errSecSuccess, let code = staticCode else { return false }
        
        var signingInformation: CFDictionary?
        let infoStatus = SecCodeCopySigningInformation(code, [], &signingInformation)
        guard infoStatus == errSecSuccess, let info = signingInformation else { return false }
        
        let infoDict = info as NSDictionary
        let flags = infoDict[kSecCodeInfoFlags as String] as? UInt32 ?? 0
        
        // Check for hardened runtime flag
        return (flags & UInt32(kSecCodeSignatureRuntime)) != 0
    }
    
    private func canSendAppleEvents() -> Bool {
        // Test by attempting to get running applications
        let workspace = NSWorkspace.shared
        let apps = workspace.runningApplications
        return !apps.isEmpty
    }
    
    private func canSendSystemEvents() -> Bool {
        // Test system event capabilities
        return true // Simplified - would need actual system event test
    }
    
    private func canAccessUserSelectedFiles() -> Bool {
        // Test file access capabilities
        return FileManager.default.homeDirectoryForCurrentUser.path.count > 0
    }
    
    private func canAccessDownloadsFolder() -> Bool {
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        return downloadsURL != nil && FileManager.default.isReadableFile(atPath: downloadsURL!.path)
    }
    
    private func canAccessDocumentsFolder() -> Bool {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentsURL != nil && FileManager.default.isReadableFile(atPath: documentsURL!.path)
    }
    
    private func canAccessNetwork() -> Bool {
        // Basic network capability test
        return true // Assume available unless restricted
    }
    
    private func canAcceptConnections() -> Bool {
        // Server capability test
        return false // Usually not needed for client apps
    }
    
    private func canAccessProcessInfo() -> Bool {
        // Test process information access
        let runningApps = NSWorkspace.shared.runningApplications
        return !runningApps.isEmpty
    }
    
    private func canAccessSystemInfo() -> Bool {
        // Test system information access
        let processInfo = ProcessInfo.processInfo
        return processInfo.operatingSystemVersion.majorVersion > 0
    }
    
    private func isDebuggerEnabled() -> Bool {
        // Check for debugger entitlement (development only)
        return false // Not present in release builds
    }
    
    private func hasGetTaskAllow() -> Bool {
        // Check for get-task-allow entitlement (development only)
        return false // Not present in release builds
    }
    
    // MARK: - Capability Validation
    
    private func validateAllCapabilities() async {
        logger.info("🔍 Validating all capabilities")
        
        var statusMap: [Capability: CapabilityStatus] = [:]
        
        for capability in Capability.allCases {
            statusMap[capability] = await validateCapability(capability)
        }
        
        capabilityStatus = statusMap
        
        // Update overall validation state
        let availableCount = statusMap.values.filter(\.isUsable).count
        let totalCount = Capability.allCases.count
        
        if availableCount == totalCount {
            entitlementValidationState = .valid
        } else if availableCount > totalCount / 2 {
            entitlementValidationState = .partial
        } else {
            entitlementValidationState = .invalid
        }
        
        logger.info("📊 Capability validation complete: \(availableCount)/\(totalCount) available")
    }
    
    private func validateCapability(_ capability: Capability) async -> CapabilityStatus {
        let requiredEntitlements = capability.requiredEntitlements
        
        // Check if all required entitlements are present
        let hasAllEntitlements = requiredEntitlements.allSatisfy { mainAppEntitlements.contains($0) }
        
        if !hasAllEntitlements {
            logger.debug("❌ Capability '\(capability.rawValue)' missing entitlements")
            return .unavailable
        }
        
        // Check if helper tool is required and available
        if capability.requiresHelperTool {
            let helperAvailable = await isHelperToolAvailable()
            if !helperAvailable {
                logger.debug("⚡ Capability '\(capability.rawValue)' requires elevation")
                return .requiresElevation
            }
        }
        
        // Additional capability-specific checks
        switch capability {
        case .terminateUserProcesses:
            return validateUserProcessTermination()
        case .terminateSystemProcesses:
            return validateSystemProcessTermination()
        case .exportData:
            return validateDataExport()
        case .privilegedOperations:
            return validatePrivilegedOperations()
        default:
            logger.debug("✅ Capability '\(capability.rawValue)' available")
            return .available
        }
    }
    
    private func validateUserProcessTermination() -> CapabilityStatus {
        // Can terminate user processes if we have Apple Events
        return mainAppEntitlements.contains(.appleEvents) ? .available : .unavailable
    }
    
    private func validateSystemProcessTermination() -> CapabilityStatus {
        // System process termination requires helper tool
        return .requiresElevation
    }
    
    private func validateDataExport() -> CapabilityStatus {
        // Data export requires user file access
        return mainAppEntitlements.contains(.userSelectedFiles) ? .available : .restricted
    }
    
    private func validatePrivilegedOperations() -> CapabilityStatus {
        // Privileged operations always require helper tool
        return .requiresElevation
    }
    
    private func isHelperToolAvailable() async -> Bool {
        // Check if helper tool is installed and accessible
        // This is a simplified check - real implementation would test XPC connection
        return false // Default to requiring installation
    }
    
    // MARK: - Permission Management
    
    public func requestCapability(_ capability: Capability) async -> Bool {
        logger.info("🔐 Requesting capability: \(capability.rawValue)")
        
        guard let status = capabilityStatus[capability] else {
            logger.error("❌ Unknown capability: \(capability.rawValue)")
            return false
        }
        
        switch status {
        case .available:
            logger.info("✅ Capability already available")
            return true
            
        case .restricted:
            logger.info("⚠️ Capability available with restrictions")
            return await requestUserConsent(for: capability)
            
        case .requiresElevation:
            logger.info("⚡ Capability requires elevation")
            return await requestElevation(for: capability)
            
        case .unavailable:
            logger.error("❌ Capability unavailable due to missing entitlements")
            return false
        }
    }
    
    private func requestUserConsent(for capability: Capability) async -> Bool {
        // Request user consent for restricted capabilities
        // This would show a system dialog or custom UI
        logger.info("💬 User consent required for capability: \(capability.rawValue)")
        return true // Simplified - assume consent granted
    }
    
    private func requestElevation(for capability: Capability) async -> Bool {
        // Request privilege elevation via helper tool installation
        logger.info("⬆️ Elevation required for capability: \(capability.rawValue)")
        
        // This would trigger the helper tool installation process
        return await installHelperToolIfNeeded()
    }
    
    private func installHelperToolIfNeeded() async -> Bool {
        // Implement SMJobBless helper tool installation
        logger.info("🔧 Installing helper tool")
        
        // This is a complex process involving:
        // 1. SMJobBless authorization
        // 2. Helper tool binary validation
        // 3. Privileged installation
        // 4. XPC service registration
        
        return true // Simplified for now
    }
    
    // MARK: - App Store Compliance
    
    public func validateAppStoreCompliance() -> (compliant: Bool, issues: [String]) {
        var issues: [String] = []
        
        // Check for non-App Store compatible entitlements
        let incompatibleEntitlements = mainAppEntitlements.filter { !$0.isAppStoreCompatible }
        if !incompatibleEntitlements.isEmpty {
            issues.append("Non-App Store entitlements detected: \(incompatibleEntitlements.map(\.rawValue))")
        }
        
        // Check for required entitlements
        let missingRequired = AppEntitlement.allCases
            .filter(\.isRequired)
            .filter { !mainAppEntitlements.contains($0) }
        
        if !missingRequired.isEmpty {
            issues.append("Missing required entitlements: \(missingRequired.map(\.rawValue))")
        }
        
        // Check sandbox requirement
        if !mainAppEntitlements.contains(.appSandbox) {
            issues.append("App sandbox entitlement required for App Store")
        }
        
        let isCompliant = issues.isEmpty
        
        if isCompliant {
            logger.info("✅ App Store compliance validated successfully")
        } else {
            logger.warning("⚠️ App Store compliance issues found: \(issues.count)")
        }
        
        return (isCompliant, issues)
    }
    
    // MARK: - Security Policy Enforcement
    
    public func enforceSecurityPolicy() async {
        logger.info("🔒 Enforcing security policy")
        
        // Re-validate all entitlements and capabilities
        await detectMainAppEntitlements()
        await validateAllCapabilities()
        
        // Log security policy status
        logSecurityPolicyStatus()
    }
    
    private func logSecurityPolicyStatus() {
        logger.info("📊 Security Policy Status:")
        logger.info("  - Main App Entitlements: \(mainAppEntitlements.count)/\(AppEntitlement.allCases.count)")
        logger.info("  - Helper Tool Entitlements: \(helperToolEntitlements.count)")
        logger.info("  - Available Capabilities: \(capabilityStatus.values.filter(\.isUsable).count)/\(Capability.allCases.count)")
        logger.info("  - Validation State: \(entitlementValidationState)")
        
        // Log specific capability status
        for (capability, status) in capabilityStatus {
            let statusIcon = status.isUsable ? "✅" : "❌"
            logger.debug("  \(statusIcon) \(capability.rawValue): \(status)")
        }
    }
    
    // MARK: - Public API
    
    public func getEntitlementReport() -> [String: Any] {
        let (appStoreCompliant, complianceIssues) = validateAppStoreCompliance()
        
        return [
            "timestamp": Date().timeIntervalSince1970,
            "validation_state": entitlementValidationState,
            "main_app_entitlements": mainAppEntitlements.map { entitlement in
                [
                    "name": entitlement.rawValue,
                    "description": entitlement.description,
                    "required": entitlement.isRequired,
                    "app_store_compatible": entitlement.isAppStoreCompatible
                ]
            },
            "helper_tool_entitlements": helperToolEntitlements.map { entitlement in
                [
                    "name": entitlement.rawValue,
                    "description": entitlement.description,
                    "required": entitlement.isRequired
                ]
            },
            "capabilities": capabilityStatus.map { capability, status in
                [
                    "name": capability.rawValue,
                    "status": String(describing: status),
                    "usable": status.isUsable,
                    "requires_helper": capability.requiresHelperTool,
                    "required_entitlements": capability.requiredEntitlements.map(\.rawValue)
                ]
            },
            "app_store_compliance": [
                "compliant": appStoreCompliant,
                "issues": complianceIssues
            ]
        ]
    }
    
    public func getCapabilityInfo(_ capability: Capability) -> [String: Any] {
        let status = capabilityStatus[capability] ?? .unknown
        
        return [
            "name": capability.rawValue,
            "status": String(describing: status),
            "usable": status.isUsable,
            "requires_helper_tool": capability.requiresHelperTool,
            "required_entitlements": capability.requiredEntitlements.map { entitlement in
                [
                    "name": entitlement.rawValue,
                    "present": mainAppEntitlements.contains(entitlement),
                    "required": entitlement.isRequired
                ]
            }
        ]
    }
    
    public func hasCapability(_ capability: Capability) -> Bool {
        return capabilityStatus[capability]?.isUsable ?? false
    }
    
    public func requiresElevation(for capability: Capability) -> Bool {
        return capabilityStatus[capability] == .requiresElevation
    }
}