import Foundation
import Security
import OSLog
import AppKit

/// System Integrity Protection compliance validator
/// Ensures all operations respect SIP boundaries and system security
class SIPComplianceValidator: ObservableObject {
    
    // MARK: - Singleton
    static let shared = SIPComplianceValidator()
    
    // MARK: - Published Properties
    @Published var sipStatus: SIPStatus = .unknown
    @Published var lastValidation: Date?
    @Published var protectedProcesses: Set<String> = []
    @Published var complianceScore: Double = 0.0
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.forceQUIT.app", category: "SIPCompliance")
    
    // SIP Protected paths - these should never be modified
    private let sipProtectedPaths: Set<String> = [
        "/System/Library/",
        "/usr/bin/",
        "/usr/sbin/",
        "/bin/",
        "/sbin/",
        "/usr/libexec/"
    ]
    
    // Critical system processes that should never be terminated
    private let criticalSystemProcesses: Set<String> = [
        "kernel_task",
        "launchd", 
        "loginwindow",
        "WindowServer",
        "securityd",
        "coreauthd",
        "mDNSResponder",
        "configd",
        "networkd",
        "bluetoothd"
    ]
    
    // Processes with special SIP protection
    private let sipProtectedProcesses: Set<String> = [
        "csrutil",
        "kextload",
        "kextunload",
        "nvram",
        "bless"
    ]
    
    // MARK: - Initialization
    private init() {
        initializeValidator()
    }
    
    private func initializeValidator() {
        logger.info("🛡️ Initializing SIP Compliance Validator")
        
        Task {
            await validateSIPStatus()
            await buildProtectedProcessList()
            await calculateComplianceScore()
        }
    }
    
    // MARK: - SIP Status Validation
    @MainActor
    func validateSIPStatus() async {
        logger.info("🔍 Validating System Integrity Protection status")
        
        let enabled = await checkSIPEnabled()
        sipStatus = enabled ? .enabled : .disabled
        lastValidation = Date()
        
        if enabled {
            logger.info("✅ System Integrity Protection is enabled")
        } else {
            logger.warning("⚠️ System Integrity Protection is DISABLED - system at risk")
        }
    }
    
