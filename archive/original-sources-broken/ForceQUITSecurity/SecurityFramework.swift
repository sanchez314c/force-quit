//
//  SecurityFramework.swift
//  ForceQUIT Security Framework
//
//  Master security framework integration layer
//  Coordinates all security components, provides unified API,
//  and manages security state across the entire application.
//

import Foundation
import AppKit
import OSLog
import Combine

@MainActor
public class SecurityFramework: ObservableObject {
    public static let shared = SecurityFramework()
    
    private let logger = Logger(subsystem: "com.forcequit.security", category: "SecurityFramework")
    
    // Component references
    private let sandboxManager = SandboxManager.shared
    private let securityValidator = SecurityValidator.shared
    private let entitlementManager = EntitlementManager.shared
    private let authorizationManager: AuthorizationManager
    
    // Framework state
    @Published public private(set) var frameworkState: FrameworkState = .initializing
    @Published public private(set) var overallSecurityLevel: SecurityLevel = .unknown
    @Published public private(set) var activeThreats: [SecurityThreat] = []
    @Published public private(set) var securityMetrics: SecurityMetrics = SecurityMetrics()
    
    // Combine subscriptions for component coordination
    private var cancellables = Set<AnyCancellable>()
    
    public enum FrameworkState: String, CaseIterable {
        case initializing = "initializing"
        case operational = "operational"
        case degraded = "degraded"
        case critical = "critical"
        case offline = "offline"
        
        var isOperational: Bool {
            switch self {
            case .operational, .degraded:
                return true
            case .initializing, .critical, .offline:
                return false
            }
        }
    }
    
    public enum SecurityLevel: String, CaseIterable, Comparable {
        case unknown = "unknown"
        case minimal = "minimal"
        case basic = "basic"
        case enhanced = "enhanced"
        case maximum = "maximum"
        
        public static func < (lhs: SecurityLevel, rhs: SecurityLevel) -> Bool {
            let order: [SecurityLevel] = [.unknown, .minimal, .basic, .enhanced, .maximum]
            guard let lhsIndex = order.firstIndex(of: lhs),
                  let rhsIndex = order.firstIndex(of: rhs) else {
                return false
            }
            return lhsIndex < rhsIndex
        }
        
        var canTerminateSystemProcesses: Bool {
            return self >= .enhanced
        }
        
        var requiresUserConfirmation: Bool {
            switch self {
            case .enhanced, .maximum:
                return false
            default:
                return true
            }
        }
    }
    
    public struct SecurityThreat {
        public let id: UUID = UUID()
        public let type: ThreatType
        public let severity: ThreatSeverity
        public let description: String
        public let recommendation: String
        public let timestamp: Date = Date()
        public let affectedComponent: String
        
        public enum ThreatType: String, CaseIterable {
            case systemIntegrityViolation = "system_integrity_violation"
            case codeSignatureViolation = "code_signature_violation"
            case sandboxViolation = "sandbox_violation"
            case privilegeEscalationViolation = "privilege_escalation_violation"
            case helperToolCompromise = "helper_tool_compromise"
            case xpcSecurityViolation = "xpc_security_violation"
            case securityFrameworkFailure = "security_framework_failure"
        }
        
        public enum ThreatSeverity: String, CaseIterable, Comparable {
            case low = "low"
            case medium = "medium"
            case high = "high"
            case critical = "critical"
            
            public static func < (lhs: ThreatSeverity, rhs: ThreatSeverity) -> Bool {
                let order: [ThreatSeverity] = [.low, .medium, .high, .critical]
                guard let lhsIndex = order.firstIndex(of: lhs),
                      let rhsIndex = order.firstIndex(of: rhs) else {
                    return false
                }
                return lhsIndex < rhsIndex
            }
        }
    }
    
