import Foundation
import AppKit
import os.log

/// SWARM 2.0 ForceQUIT - Intelligent Process Terminator
/// Advanced process termination system with smart kill strategies
/// Implements graceful -> forceful escalation with safety checks

class ProcessTerminator: ObservableObject {
    // MARK: - Properties
    @Published private(set) var terminationHistory: [TerminationRecord] = []
    @Published private(set) var activeTerminations: Set<pid_t> = []
    
    private let terminationQueue = DispatchQueue(label: "com.forcequit.terminator", qos: .userInitiated)
    private let logger = Logger(subsystem: "com.forcequit.app", category: "ProcessTerminator")
    
    // Termination strategy configuration
    private let gracefulTerminationTimeout: TimeInterval = 10.0
    private let forcefulTerminationTimeout: TimeInterval = 5.0
    private let maxConcurrentTerminations = 5
    
    // MARK: - Public Interface
    
    /// Terminate a single process using intelligent strategy selection
    func terminateProcess(_ processInfo: ProcessInfo, strategy: TerminationStrategy = .auto) async -> TerminationResult {
        logger.info("Initiating termination for process: \(processInfo.name, privacy: .public) (PID: \(processInfo.pid))")
        
        // Check if already terminating
        guard !activeTerminations.contains(processInfo.pid) else {
            return TerminationResult(
                processInfo: processInfo,
                strategy: strategy,
                success: false,
                error: .alreadyTerminating,
                duration: 0,
                attempts: []
            )
        }
        
        // Check termination limits
        guard activeTerminations.count < maxConcurrentTerminations else {
            return TerminationResult(
                processInfo: processInfo,
                strategy: strategy,
                success: false,
                error: .concurrencyLimitReached,
                duration: 0,
                attempts: []
            )
        }
        
        // Perform safety checks
        let safetyCheck = performSafetyChecks(for: processInfo)
        guard safetyCheck.isSafe else {
            return TerminationResult(
                processInfo: processInfo,
                strategy: strategy,
                success: false,
                error: .safetyCheckFailed(reason: safetyCheck.reason),
                duration: 0,
                attempts: []
            )
        }
        
        // Mark as active termination
        await MainActor.run {
            activeTerminations.insert(processInfo.pid)
        }
        
        defer {
            Task { @MainActor in
                activeTerminations.remove(processInfo.pid)
            }
        }
        
        let startTime = Date()
        var attempts: [TerminationAttempt] = []
        
        // Determine optimal strategy
        let actualStrategy = strategy == .auto ? determineOptimalStrategy(for: processInfo) : strategy
        
        let result: TerminationResult
        
        switch actualStrategy {
        case .graceful:
            result = await performGracefulTermination(processInfo: processInfo, attempts: &attempts)
        case .forceful:
            result = await performForcefulTermination(processInfo: processInfo, attempts: &attempts)
        case .escalating:
            result = await performEscalatingTermination(processInfo: processInfo, attempts: &attempts)
        case .restart:
            result = await performRestartTermination(processInfo: processInfo, attempts: &attempts)
        case .auto:
            result = await performEscalatingTermination(processInfo: processInfo, attempts: &attempts)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let finalResult = TerminationResult(
            processInfo: processInfo,
            strategy: actualStrategy,
            success: result.success,
            error: result.error,
            duration: duration,
            attempts: attempts
        )
        
        // Record termination
        let record = TerminationRecord(result: finalResult, timestamp: Date())
        await MainActor.run {
            terminationHistory.append(record)
            
            // Limit history size
            if terminationHistory.count > 1000 {
                terminationHistory.removeFirst(terminationHistory.count - 1000)
            }
        }
        
        logger.info("Termination completed for \(processInfo.name, privacy: .public): \(result.success ? "SUCCESS" : "FAILED") in \(duration, privacy: .public)s")
        
        return finalResult
    }
    
    /// Terminate multiple processes with intelligent batching
    func terminateProcesses(_ processes: [ProcessInfo], strategy: TerminationStrategy = .auto) async -> [TerminationResult] {
        logger.info("Initiating batch termination for \(processes.count) processes")
        
        // Sort by priority (safer processes first)
        let sortedProcesses = processes.sorted { lhs, rhs in
            if lhs.securityLevel != rhs.securityLevel {
                return lhs.securityLevel.rawValue < rhs.securityLevel.rawValue
            }
            return lhs.systemImpactScore < rhs.systemImpactScore
        }
        
        var results: [TerminationResult] = []
        
        // Process in batches to respect concurrency limits
        for batch in sortedProcesses.chunked(into: maxConcurrentTerminations) {
            let batchResults = await withTaskGroup(of: TerminationResult.self) { group in
                for process in batch {
                    group.addTask {
                        await self.terminateProcess(process, strategy: strategy)
                    }
                }
                
                var batchResults: [TerminationResult] = []
                for await result in group {
                    batchResults.append(result)
                }
                return batchResults
            }
            
            results.append(contentsOf: batchResults)
            
            // Brief pause between batches for system stability
            if batch.count == maxConcurrentTerminations {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }
        
        logger.info("Batch termination completed: \(results.filter(\.success).count)/\(results.count) successful")
        
        return results
    }
    
    /// Emergency force quit - bypass all safety checks
    func emergencyForceQuit(_ processInfo: ProcessInfo) async -> TerminationResult {
        logger.warning("EMERGENCY FORCE QUIT initiated for \(processInfo.name, privacy: .public)")
        
        let startTime = Date()
        var attempts: [TerminationAttempt] = []
        
        let attempt = TerminationAttempt(
            method: .kill9,
            timestamp: Date(),
            success: false,
            error: nil
        )
        
        let success = killProcess(processInfo.pid, signal: SIGKILL)
        let updatedAttempt = TerminationAttempt(
            method: .kill9,
            timestamp: attempt.timestamp,
            success: success,
            error: success ? nil : .signalFailed
        )
        
        attempts.append(updatedAttempt)
        
        return TerminationResult(
            processInfo: processInfo,
            strategy: .forceful,
            success: success,
            error: success ? nil : .signalFailed,
            duration: Date().timeIntervalSince(startTime),
            attempts: attempts
        )
    }
    
    // MARK: - Private Implementation
    
    private func determineOptimalStrategy(for processInfo: ProcessInfo) -> TerminationStrategy {
        // System processes require careful handling
        if processInfo.securityLevel == .high {
            return .graceful
        }
        
        // Restartable applications can use restart strategy
        if processInfo.canSafelyRestart {
            return .restart
        }
        
        // High-impact processes get escalating treatment
        if processInfo.systemImpactScore > 0.7 {
            return .escalating
        }
        
        // Default to graceful for user applications
        return processInfo.securityLevel == .low ? .graceful : .escalating
    }
    
    private func performSafetyChecks(for processInfo: ProcessInfo) -> SafetyCheckResult {
        // Check for critical system processes
        let criticalProcesses = [
            "kernel_task", "launchd", "WindowServer", "loginwindow",
            "SystemUIServer", "Dock", "Finder", "Activity Monitor"
        ]
        
        if criticalProcesses.contains(processInfo.name) {
            return SafetyCheckResult(isSafe: false, reason: "Critical system process")
        }
        
        // Check for security software
        let securityBundleIds = [
            "com.apple.SecurityAgent",
            "com.apple.AuthenticationServices",
            "com.apple.securityd"
        ]
        
        if let bundleId = processInfo.bundleIdentifier,
           securityBundleIds.contains(bundleId) {
            return SafetyCheckResult(isSafe: false, reason: "Security system process")
        }
        
        // Check for SIP protection (simplified check)
        if processInfo.securityLevel == .high && processInfo.pid < 100 {
            return SafetyCheckResult(isSafe: false, reason: "System Integrity Protection")
        }
        
        return SafetyCheckResult(isSafe: true, reason: nil)
    }
    
    private func performGracefulTermination(processInfo: ProcessInfo, attempts: inout [TerminationAttempt]) async -> TerminationResult {
        // Try NSRunningApplication terminate first (most graceful)
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == processInfo.pid }) {
            let attempt = TerminationAttempt(method: .nsApplicationTerminate, timestamp: Date(), success: false, error: nil)
            let success = app.terminate()
            
            let updatedAttempt = TerminationAttempt(
                method: .nsApplicationTerminate,
                timestamp: attempt.timestamp,
                success: success,
                error: success ? nil : .nsApplicationFailed
            )
            attempts.append(updatedAttempt)
            
            if success {
                // Wait for graceful termination
                let terminated = await waitForProcessTermination(pid: processInfo.pid, timeout: gracefulTerminationTimeout)
                if terminated {
                    return TerminationResult(processInfo: processInfo, strategy: .graceful, success: true, error: nil, duration: 0, attempts: attempts)
                }
            }
        }
        
        // Fall back to SIGTERM
        let termAttempt = TerminationAttempt(method: .sigterm, timestamp: Date(), success: false, error: nil)
        let termSuccess = killProcess(processInfo.pid, signal: SIGTERM)
        
        let updatedTermAttempt = TerminationAttempt(
            method: .sigterm,
            timestamp: termAttempt.timestamp,
            success: termSuccess,
            error: termSuccess ? nil : .signalFailed
        )
        attempts.append(updatedTermAttempt)
        
        if termSuccess {
            let terminated = await waitForProcessTermination(pid: processInfo.pid, timeout: gracefulTerminationTimeout)
            if terminated {
                return TerminationResult(processInfo: processInfo, strategy: .graceful, success: true, error: nil, duration: 0, attempts: attempts)
            }
        }
        
        return TerminationResult(processInfo: processInfo, strategy: .graceful, success: false, error: .gracefulTerminationFailed, duration: 0, attempts: attempts)
    }
    