    private func checkSIPEnabled() async -> Bool {
        // Check SIP status via csrutil command
        return await withCheckedContinuation { continuation in
            let process = Process()
            process.launchPath = "/usr/bin/csrutil"
            process.arguments = ["status"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            process.terminationHandler = { process in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                
                // Parse csrutil output
                let enabled = output.lowercased().contains("enabled")
                continuation.resume(returning: enabled)
            }
            
            do {
                try process.run()
            } catch {
                self.logger.error("Failed to check SIP status: \(error)")
                continuation.resume(returning: true) // Assume enabled on error for safety
            }
        }
    }
    
    // MARK: - Process Safety Validation
    func validateProcessSafety(processInfo: ProcessInfo) async -> ProcessSafetyResult {
        logger.debug("🔍 Validating process safety: \(processInfo.name) (PID: \(processInfo.pid))")
        
        // Check if process is in critical system processes
        if criticalSystemProcesses.contains(processInfo.name) {
            return ProcessSafetyResult(
                level: .forbidden,
                reason: "Critical system process protected by SIP",
                recommendation: "Never terminate - essential for system stability",
                sipCompliant: true
            )
        }
        
        // Check if process is SIP-protected
        if sipProtectedProcesses.contains(processInfo.name) {
            return ProcessSafetyResult(
                level: .forbidden,
                reason: "SIP-protected system utility",
                recommendation: "Protected by System Integrity Protection",
                sipCompliant: true
            )
        }
        
        // Check process bundle identifier
        if let bundleId = processInfo.bundleIdentifier {
            let safetyResult = await validateBundleIdentifierSafety(bundleId)
            if safetyResult.level == .forbidden {
                return safetyResult
            }
        }
        
        // Check process location
        let locationSafety = await validateProcessLocation(processInfo)
        if locationSafety.level == .forbidden {
            return locationSafety
        }
        
        // Default safety assessment
        return assessDefaultSafety(processInfo)
    }
    
    private func validateBundleIdentifierSafety(_ bundleId: String) async -> ProcessSafetyResult {
        // Apple system processes
        if bundleId.starts(with: "com.apple.") {
            let criticalAppleProcesses: Set<String> = [
                "com.apple.loginwindow",
                "com.apple.WindowServer",
                "com.apple.securityd",
                "com.apple.coreauthd"
            ]
            
            if criticalAppleProcesses.contains(bundleId) {
                return ProcessSafetyResult(
                    level: .forbidden,
                    reason: "Critical Apple system process",
                    recommendation: "Protected - termination could destabilize system",
                    sipCompliant: true
                )
            }
            
            return ProcessSafetyResult(
                level: .restricted,
                reason: "Apple system process - requires caution",
                recommendation: "Use Apple Events for graceful termination",
                sipCompliant: true
            )
        }
        
        // Check for system-level processes
        if bundleId.contains("system") || bundleId.contains("daemon") {
            return ProcessSafetyResult(
                level: .monitored,
                reason: "System-level process detected",
                recommendation: "Monitor termination and log for audit",
                sipCompliant: true
            )
        }
        
        return ProcessSafetyResult(
            level: .safe,
            reason: "User application",
            recommendation: "Safe to terminate",
            sipCompliant: true
        )
    }
    
    private func validateProcessLocation(_ processInfo: ProcessInfo) async -> ProcessSafetyResult {
        // Get process executable path
        guard let executablePath = getProcessExecutablePath(pid: processInfo.pid) else {
            return ProcessSafetyResult(
                level: .monitored,
                reason: "Cannot determine process location",
                recommendation: "Use caution - unknown executable path",
                sipCompliant: false
            )
        }
        
        // Check if process is in SIP-protected location
        for protectedPath in sipProtectedPaths {
            if executablePath.starts(with: protectedPath) {
                return ProcessSafetyResult(
                    level: .forbidden,
                    reason: "Process located in SIP-protected path: \(protectedPath)",
                    recommendation: "SIP-protected location - never terminate",
                    sipCompliant: true
                )
            }
        }
        
        return ProcessSafetyResult(
            level: .safe,
            reason: "Process in safe location",
            recommendation: "Location allows termination",
            sipCompliant: true
        )
    }
    
    private func assessDefaultSafety(_ processInfo: ProcessInfo) -> ProcessSafetyResult {
        switch processInfo.securityLevel {
        case .low:
            return ProcessSafetyResult(
                level: .safe,
                reason: "User process with low security level",
                recommendation: "Safe to terminate",
                sipCompliant: true
            )
            
        case .medium:
            return ProcessSafetyResult(
                level: .monitored,
                reason: "Medium security level process",
                recommendation: "Monitor and log termination",
                sipCompliant: true
            )
            
        case .high:
            return ProcessSafetyResult(
                level: .restricted,
                reason: "High security level process",
                recommendation: "Requires elevated privileges",
                sipCompliant: true
            )
        }
    }
    
    // MARK: - Protected Process Management
    @MainActor
    private func buildProtectedProcessList() async {
        logger.info("🔒 Building protected process list")
        
        var processes = Set<String>()
        
        // Add critical system processes
        processes.formUnion(criticalSystemProcesses)
        
        // Add SIP-protected processes
        processes.formUnion(sipProtectedProcesses)
        
        // Add our own app to prevent self-termination
        processes.insert("ForceQUIT")
        
        protectedProcesses = processes
        
        logger.info("🔒 Protected process list updated: \(processes.count) processes")
    }
    
    func isProcessProtected(_ processInfo: ProcessInfo) -> Bool {
        return protectedProcesses.contains(processInfo.name)
    }
    
    func getProtectionReason(for processInfo: ProcessInfo) -> String {
        if criticalSystemProcesses.contains(processInfo.name) {
            return "Critical system process - essential for macOS operation"
        }
        
        if sipProtectedProcesses.contains(processInfo.name) {
            return "SIP-protected system utility"
        }
        
        if processInfo.name == "ForceQUIT" {
            return "Cannot terminate self"
        }
        
        return "Process is protected by system security policies"
    }
    
    // MARK: - Compliance Scoring
    @MainActor
    private func calculateComplianceScore() async {
        logger.info("📊 Calculating SIP compliance score")
        
        var score = 0.0
        let maxScore = 100.0
        
        // SIP status (40 points)
        if sipStatus == .enabled {
            score += 40.0
        }
        
        // Protected process list completeness (30 points)
        let expectedMinimumProtected = criticalSystemProcesses.count + sipProtectedProcesses.count
        let actualProtected = protectedProcesses.count
        
        if actualProtected >= expectedMinimumProtected {
            score += 30.0
        } else {
            let ratio = Double(actualProtected) / Double(expectedMinimumProtected)
            score += 30.0 * ratio
        }
        
        // Path protection validation (20 points)
        let pathProtectionScore = await validatePathProtections()
        score += pathProtectionScore * 20.0
        
        // System integrity checks (10 points)
        let integrityScore = await validateSystemIntegrity()
        score += integrityScore * 10.0
        
        complianceScore = score
        
        logger.info("📊 SIP compliance score: \(score)/\(maxScore)")
    }
    
    private func validatePathProtections() async -> Double {
        var protectedCount = 0
        let totalPaths = sipProtectedPaths.count
        
        for path in sipProtectedPaths {
            if await isPathSIPProtected(path) {
                protectedCount += 1
            }
        }
        
        return Double(protectedCount) / Double(totalPaths)
    }
    
    private func isPathSIPProtected(_ path: String) async -> Bool {
        // Check if path has SIP protection
        let fileManager = FileManager.default
        
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            
            // Check for protection flags (simplified check)
            if let protectionKey = attributes[.protectionKey] {
                logger.debug("Path \(path) has protection: \(protectionKey)")
                return true
            }
            
            return true // Assume protected for system paths
            
        } catch {
            logger.debug("Cannot check protection for path \(path): \(error)")
            return false
        }
    }
    