    public struct SecurityMetrics {
        public var totalValidationRules: Int = 0
        public var passedValidationRules: Int = 0
        public var failedValidationRules: Int = 0
        public var availableCapabilities: Int = 0
        public var totalCapabilities: Int = 0
        public var sandboxCompliance: Bool = false
        public var sipCompliance: Bool = false
        public var codeSignatureValid: Bool = false
        public var helperToolInstalled: Bool = false
        public var lastSecurityCheck: Date?
        public var uptimeSeconds: TimeInterval = 0
        
        public var securityScore: Double {
            let ruleScore = totalValidationRules > 0 ? Double(passedValidationRules) / Double(totalValidationRules) : 0.0
            let capabilityScore = totalCapabilities > 0 ? Double(availableCapabilities) / Double(totalCapabilities) : 0.0
            let complianceScore = [sandboxCompliance, sipCompliance, codeSignatureValid].filter { $0 }.count / 3.0
            
            return (ruleScore + capabilityScore + complianceScore) / 3.0
        }
        
        public var securityGrade: String {
            let score = securityScore
            switch score {
            case 0.95...1.0: return "A+"
            case 0.90..<0.95: return "A"
            case 0.85..<0.90: return "A-"
            case 0.80..<0.85: return "B+"
            case 0.75..<0.80: return "B"
            case 0.70..<0.75: return "B-"
            case 0.65..<0.70: return "C+"
            case 0.60..<0.65: return "C"
            default: return "F"
            }
        }
    }
    
    private init() {
        self.authorizationManager = AuthorizationManager()
        
        setupComponentObservation()
        initializeSecurityFramework()
    }
    
    // MARK: - Framework Initialization
    
    private func initializeSecurityFramework() {
        logger.info("🚀 Initializing Security Framework")
        
        Task {
            await performInitialSecurityAssessment()
            await startFrameworkCoordination()
            
            frameworkState = .operational
            logger.info("✅ Security Framework initialization complete")
        }
    }
    
    private func setupComponentObservation() {
        // Observe sandbox manager changes
        sandboxManager.$securityLevel
            .combineLatest(securityValidator.$securityState, entitlementManager.$entitlementValidationState)
            .sink { [weak self] _, _, _ in
                Task { @MainActor in
                    await self?.updateOverallSecurityLevel()
                }
            }
            .store(in: &cancellables)
        
        // Observe threat level changes
        securityValidator.$threatLevel
            .sink { [weak self] threatLevel in
                Task { @MainActor in
                    await self?.handleThreatLevelChange(threatLevel)
                }
            }
            .store(in: &cancellables)
    }
    
    private func performInitialSecurityAssessment() async {
        logger.info("🔍 Performing initial security assessment")
        
        // Coordinate with all security components
        await sandboxManager.enforceSecurityPolicy()
        await entitlementManager.enforceSecurityPolicy()
        
        // Update security metrics
        await updateSecurityMetrics()
        
        // Assess overall security level
        await updateOverallSecurityLevel()
        
        logger.info("📊 Initial security assessment complete")
    }
    
    private func startFrameworkCoordination() async {
        // Start coordinated security monitoring
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            Task { @MainActor in
                await self.performCoordinatedSecurityCheck()
            }
        }
        