    private func performForcefulTermination(processInfo: ProcessInfo, attempts: inout [TerminationAttempt]) async -> TerminationResult {
        // Force terminate with NSRunningApplication
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == processInfo.pid }) {
            let attempt = TerminationAttempt(method: .nsApplicationForceTerminate, timestamp: Date(), success: false, error: nil)
            let success = app.forceTerminate()
            
            let updatedAttempt = TerminationAttempt(
                method: .nsApplicationForceTerminate,
                timestamp: attempt.timestamp,
                success: success,
                error: success ? nil : .nsApplicationFailed
            )
            attempts.append(updatedAttempt)
            
            if success {
                let terminated = await waitForProcessTermination(pid: processInfo.pid, timeout: forcefulTerminationTimeout)
                if terminated {
                    return TerminationResult(processInfo: processInfo, strategy: .forceful, success: true, error: nil, duration: 0, attempts: attempts)
                }
            }
        }
        
        // Fall back to SIGKILL
        let killAttempt = TerminationAttempt(method: .kill9, timestamp: Date(), success: false, error: nil)
        let killSuccess = killProcess(processInfo.pid, signal: SIGKILL)
        
        let updatedKillAttempt = TerminationAttempt(
            method: .kill9,
            timestamp: killAttempt.timestamp,
            success: killSuccess,
            error: killSuccess ? nil : .signalFailed
        )
        attempts.append(updatedKillAttempt)
        
        if killSuccess {
            let terminated = await waitForProcessTermination(pid: processInfo.pid, timeout: forcefulTerminationTimeout)
            return TerminationResult(processInfo: processInfo, strategy: .forceful, success: terminated, error: terminated ? nil : .processStillRunning, duration: 0, attempts: attempts)
        }
        
        return TerminationResult(processInfo: processInfo, strategy: .forceful, success: false, error: .signalFailed, duration: 0, attempts: attempts)
    }
    
    private func performEscalatingTermination(processInfo: ProcessInfo, attempts: inout [TerminationAttempt]) async -> TerminationResult {
        // Try graceful first
        let gracefulResult = await performGracefulTermination(processInfo: processInfo, attempts: &attempts)
        if gracefulResult.success {
            return gracefulResult
        }
        
        // Escalate to forceful
        logger.info("Escalating to forceful termination for \(processInfo.name, privacy: .public)")
        let forcefulResult = await performForcefulTermination(processInfo: processInfo, attempts: &attempts)
        
        return TerminationResult(
            processInfo: processInfo,
            strategy: .escalating,
            success: forcefulResult.success,
            error: forcefulResult.error,
            duration: 0,
            attempts: attempts
        )
    }
    
    private func performRestartTermination(processInfo: ProcessInfo, attempts: inout [TerminationAttempt]) async -> TerminationResult {
        guard let bundleId = processInfo.bundleIdentifier else {
            return await performEscalatingTermination(processInfo: processInfo, attempts: &attempts)
        }
        
        // Store app path for restart
        let appPath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)
        
        // Terminate the process
        let terminationResult = await performEscalatingTermination(processInfo: processInfo, attempts: &attempts)
        
        guard terminationResult.success else {
            return terminationResult
        }
        
        // Wait a moment before restart
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Restart the application
        let restartAttempt = TerminationAttempt(method: .restart, timestamp: Date(), success: false, error: nil)
        
        var restartSuccess = false
        if let appPath = appPath {
            do {
                _ = try NSWorkspace.shared.launchApplication(at: appPath, configuration: NSWorkspace.OpenConfiguration())
                restartSuccess = true
            } catch {
                logger.error("Failed to restart application: \(error.localizedDescription, privacy: .public)")
            }
        }
        
        let updatedRestartAttempt = TerminationAttempt(
            method: .restart,
            timestamp: restartAttempt.timestamp,
            success: restartSuccess,
            error: restartSuccess ? nil : .restartFailed
        )
        attempts.append(updatedRestartAttempt)
        
        return TerminationResult(
            processInfo: processInfo,
            strategy: .restart,
            success: terminationResult.success && restartSuccess,
            error: restartSuccess ? nil : .restartFailed,
            duration: 0,
            attempts: attempts
        )
    }
    
    private func killProcess(_ pid: pid_t, signal: Int32) -> Bool {
        let result = kill(pid, signal)
        return result == 0
    }
    
    private func waitForProcessTermination(pid: pid_t, timeout: TimeInterval) async -> Bool {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            // Check if process still exists
            if kill(pid, 0) != 0 {
                return true // Process terminated
            }
            
            // Wait a brief moment before checking again
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        return false // Timeout reached
    }
}

