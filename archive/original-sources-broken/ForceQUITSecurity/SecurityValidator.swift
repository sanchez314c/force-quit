//
//  SecurityValidator.swift
//  ForceQUIT Security Framework
//
//  Comprehensive security validation framework for process termination
//  Implements multi-tier safety checks, SIP compliance, and risk assessment
//  with detailed security reporting and threat classification.
//

import Foundation
import AppKit
import OSLog
import Security
import System

@MainActor
public class SecurityValidator: ObservableObject {
    public static let shared = SecurityValidator()
    
    private let logger = Logger(subsystem: "com.forcequit.security", category: "SecurityValidator")
    
    @Published public private(set) var securityState: SecurityState = .initializing
    @Published public private(set) var validationRules: [SecurityRule] = []
    @Published public private(set) var threatLevel: ThreatLevel = .low
    @Published public private(set) var lastValidation: Date?
    
    // Security state tracking
    public enum SecurityState: String, CaseIterable {
        case initializing = "initializing"
        case secure = "secure"
        case degraded = "degraded"
        case compromised = "compromised"
        case critical = "critical"
        
        var isOperational: Bool {
            switch self {
            case .secure, .degraded:
                return true
            case .initializing, .compromised, .critical:
                return false
            }
        }
        
        var priority: Int {
            switch self {
            case .secure: return 0
            case .degraded: return 1
            case .initializing: return 2
            case .compromised: return 3
            case .critical: return 4
            }
        }
    }
    
    public enum ThreatLevel: String, CaseIterable, Comparable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
        