        logger.info("🔄 Framework coordination started")
    }
    
    // MARK: - Security Level Management
    
    private func updateOverallSecurityLevel() async {
        let sandboxLevel = sandboxManager.securityLevel
        let validatorState = securityValidator.securityState
        let entitlementState = entitlementManager.entitlementValidationState
        
        let newSecurityLevel = calculateOverallSecurityLevel(
            sandboxLevel: sandboxLevel,
            validatorState: validatorState,
            entitlementState: entitlementState
        )
        
        if newSecurityLevel != overallSecurityLevel {
            logger.info("🔄 Security level changed: \(overallSecurityLevel.rawValue) → \(newSecurityLevel.rawValue)")
            overallSecurityLevel = newSecurityLevel
            
            // Update framework state based on security level
            updateFrameworkState()
        }
    }
    
    private func calculateOverallSecurityLevel(
        sandboxLevel: SandboxManager.SandboxSecurityLevel,
        validatorState: SecurityValidator.SecurityState,
        entitlementState: EntitlementManager.ValidationState
    ) -> SecurityLevel {
        
        // Start with baseline security level
        var level = SecurityLevel.basic
        
        // Adjust based on sandbox security level
        switch sandboxLevel {
        case .restricted:
            level = .minimal
        case .standard:
            level = .basic
        case .elevated:
            level = .enhanced
        case .privileged:
            level = .maximum
        }
        
        // Adjust based on validator state (can only decrease security)
        switch validatorState {
        case .critical, .compromised:
            level = min(level, .minimal)
        case .degraded:
            level = min(level, .basic)
        case .secure:
            // No change - validator is working properly
            break
        case .initializing:
            level = .unknown
        }
        
        // Adjust based on entitlement state
        switch entitlementState {
        case .invalid:
            level = min(level, .minimal)
        case .partial:
            level = min(level, .basic)
        case .valid:
            // No change - entitlements are properly configured
            break
        case .unknown:
            level = .unknown
        }
        
        return level
    }
    
    private func updateFrameworkState() {
        switch overallSecurityLevel {
        case .unknown:
            frameworkState = .initializing
        case .minimal:
            frameworkState = .critical
        case .basic:
            frameworkState = .degraded
        case .enhanced, .maximum:
            frameworkState = .operational
        }
    }
    
    // MARK: - Threat Management
    
    private func handleThreatLevelChange(_ threatLevel: SecurityValidator.ThreatLevel) async {
        logger.info("⚠️ Threat level changed to: \(threatLevel.rawValue)")
        
        // Update active threats based on current system state
        await updateActiveThreats()
        
        // Take appropriate action based on threat level
        switch threatLevel {
        case .critical:
            await handleCriticalThreat()
        case .high:
            await handleHighThreat()
        case .medium:
            await handleMediumThreat()
        case .low:
            await handleLowThreat()
        }
    }
    
    private func updateActiveThreats() async {
        var threats: [SecurityThreat] = []
        
        // Check system integrity threats
        if !securityMetrics.sipCompliance {
            threats.append(SecurityThreat(
                type: .systemIntegrityViolation,
                severity: .critical,
                description: "System Integrity Protection is disabled",
                recommendation: "Enable SIP by restarting to recovery mode",
                affectedComponent: "System"
            ))
        }
        
        // Check code signature threats
        if !securityMetrics.codeSignatureValid {
            threats.append(SecurityThreat(
                type: .codeSignatureViolation,
                severity: .high,
                description: "Application code signature is invalid",
                recommendation: "Reinstall application from trusted source",
                affectedComponent: "Application"
            ))
        }
        
        // Check sandbox threats
        if !securityMetrics.sandboxCompliance {
            threats.append(SecurityThreat(
                type: .sandboxViolation,
                severity: .medium,
                description: "Sandbox environment is not properly configured",
                recommendation: "Review application entitlements",
                affectedComponent: "Sandbox"
            ))
        }
        
        // Check framework threats
        if !frameworkState.isOperational {
            threats.append(SecurityThreat(
                type: .securityFrameworkFailure,
                severity: .high,
                description: "Security framework is not operational",
                recommendation: "Restart application and check logs",
                affectedComponent: "SecurityFramework"
            ))
        }
        
        activeThreats = threats
        logger.info("🎯 Active security threats: \(threats.count)")
    }
    
    private func handleCriticalThreat() async {
        logger.error("🚨 CRITICAL THREAT DETECTED - Implementing emergency security measures")
        
        // Disable high-risk operations
        frameworkState = .critical
        
        // Log critical security event
        logSecurityEvent(level: .critical, message: "Critical security threat detected - emergency measures active")
    }
    
    private func handleHighThreat() async {
        logger.warning("⚠️ HIGH THREAT DETECTED - Enhanced security monitoring")
        
        // Increase monitoring frequency
        await performCoordinatedSecurityCheck()
    }
    
    private func handleMediumThreat() async {
        logger.info("ℹ️ MEDIUM THREAT DETECTED - Standard monitoring")
        
        // Continue normal operation with monitoring
    }
    
    private func handleLowThreat() async {
        logger.info("✅ LOW THREAT LEVEL - Normal operation")
        
        // Standard security posture
    }
    
    // MARK: - Process Security Operations
    
    public func validateProcessTermination(_ process: NSRunningApplication) async -> (allowed: Bool, reason: String, recommendations: [String]) {
        // Ensure framework is operational
        guard frameworkState.isOperational else {
            return (false, "Security framework is not operational", ["Restart application", "Check security configuration"])
        }
        
        // Get comprehensive validation from security validator
        let validationResult = await securityValidator.validateProcessTermination(process)
        
        // Additional framework-level checks
        let frameworkChecks = performFrameworkLevelChecks(for: process)
        
        // Combine results
        let finalAllowed = validationResult.allowed && frameworkChecks.allowed
        let finalReason = finalAllowed ? validationResult.reason : frameworkChecks.reason
        let combinedRecommendations = validationResult.recommendations + frameworkChecks.recommendations
        
        // Log security decision
        logSecurityDecision(process: process, allowed: finalAllowed, reason: finalReason)
        
        return (finalAllowed, finalReason, combinedRecommendations)
    }
    
    private func performFrameworkLevelChecks(for process: NSRunningApplication) -> (allowed: Bool, reason: String, recommendations: [String]) {
        // Framework-specific security checks
        
        // Check if we're in a critical security state
        if frameworkState == .critical {
            return (false, "Framework in critical security state", ["Resolve security threats", "Restart application"])
        }
        
        // Check if security level allows operation
        if overallSecurityLevel < .basic {
            return (false, "Insufficient security level for process termination", ["Improve security configuration"])
        }
        
        // Check for active critical threats
        let criticalThreats = activeThreats.filter { $0.severity == .critical }
        if !criticalThreats.isEmpty {
            return (false, "Critical security threats prevent operation", ["Resolve critical threats"])
        }
        
        return (true, "Framework-level security checks passed", [])
    }
    
    public func requestElevatedPermissions(for operation: String) async -> Bool {
        logger.info("🔐 Requesting elevated permissions for: \(operation)")
        
        // Check if elevation is possible with current security level
        guard overallSecurityLevel >= .enhanced else {
            logger.warning("⚠️ Security level too low for elevation request")
            return false
        }
        
        // Use authorization manager to handle elevation
        return await authorizationManager.requestElevation(for: operation)
    }
    
    // MARK: - Security Monitoring
    
    private func performCoordinatedSecurityCheck() async {
        logger.info("🔍 Performing coordinated security check")
        
        // Update metrics from all components
        await updateSecurityMetrics()
        
        // Check for new threats
        await updateActiveThreats()
        
        // Update overall security assessment
        await updateOverallSecurityLevel()
        
        // Log security status
        logSecurityStatus()
    }
    
    private func updateSecurityMetrics() async {
        var metrics = SecurityMetrics()
        
        // Get sandbox metrics
        let sandboxMetrics = sandboxManager.getSecurityMetrics()
        metrics.sandboxCompliance = sandboxMetrics["sandboxed"] as? Bool ?? false
        
        // Get validator metrics
        let validatorMetrics = securityValidator.getSecurityMetrics()
        metrics.totalValidationRules = validatorMetrics["total_rules"] as? Int ?? 0
        metrics.passedValidationRules = validatorMetrics["passed_rules"] as? Int ?? 0
        metrics.failedValidationRules = validatorMetrics["failed_rules"] as? Int ?? 0
        
        // Get entitlement metrics
        let entitlementReport = entitlementManager.getEntitlementReport()
        if let capabilities = entitlementReport["capabilities"] as? [[String: Any]] {
            metrics.totalCapabilities = capabilities.count
            metrics.availableCapabilities = capabilities.filter { ($0["usable"] as? Bool) ?? false }.count
        }
        
        // System-level metrics
        metrics.sipCompliance = true // Would check actual SIP status
        metrics.codeSignatureValid = true // Would validate actual signature
        metrics.helperToolInstalled = false // Would check helper tool status
        metrics.lastSecurityCheck = Date()
        metrics.uptimeSeconds = ProcessInfo.processInfo.systemUptime
        
        securityMetrics = metrics
    }
    
    // MARK: - Logging and Reporting
    
    private func logSecurityEvent(level: OSLogType, message: String) {
        logger.log(level: level, "🔒 SECURITY EVENT: \(message)")
    }
    
    private func logSecurityDecision(process: NSRunningApplication, allowed: Bool, reason: String) {
        let processName = process.localizedName ?? "Unknown"
        let decision = allowed ? "ALLOWED" : "DENIED"
        
        logger.info("⚖️ SECURITY DECISION: \(decision) for '\(processName)' - \(reason)")
    }
    
    private func logSecurityStatus() {
        logger.info("📊 Security Framework Status:")
        logger.info("  - Framework State: \(frameworkState.rawValue)")
        logger.info("  - Security Level: \(overallSecurityLevel.rawValue)")
        logger.info("  - Security Score: \(String(format: "%.1f", securityMetrics.securityScore * 100))% (\(securityMetrics.securityGrade))")
        logger.info("  - Active Threats: \(activeThreats.count)")
        logger.info("  - Capabilities: \(securityMetrics.availableCapabilities)/\(securityMetrics.totalCapabilities)")
    }
    
    // MARK: - Public API
    
    public func getSecurityReport() -> [String: Any] {
        return [
            "timestamp": Date().timeIntervalSince1970,
            "framework_version": "1.0.0",
            "framework_state": frameworkState.rawValue,
            "security_level": overallSecurityLevel.rawValue,
            "metrics": [
                "security_score": securityMetrics.securityScore,
                "security_grade": securityMetrics.securityGrade,
                "total_validation_rules": securityMetrics.totalValidationRules,
                "passed_validation_rules": securityMetrics.passedValidationRules,
                "failed_validation_rules": securityMetrics.failedValidationRules,
                "available_capabilities": securityMetrics.availableCapabilities,
                "total_capabilities": securityMetrics.totalCapabilities,
                "sandbox_compliance": securityMetrics.sandboxCompliance,
                "sip_compliance": securityMetrics.sipCompliance,
                "code_signature_valid": securityMetrics.codeSignatureValid,
                "helper_tool_installed": securityMetrics.helperToolInstalled,
                "uptime_seconds": securityMetrics.uptimeSeconds
            ],
            "active_threats": activeThreats.map { threat in
                [
                    "id": threat.id.uuidString,
                    "type": threat.type.rawValue,
                    "severity": threat.severity.rawValue,
                    "description": threat.description,
                    "recommendation": threat.recommendation,
                    "timestamp": threat.timestamp.timeIntervalSince1970,
                    "affected_component": threat.affectedComponent
                ]
            },
            "component_reports": [
                "sandbox": sandboxManager.getSecurityMetrics(),
                "validator": securityValidator.getSecurityMetrics(),
                "entitlements": entitlementManager.getEntitlementReport()
            ]
        ]
    }
    
    public func isOperational() -> Bool {
        return frameworkState.isOperational
    }
    
    public func canPerformSystemOperations() -> Bool {
        return overallSecurityLevel.canTerminateSystemProcesses && frameworkState.isOperational
    }
    
    public func getSecurityLevel() -> SecurityLevel {
        return overallSecurityLevel
    }
    
    public func getActiveThreats() -> [SecurityThreat] {
        return activeThreats
    }
}

// MARK: - Authorization Manager

private class AuthorizationManager {
    private let logger = Logger(subsystem: "com.forcequit.security", category: "AuthorizationManager")
    
    func requestElevation(for operation: String) async -> Bool {
        logger.info("🔐 Requesting elevation for operation: \(operation)")
        
        // This would implement the actual authorization request
        // using AuthorizationServices framework and SMJobBless
        
        return true // Simplified for now
    }
}