// MARK: - Supporting Types

enum TerminationStrategy: String, CaseIterable {
    case auto = "Auto"
    case graceful = "Graceful"
    case forceful = "Forceful"
    case escalating = "Escalating"
    case restart = "Restart"
    
    var description: String {
        switch self {
        case .auto:
            return "Automatically select optimal strategy"
        case .graceful:
            return "Gentle termination allowing cleanup"
        case .forceful:
            return "Immediate termination"
        case .escalating:
            return "Graceful → Forceful escalation"
        case .restart:
            return "Terminate and restart application"
        }
    }
    
    var systemImage: String {
        switch self {
        case .auto: return "wand.and.rays"
        case .graceful: return "hand.raised"
        case .forceful: return "bolt"
        case .escalating: return "arrow.up.circle"
        case .restart: return "arrow.clockwise"
        }
    }
}

enum TerminationMethod: String {
    case nsApplicationTerminate = "NSApplication.terminate"
    case nsApplicationForceTerminate = "NSApplication.forceTerminate"
    case sigterm = "SIGTERM"
    case sigkill = "SIGKILL"
    case kill9 = "kill -9"
    case restart = "Restart"
}

enum TerminationError: Error, LocalizedError {
    case alreadyTerminating
    case concurrencyLimitReached
    case safetyCheckFailed(reason: String)
    case nsApplicationFailed
    case signalFailed
    case gracefulTerminationFailed
    case processStillRunning
    case restartFailed
    