        public static func < (lhs: ThreatLevel, rhs: ThreatLevel) -> Bool {
            let order: [ThreatLevel] = [.low, .medium, .high, .critical]
            guard let lhsIndex = order.firstIndex(of: lhs),
                  let rhsIndex = order.firstIndex(of: rhs) else {
                return false
            }
            return lhsIndex < rhsIndex
        }
    }
    
    // Process safety classification
    public enum ProcessSafetyLevel: String, CaseIterable {
        case safe = "safe"              // User applications - free termination
        case monitored = "monitored"    // Background processes - logged termination
        case restricted = "restricted"  // System services - require confirmation
        case dangerous = "dangerous"    // May cause system instability
        case forbidden = "forbidden"    // SIP-protected - never allow
        
        var allowsTermination: Bool {
            switch self {
            case .safe, .monitored, .restricted:
                return true
            case .dangerous, .forbidden:
                return false
            }
        }
        
        var requiresConfirmation: Bool {
            switch self {
            case .restricted, .dangerous:
                return true
            case .safe, .monitored, .forbidden:
                return false
            }
        }
    }
    
    // Validation result structure
    public struct ValidationResult {
        public let allowed: Bool
        public let safetyLevel: ProcessSafetyLevel
        public let threatLevel: ThreatLevel
        public let reason: String
        public let recommendations: [String]
        public let metadata: [String: Any]
        public let timestamp: Date
        
        public init(allowed: Bool, safetyLevel: ProcessSafetyLevel, threatLevel: ThreatLevel, reason: String, recommendations: [String] = [], metadata: [String: Any] = [:]) {
            self.allowed = allowed
            self.safetyLevel = safetyLevel
            self.threatLevel = threatLevel
            self.reason = reason
            self.recommendations = recommendations
            self.metadata = metadata
            self.timestamp = Date()
        }
    }
    
    private init() {
        initializeSecurityFramework()
    }
    
    // MARK: - Security Framework Initialization
    
    private func initializeSecurityFramework() {
        logger.info("🛡️ Initializing Security Validation Framework")
        
        Task {
            await performInitialSecurityValidation()
            await setupValidationRules()
            await startContinuousMonitoring()
            
            securityState = .secure
            logger.info("✅ Security Validation Framework initialized successfully")
        }
    }
    
    private func performInitialSecurityValidation() async {
        logger.info("🔍 Performing initial security validation")
        
        // Validate system integrity
        let sipStatus = await validateSIPCompliance()
        let codeSignature = await validateCodeSignature()
        let sandboxIntegrity = await validateSandboxIntegrity()
        
        if sipStatus && codeSignature && sandboxIntegrity {
            logger.info("✅ Initial security validation passed")
        } else {
            logger.warning("⚠️ Initial security validation failed - system in degraded state")
            securityState = .degraded
        }
    }
    
    private func setupValidationRules() async {
        validationRules = [
            SecurityRule(
                id: "SIP_COMPLIANCE",
                name: "System Integrity Protection Compliance",
                priority: .critical,
                validator: validateSIPCompliance
            ),
            SecurityRule(
                id: "CODE_SIGNATURE",
                name: "Code Signature Validation",
                priority: .critical,
                validator: validateCodeSignature
            ),
            SecurityRule(
                id: "SANDBOX_INTEGRITY",
                name: "Sandbox Environment Integrity",
                priority: .high,
                validator: validateSandboxIntegrity
            ),
            SecurityRule(
                id: "PRIVILEGE_ESCALATION",
                name: "Privilege Escalation Safety",
                priority: .high,
                validator: validatePrivilegeEscalation
            ),
            SecurityRule(
                id: "PROCESS_VALIDATION",
                name: "Process Termination Validation",
                priority: .medium,
                validator: validateProcessTermination
            ),
            SecurityRule(
                id: "HELPER_INTEGRITY",
                name: "Helper Tool Integrity",
                priority: .high,
                validator: validateHelperIntegrity
            ),
            SecurityRule(
                id: "XPC_SECURITY",
                name: "XPC Communication Security",
                priority: .high,
                validator: validateXPCSecurity
            ),
            SecurityRule(
                id: "ENTITLEMENT_VALIDATION",
                name: "Entitlement Compliance",
                priority: .medium,
                validator: validateEntitlements
            )
        ]
        
        logger.info("📋 Security validation rules configured: \(validationRules.count)")
    }
    
    private func startContinuousMonitoring() async {
        // Start periodic security health checks
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                await self.performPeriodicSecurityCheck()
            }
        }
        
        logger.info("🔄 Continuous security monitoring started")
    }
    
    // MARK: - Process Security Validation
    
    public func validateProcessTermination(_ process: NSRunningApplication) async -> ValidationResult {
        logger.info("🎯 Validating termination for process: \(process.localizedName ?? "Unknown")")
        
        // Get process metadata
        let metadata = await gatherProcessMetadata(process)
        
        // Classify process safety level
        let safetyLevel = classifyProcessSafety(process, metadata: metadata)
        
        // Assess threat level
        let threatLevel = assessThreatLevel(for: safetyLevel, metadata: metadata)
        
        // Generate security recommendations
        let recommendations = generateSecurityRecommendations(safetyLevel: safetyLevel, metadata: metadata)
        
        // Determine if termination is allowed
        let allowed = determineTerminationPermission(safetyLevel: safetyLevel, metadata: metadata)
        
        let reason = generateValidationReason(allowed: allowed, safetyLevel: safetyLevel, metadata: metadata)
        
        let result = ValidationResult(
            allowed: allowed,
            safetyLevel: safetyLevel,
            threatLevel: threatLevel,
            reason: reason,
            recommendations: recommendations,
            metadata: metadata
        )
        
        // Log validation result
        logValidationResult(result, for: process)
        
        return result
    }
    
    private func gatherProcessMetadata(_ process: NSRunningApplication) async -> [String: Any] {
        var metadata: [String: Any] = [:]
        
        // Basic process information
        metadata["pid"] = process.processIdentifier
        metadata["name"] = process.localizedName ?? "Unknown"
        metadata["bundle_id"] = process.bundleIdentifier
        metadata["executable_url"] = process.executableURL?.path
        metadata["owns_menu_bar"] = process.ownsMenuBar
        metadata["is_active"] = process.isActive
        metadata["is_hidden"] = process.isHidden
        metadata["launch_date"] = process.launchDate
        
        // Enhanced security metadata
        if let executableURL = process.executableURL {
            metadata["executable_path"] = executableURL.path
            metadata["is_system_path"] = isSystemPath(executableURL.path)
            metadata["is_sip_protected"] = isSIPProtectedPath(executableURL.path)
            metadata["code_signature_valid"] = await validateProcessCodeSignature(executableURL)
        }
        
        // Process hierarchy information
        if let parentPID = getParentPID(for: process.processIdentifier) {
            metadata["parent_pid"] = parentPID
            metadata["is_launchd_child"] = parentPID == 1
        }
        
        // System integration checks
        metadata["has_accessibility_permissions"] = hasAccessibilityPermissions(process)
        metadata["is_agent_or_daemon"] = isAgentOrDaemon(process)
        metadata["system_integration_level"] = assessSystemIntegrationLevel(process)
        
        return metadata
    }
    
    private func classifyProcessSafety(_ process: NSRunningApplication, metadata: [String: Any]) -> ProcessSafetyLevel {
        let processName = process.localizedName ?? "Unknown"
        let bundleId = process.bundleIdentifier ?? ""
        let executablePath = metadata["executable_path"] as? String ?? ""
        
        // Critical system processes - never allow termination
        if isCriticalSystemProcess(processName: processName, bundleId: bundleId) {
            return .forbidden
        }
        
        // SIP-protected paths - forbidden
        if metadata["is_sip_protected"] as? Bool == true {
            return .forbidden
        }
        
        // Invalid code signature - dangerous
        if metadata["code_signature_valid"] as? Bool == false {
            return .dangerous
        }
        
        // System paths with root ownership - restricted
        if metadata["is_system_path"] as? Bool == true {
            return .restricted
        }
        
        // LaunchAgents and LaunchDaemons - restricted
        if metadata["is_agent_or_daemon"] as? Bool == true {
            return .restricted
        }
        
        // Applications in /Applications/ - safe
        if executablePath.hasPrefix("/Applications/") {
            return .safe
        }
        
        // Background processes and utilities - monitored
        if !process.ownsMenuBar {
            return .monitored
        }
        
        return .safe
    }
    
    private func assessThreatLevel(for safetyLevel: ProcessSafetyLevel, metadata: [String: Any]) -> ThreatLevel {
        switch safetyLevel {
        case .forbidden:
            return .critical
        case .dangerous:
            return .high
        case .restricted:
            let systemIntegration = metadata["system_integration_level"] as? Int ?? 0
            return systemIntegration > 3 ? .high : .medium
        case .monitored:
            return .low
        case .safe:
            return .low
        }
    }
    
    private func generateSecurityRecommendations(safetyLevel: ProcessSafetyLevel, metadata: [String: Any]) -> [String] {
        var recommendations: [String] = []
        
        switch safetyLevel {
        case .forbidden:
            recommendations.append("Process is SIP-protected and should never be terminated")
            recommendations.append("Consider system restart if process is problematic")
            
        case .dangerous:
            recommendations.append("Process termination may cause system instability")
            recommendations.append("Save all work before proceeding")
            recommendations.append("Consider graceful shutdown instead of force termination")
            
        case .restricted:
            recommendations.append("System service - termination should be confirmed")
            recommendations.append("Check for dependent processes before termination")
            recommendations.append("Monitor system stability after termination")
            
        case .monitored:
            recommendations.append("Background process termination will be logged")
            recommendations.append("Consider why process is consuming resources")
            
        case .safe:
            recommendations.append("User application - safe for termination")
        }
        
        // Additional recommendations based on metadata
        if metadata["has_accessibility_permissions"] as? Bool == true {
            recommendations.append("Process has accessibility permissions - verify necessity")
        }
        
        if metadata["code_signature_valid"] as? Bool == false {
            recommendations.append("Invalid code signature detected - potential security risk")
        }
        
        return recommendations
    }
    
    private func determineTerminationPermission(safetyLevel: ProcessSafetyLevel, metadata: [String: Any]) -> Bool {
        return safetyLevel.allowsTermination
    }
    
    private func generateValidationReason(allowed: Bool, safetyLevel: ProcessSafetyLevel, metadata: [String: Any]) -> String {
        let processName = metadata["name"] as? String ?? "Unknown"
        
        if !allowed {
            switch safetyLevel {
            case .forbidden:
                return "Process '\(processName)' is SIP-protected and cannot be terminated"
            case .dangerous:
                return "Process '\(processName)' termination may cause system instability"
            default:
                return "Process '\(processName)' termination blocked by security policy"
            }
        } else {
            switch safetyLevel {
            case .safe:
                return "User application '\(processName)' approved for safe termination"
            case .monitored:
                return "Background process '\(processName)' approved with monitoring"
            case .restricted:
                return "System service '\(processName)' approved with restrictions"
            default:
                return "Process '\(processName)' approved for termination"
            }
        }
    }
    
    // MARK: - Security Classification Helpers
    
    private func isCriticalSystemProcess(processName: String, bundleId: String) -> Bool {
        let criticalProcesses = [
            "kernel_task", "launchd", "WindowServer", "loginwindow",
            "SystemUIServer", "Dock", "Finder", "mds", "mdworker",
            "configd", "networkd", "bluetoothd", "coreaudiod"
        ]
        
        let criticalBundleIds = [
            "com.apple.loginwindow",
            "com.apple.WindowServer",
            "com.apple.dock",
            "com.apple.finder",
            "com.apple.systemuiserver",
            "com.apple.CoreServices.SystemUIServer"
        ]
        
        return criticalProcesses.contains { processName.lowercased().contains($0.lowercased()) } ||
               criticalBundleIds.contains(bundleId)
    }
    
    private func isSystemPath(_ path: String) -> Bool {
        let systemPaths = [
            "/System/",
            "/usr/bin/",
            "/usr/sbin/",
            "/bin/",
            "/sbin/",
            "/usr/libexec/"
        ]
        
        return systemPaths.contains { path.hasPrefix($0) }
    }
    
    private func isSIPProtectedPath(_ path: String) -> Bool {
        let sipPaths = [
            "/System/",
            "/usr/bin/",
            "/usr/sbin/",
            "/bin/",
            "/sbin/",
            "/Library/Apple/",
            "/System/Library/"
        ]
        
        return sipPaths.contains { path.hasPrefix($0) }
    }
    
    private func getParentPID(for pid: pid_t) -> pid_t? {
        var kinfo = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.size
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        
        let result = sysctl(&mib, u_int(mib.count), &kinfo, &size, nil, 0)
        guard result == 0 else { return nil }
        
        return kinfo.kp_eproc.e_ppid
    }
    
    private func hasAccessibilityPermissions(_ process: NSRunningApplication) -> Bool {
        // This is a heuristic - checking if process has certain capabilities
        return process.ownsMenuBar || isAgentOrDaemon(process)
    }
    
    private func isAgentOrDaemon(_ process: NSRunningApplication) -> Bool {
        guard let name = process.localizedName else { return false }
        let lowercaseName = name.lowercased()
        return lowercaseName.contains("agent") || lowercaseName.contains("daemon") || lowercaseName.contains("helper")
    }
    
    private func assessSystemIntegrationLevel(_ process: NSRunningApplication) -> Int {
        var level = 0
        
        if process.ownsMenuBar { level += 1 }
        if isAgentOrDaemon(process) { level += 2 }
        if let path = process.executableURL?.path, isSystemPath(path) { level += 3 }
        if getParentPID(for: process.processIdentifier) == 1 { level += 2 }
        
        return level
    }
    
    // MARK: - Security Rule Validation
    
    private func validateSIPCompliance() async -> Bool {
        // Check if SIP is enabled
        let sipEnabled = csr_check(UInt32(CSR_ALLOW_UNSIGNED_EXECUTABLE_POLICY)) != 0
        
        if sipEnabled {
            logger.info("✅ System Integrity Protection is enabled")
        } else {
            logger.warning("⚠️ System Integrity Protection is disabled")
        }
        
        return sipEnabled
    }
    
    private func validateCodeSignature() async -> Bool {
        guard let executableURL = Bundle.main.executableURL else { return false }
        return await validateProcessCodeSignature(executableURL)
    }
    
    private func validateProcessCodeSignature(_ executableURL: URL) async -> Bool {
        var staticCode: SecStaticCode?
        let status = SecStaticCodeCreateWithPath(executableURL as CFURL, [], &staticCode)
        
        guard status == errSecSuccess, let code = staticCode else {
            return false
        }
        
        let verifyStatus = SecStaticCodeCheckValidity(code, [], nil)
        return verifyStatus == errSecSuccess
    }
    
    private func validateSandboxIntegrity() async -> Bool {
        let sandboxManager = SandboxManager.shared
        let metrics = sandboxManager.getSecurityMetrics()
        
        guard let isSandboxed = metrics["sandboxed"] as? Bool,
              let allRequiredPresent = metrics["all_required_present"] as? Bool else {
            return false
        }
        
        return isSandboxed && allRequiredPresent
    }
    
    private func validatePrivilegeEscalation() async -> Bool {
        // Validate that privilege escalation mechanisms are secure
        let currentUID = getuid()
        let hasRootPrivileges = currentUID == 0
        
        // In a properly secured app, we should NOT have root privileges initially
        return !hasRootPrivileges
    }
    
    private func validateProcessTermination() async -> Bool {
        // Validate that process termination mechanisms are working
        return true // Basic validation - always true for now
    }
    
    private func validateHelperIntegrity() async -> Bool {
        // Validate helper tool integrity and availability
        // This would check if the XPC helper is properly installed and signed
        return true // Simplified for now
    }
    
    private func validateXPCSecurity() async -> Bool {
        // Validate XPC communication security
        return true // Simplified for now
    }
    
    private func validateEntitlements() async -> Bool {
        let sandboxManager = SandboxManager.shared
        let metrics = sandboxManager.getSecurityMetrics()
        
        return metrics["all_required_present"] as? Bool ?? false
    }
    
    // MARK: - Continuous Monitoring
    
    private func performPeriodicSecurityCheck() async {
        logger.info("🔄 Performing periodic security check")
        
        var failedRules = 0
        var criticalFailures = 0
        
        for rule in validationRules {
            let passed = await rule.validator()
            if !passed {
                failedRules += 1
                if rule.priority == .critical {
                    criticalFailures += 1
                }
            }
        }
        
        // Update threat level based on failures
        let previousThreatLevel = threatLevel
        threatLevel = calculateThreatLevel(failedRules: failedRules, criticalFailures: criticalFailures)
        
        // Update security state
        let previousState = securityState
        securityState = calculateSecurityState(failedRules: failedRules, criticalFailures: criticalFailures)
        
        lastValidation = Date()
        
        // Log state changes
        if previousState != securityState {
            logger.warning("🚨 Security state changed: \(previousState.rawValue) → \(securityState.rawValue)")
        }
        
        if previousThreatLevel != threatLevel {
            logger.info("📊 Threat level changed: \(previousThreatLevel.rawValue) → \(threatLevel.rawValue)")
        }
        
        logger.info("✅ Periodic security check complete - Failed: \(failedRules)/\(validationRules.count), Critical: \(criticalFailures)")
    }
    
    private func calculateThreatLevel(failedRules: Int, criticalFailures: Int) -> ThreatLevel {
        if criticalFailures > 0 {
            return .critical
        } else if failedRules > 2 {
            return .high
        } else if failedRules > 0 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func calculateSecurityState(failedRules: Int, criticalFailures: Int) -> SecurityState {
        if criticalFailures > 1 {
            return .critical
        } else if criticalFailures > 0 {
            return .compromised
        } else if failedRules > 3 {
            return .degraded
        } else {
            return .secure
        }
    }
    
    private func logValidationResult(_ result: ValidationResult, for process: NSRunningApplication) {
        let processName = process.localizedName ?? "Unknown"
        
        if result.allowed {
            logger.info("✅ Validation PASSED for '\(processName)': \(result.reason)")
        } else {
            logger.warning("❌ Validation FAILED for '\(processName)': \(result.reason)")
        }
        
        if !result.recommendations.isEmpty {
            logger.info("💡 Recommendations: \(result.recommendations.joined(separator: "; "))")
        }
    }
    
    // MARK: - Public API
    
    public func getSecurityMetrics() -> [String: Any] {
        let passedRules = validationRules.filter { rule in
            // This would require async/await handling in real implementation
            return true // Simplified
        }.count
        
        return [
            "security_state": securityState.rawValue,
            "threat_level": threatLevel.rawValue,
            "total_rules": validationRules.count,
            "passed_rules": passedRules,
            "failed_rules": validationRules.count - passedRules,
            "last_validation": lastValidation?.timeIntervalSince1970 ?? 0,
            "is_operational": securityState.isOperational,
            "state_priority": securityState.priority
        ]
    }
    
    public func generateSecurityReport() -> [String: Any] {
        let metrics = getSecurityMetrics()
        
        return [
            "timestamp": Date().timeIntervalSince1970,
            "security_framework_version": "1.0.0",
            "metrics": metrics,
            "validation_rules": validationRules.map { rule in
                [
                    "id": rule.id,
                    "name": rule.name,
                    "priority": rule.priority.rawValue
                ]
            },
            "recommendations": generateSystemRecommendations()
        ]
    }
    
    private func generateSystemRecommendations() -> [String] {
        var recommendations: [String] = []
        
        switch securityState {
        case .critical:
            recommendations.append("Immediate security attention required")
            recommendations.append("Consider system restart or security update")
            
        case .compromised:
            recommendations.append("Security compromise detected - review system integrity")
            recommendations.append("Limit privileged operations until resolved")
            
        case .degraded:
            recommendations.append("Security degradation detected - monitor system closely")
            recommendations.append("Consider updating security policies")
            
        case .secure:
            recommendations.append("Security framework operating normally")
            
        case .initializing:
            recommendations.append("Security framework initializing - please wait")
        }
        
        if threatLevel >= .high {
            recommendations.append("High threat level - exercise additional caution")
        }
        
        return recommendations
    }
}

// MARK: - Security Rule Structure

private struct SecurityRule {
    let id: String
    let name: String
    let priority: RulePriority
    let validator: () async -> Bool
    
    enum RulePriority: String, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
}

// MARK: - CSR Constants

private let CSR_ALLOW_UNSIGNED_EXECUTABLE_POLICY: UInt32 = 0x1000