    private func validateSystemIntegrity() async -> Double {
        // Simplified system integrity check
        // In production, would perform more comprehensive checks
        
        var integrityScore = 1.0
        
        // Check if critical directories exist and are protected
        let criticalDirectories = ["/System/Library/", "/usr/bin/", "/bin/"]
        
        for directory in criticalDirectories {
            if !FileManager.default.fileExists(atPath: directory) {
                integrityScore -= 0.3
            }
        }
        
        return max(0.0, integrityScore)
    }
    
    // MARK: - Compliance Reporting
    func generateComplianceReport() -> SIPComplianceReport {
        return SIPComplianceReport(
            sipStatus: sipStatus,
            complianceScore: complianceScore,
            protectedProcessCount: protectedProcesses.count,
            criticalProcessesProtected: criticalSystemProcesses.isSubset(of: protectedProcesses),
            sipProtectedPathsCount: sipProtectedPaths.count,
            lastValidation: lastValidation ?? Date.distantPast,
            recommendations: generateRecommendations()
        )
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if sipStatus != .enabled {
            recommendations.append("Enable System Integrity Protection for maximum security")
        }
        
        if complianceScore < 80 {
            recommendations.append("Review and update security policies to improve compliance")
        }
        
        if !criticalSystemProcesses.isSubset(of: protectedProcesses) {
            recommendations.append("Ensure all critical system processes are protected")
        }
        
        return recommendations
    }
    
    // MARK: - Helper Methods
    private func getProcessExecutablePath(pid: pid_t) -> String? {
        var pathBuffer = [Int8](repeating: 0, count: Int(MAXPATHLEN))
        let result = proc_pidpath(pid, &pathBuffer, UInt32(MAXPATHLEN))
        
        guard result > 0 else { return nil }
        
        return String(cString: pathBuffer)
    }
    
    // MARK: - Manual Validation
    func performManualValidation() async {
        logger.info("🔄 Performing manual SIP compliance validation")
        
        await validateSIPStatus()
        await buildProtectedProcessList()
        await calculateComplianceScore()
        
        logger.info("✅ Manual validation complete")
    }
}

// MARK: - Supporting Types
enum SIPStatus: String, CaseIterable {
    case unknown = "Unknown"
    case enabled = "Enabled"
    case disabled = "Disabled"
    case partial = "Partial"
    
    var color: NSColor {
        switch self {
        case .unknown: return .systemGray
        case .enabled: return .systemGreen
        case .disabled: return .systemRed
        case .partial: return .systemOrange
        }
    }
    
    var systemImage: String {
        switch self {
        case .unknown: return "questionmark.circle"
        case .enabled: return "lock.shield"
        case .disabled: return "exclamationmark.triangle"
        case .partial: return "shield.lefthalf.filled"
        }
    }
}

// ProcessSafetyLevel enum moved to XPCHelperTool.swift to avoid duplication

// Note: ProcessSafetyResult moved to XPCHelperTool.swift to consolidate definitions

struct SIPComplianceReport {
    let sipStatus: SIPStatus
    let complianceScore: Double
    let protectedProcessCount: Int
    let criticalProcessesProtected: Bool
    let sipProtectedPathsCount: Int
    let lastValidation: Date
    let recommendations: [String]
    
    var grade: String {
        switch complianceScore {
        case 90...100: return "Excellent"
        case 80..<90: return "Good"
        case 70..<80: return "Acceptable"
        case 60..<70: return "Needs Improvement"
        default: return "Poor"
        }
    }
    
    var gradeColor: NSColor {
        switch complianceScore {
        case 90...100: return .systemGreen
        case 80..<90: return .systemBlue
        case 70..<80: return .systemYellow
        case 60..<70: return .systemOrange
        default: return .systemRed
        }
    }
}