    var errorDescription: String? {
        switch self {
        case .alreadyTerminating:
            return "Process is already being terminated"
        case .concurrencyLimitReached:
            return "Maximum concurrent terminations reached"
        case .safetyCheckFailed(let reason):
            return "Safety check failed: \(reason)"
        case .nsApplicationFailed:
            return "NSApplication termination failed"
        case .signalFailed:
            return "Signal delivery failed"
        case .gracefulTerminationFailed:
            return "Graceful termination failed"
        case .processStillRunning:
            return "Process is still running after termination attempt"
        case .restartFailed:
            return "Failed to restart application"
        }
    }
}

struct TerminationAttempt {
    let method: TerminationMethod
    let timestamp: Date
    let success: Bool
    let error: TerminationError?
}

struct TerminationResult {
    let processInfo: ProcessInfo
    let strategy: TerminationStrategy
    let success: Bool
    let error: TerminationError?
    let duration: TimeInterval
    let attempts: [TerminationAttempt]
}

struct TerminationRecord {
    let result: TerminationResult
    let timestamp: Date
    
    var wasSuccessful: Bool { result.success }
    var strategy: TerminationStrategy { result.strategy }
    var processName: String { result.processInfo.name }
}

struct SafetyCheckResult {
    let isSafe: Bool
    let reason: String?
}

// MARK: - Array Extensions
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}