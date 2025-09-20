import Foundation
import OSLog
import CrashReporter

// MARK: - Crash Reporter
class CrashReporter: ObservableObject {
    static let shared = CrashReporter()
    
    private let logger = Logger(subsystem: "com.forcequit.crash", category: "CrashReporter")
    private var crashReporter: PLCrashReporter?
    
    @Published var isEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "CrashReportingEnabled")
            configureCrashReporter()
        }
    }
    
    private init() {
        loadConfiguration()
        configureCrashReporter()
        setupCrashHandler()
    }
    
    private func loadConfiguration() {
        isEnabled = UserDefaults.standard.bool(forKey: "CrashReportingEnabled")
    }
    
    private func configureCrashReporter() {
        guard isEnabled else {
            crashReporter = nil
            return
        }
        
        let config = PLCrashReporterConfig.defaultConfiguration()
        crashReporter = PLCrashReporter(configuration: config)
        
        do {
            try crashReporter?.enable()
            logger.info("Crash reporter enabled successfully")
        } catch {
            logger.error("Failed to enable crash reporter: \(error)")
        }
    }
    
    private func setupCrashHandler() {
        // Set up custom crash handler
        signal(SIGABRT) { signal in
            CrashReporter.shared.handleCrash(signal: signal, context: "SIGABRT")
        }
        
        signal(SIGSEGV) { signal in
            CrashReporter.shared.handleCrash(signal: signal, context: "SIGSEGV")
        }
        
        signal(SIGBUS) { signal in
            CrashReporter.shared.handleCrash(signal: signal, context: "SIGBUS")
        }
        
        signal(SIGFPE) { signal in
            CrashReporter.shared.handleCrash(signal: signal, context: "SIGFPE")
        }
    }
    
    private func handleCrash(signal: Int32, context: String) {
        guard isEnabled else { return }
        
        let crashInfo: [String: Any] = [
            "signal": signal,
            "context": context,
            "timestamp": Date().timeIntervalSince1970,
            "process_id": ProcessInfo.processInfo.processIdentifier,
            "thread_id": pthread_self(),
            "app_version": Bundle.main.appVersion,
            "os_version": ProcessInfo.processInfo.operatingSystemVersionString
        ]
        
        // Collect additional diagnostic information
        let diagnosticInfo = collectDiagnosticInfo()
        
        // Create comprehensive crash report
        let report = createCrashReport(crashInfo: crashInfo, diagnostics: diagnosticInfo)
        
        // Save crash report locally
        saveCrashReport(report)
        
        // Track crash with analytics
        AnalyticsManager.shared.trackCrash(crashInfo)
        
        logger.critical("Crash detected and reported: \(context)")
    }
}

// MARK: - Diagnostic Information Collection
extension CrashReporter {
    private func collectDiagnosticInfo() -> [String: Any] {
        var diagnostics: [String: Any] = [:]
        
        // System Information
        diagnostics["system_info"] = [
            "os_version": ProcessInfo.processInfo.operatingSystemVersionString,
            "processor_count": ProcessInfo.processInfo.processorCount,
            "active_processor_count": ProcessInfo.processInfo.activeProcessorCount,
            "physical_memory": ProcessInfo.processInfo.physicalMemory,
            "thermal_state": ProcessInfo.processInfo.thermalState.rawValue
        ]
        
        // App State Information
        diagnostics["app_state"] = [
            "launch_time": AppDelegate.shared?.launchTime?.timeIntervalSince1970 ?? 0,
            "active_windows": NSApplication.shared.windows.count,
            "is_active": NSApplication.shared.isActive,
            "is_hidden": NSApplication.shared.isHidden
        ]
        
        // Memory Information
        diagnostics["memory_info"] = collectMemoryInfo()
        
        // Process Information
        diagnostics["process_info"] = collectProcessInfo()
        
        // User Activity
        diagnostics["user_activity"] = [
            "last_user_interaction": Date().timeIntervalSince1970,
            "session_duration": Date().timeIntervalSince(AnalyticsManager.shared.sessionStartTime ?? Date())
        ]
        
        return diagnostics
    }
    
    private func collectMemoryInfo() -> [String: Any] {
        let task = mach_task_self_
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(task, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard kerr == KERN_SUCCESS else {
            return ["error": "Failed to collect memory info"]
        }
        
        return [
            "virtual_size": info.virtual_size,
            "resident_size": info.resident_size,
            "maximum_resident_size": info.resident_size_max,
            "suspend_count": info.suspend_count
        ]
    }
    
    private func collectProcessInfo() -> [String: Any] {
        return [
            "process_id": ProcessInfo.processInfo.processIdentifier,
            "parent_process_id": getppid(),
            "process_name": ProcessInfo.processInfo.processName,
            "arguments": ProcessInfo.processInfo.arguments,
            "environment_count": ProcessInfo.processInfo.environment.count,
            "uptime": ProcessInfo.processInfo.systemUptime
        ]
    }
}

// MARK: - Crash Report Creation and Storage
extension CrashReporter {
    private func createCrashReport(crashInfo: [String: Any], diagnostics: [String: Any]) -> CrashReport {
        // Collect recent analytics events for context
        let recentEvents = AnalyticsManager.shared.getRecentEvents(limit: 50)
        
        // Create stack trace if available
        let stackTrace = captureStackTrace()
        
        var fullCrashInfo = crashInfo
        fullCrashInfo["diagnostics"] = diagnostics
        fullCrashInfo["stack_trace"] = stackTrace
        fullCrashInfo["thread_info"] = collectThreadInfo()
        
        return CrashReport(
            sessionId: AnalyticsManager.shared.sessionId,
            userId: AnalyticsManager.shared.userId,
            timestamp: Date(),
            appVersion: Bundle.main.appVersion,
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            crashInfo: fullCrashInfo,
            recentEvents: recentEvents
        )
    }
    
    private func captureStackTrace() -> [String] {
        let stackTrace = Thread.callStackSymbols
        return stackTrace.map { symbol in
            // Clean up stack trace symbols for better readability
            return symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    private func collectThreadInfo() -> [String: Any] {
        return [
            "main_thread": Thread.isMainThread,
            "thread_count": Thread.activeCount(),
            "current_thread": Thread.current.description,
            "thread_priority": Thread.threadPriority()
        ]
    }
    
    private func saveCrashReport(_ report: CrashReport) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let crashReportsPath = documentsPath.appendingPathComponent("ForceQUIT_CrashReports")
        
        do {
            try FileManager.default.createDirectory(at: crashReportsPath, withIntermediateDirectories: true)
            
            let fileName = "crash_\(report.timestamp.timeIntervalSince1970).json"
            let fileURL = crashReportsPath.appendingPathComponent(fileName)
            
            let jsonData = try JSONEncoder().encode(report)
            try jsonData.write(to: fileURL)
            
            logger.info("Crash report saved: \(fileName)")
        } catch {
            logger.error("Failed to save crash report: \(error)")
        }
    }
    
    func getPendingCrashReports() -> [CrashReport] {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let crashReportsPath = documentsPath.appendingPathComponent("ForceQUIT_CrashReports")
        
        guard FileManager.default.fileExists(atPath: crashReportsPath.path) else {
            return []
        }
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: crashReportsPath,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            var reports: [CrashReport] = []
            
            for fileURL in fileURLs {
                guard fileURL.pathExtension == "json" else { continue }
                
                do {
                    let data = try Data(contentsOf: fileURL)
                    let report = try JSONDecoder().decode(CrashReport.self, from: data)
                    reports.append(report)
                } catch {
                    logger.error("Failed to decode crash report: \(fileURL.lastPathComponent) - \(error)")
                }
            }
            
            return reports.sorted { $0.timestamp > $1.timestamp }
        } catch {
            logger.error("Failed to read crash reports directory: \(error)")
            return []
        }
    }
    
    func deleteCrashReport(_ report: CrashReport) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let crashReportsPath = documentsPath.appendingPathComponent("ForceQUIT_CrashReports")
        let fileName = "crash_\(report.timestamp.timeIntervalSince1970).json"
        let fileURL = crashReportsPath.appendingPathComponent(fileName)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            logger.info("Deleted crash report: \(fileName)")
        } catch {
            logger.error("Failed to delete crash report: \(error)")
        }
    }
}

// MARK: - Crash Report View Model
class CrashReportViewModel: ObservableObject {
    @Published var crashReports: [CrashReport] = []
    @Published var isLoading = false
    
    init() {
        loadCrashReports()
    }
    
    func loadCrashReports() {
        isLoading = true
        crashReports = CrashReporter.shared.getPendingCrashReports()
        isLoading = false
    }
    
    func deleteCrashReport(_ report: CrashReport) {
        CrashReporter.shared.deleteCrashReport(report)
        loadCrashReports()
    }
    
    func exportCrashReports() -> URL? {
        guard !crashReports.isEmpty else { return nil }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let exportURL = documentsPath.appendingPathComponent("crash_reports_export.json")
        
        do {
            let exportData = [
                "export_timestamp": Date().timeIntervalSince1970,
                "app_version": Bundle.main.appVersion,
                "crash_reports": crashReports.map { report in
                    [
                        "session_id": report.sessionId,
                        "timestamp": report.timestamp.timeIntervalSince1970,
                        "app_version": report.appVersion,
                        "os_version": report.osVersion,
                        "crash_info": report.crashInfo,
                        "recent_events_count": report.recentEvents.count
                    ]
                }
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            try jsonData.write(to: exportURL)
            
            return exportURL
        } catch {
            print("Failed to export crash reports: \(error)")
            return nil
        }
    }
}

// MARK: - Error Recovery System
class ErrorRecoverySystem {
    static let shared = ErrorRecoverySystem()
    
    private let logger = Logger(subsystem: "com.forcequit.recovery", category: "ErrorRecovery")
    private var recoveryStrategies: [String: RecoveryStrategy] = [:]
    
    private init() {
        setupRecoveryStrategies()
    }
    
    private func setupRecoveryStrategies() {
        recoveryStrategies = [
            "memory_pressure": MemoryPressureRecovery(),
            "process_access_denied": ProcessAccessRecovery(),
            "ui_freeze": UIFreezeRecovery(),
            "network_timeout": NetworkTimeoutRecovery()
        ]
    }
    
    func attemptRecovery(from error: Error, context: String) -> Bool {
        let errorKey = identifyErrorType(error)
        
        guard let strategy = recoveryStrategies[errorKey] else {
            logger.warning("No recovery strategy found for error: \(errorKey)")
            return false
        }
        
        logger.info("Attempting recovery for error: \(errorKey)")
        
        do {
            let success = try strategy.attemptRecovery(from: error, context: context)
            
            if success {
                logger.info("Recovery successful for error: \(errorKey)")
                
                // Track successful recovery
                AnalyticsManager.shared.trackEvent(.systemError, properties: [
                    "error_type": errorKey,
                    "recovery_successful": true,
                    "context": context
                ])
            } else {
                logger.warning("Recovery failed for error: \(errorKey)")
            }
            
            return success
        } catch {
            logger.error("Recovery attempt failed with exception: \(error)")
            return false
        }
    }
    
    private func identifyErrorType(_ error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.domain {
        case NSPOSIXErrorDomain:
            if nsError.code == EACCES {
                return "process_access_denied"
            }
        case NSCocoaErrorDomain:
            if nsError.code == NSFileReadNoPermissionError {
                return "file_permission_denied"
            }
        default:
            break
        }
        
        // Check error description for patterns
        let description = error.localizedDescription.lowercased()
        if description.contains("memory") || description.contains("allocation") {
            return "memory_pressure"
        } else if description.contains("timeout") || description.contains("network") {
            return "network_timeout"
        } else if description.contains("ui") || description.contains("freeze") {
            return "ui_freeze"
        }
        
        return "unknown"
    }
}

// MARK: - Recovery Strategy Protocol
protocol RecoveryStrategy {
    func attemptRecovery(from error: Error, context: String) throws -> Bool
}

// MARK: - Specific Recovery Strategies
struct MemoryPressureRecovery: RecoveryStrategy {
    func attemptRecovery(from error: Error, context: String) throws -> Bool {
        // Clear caches and free up memory
        URLCache.shared.removeAllCachedResponses()
        
        // Force garbage collection
        autoreleasepool {
            // Perform cleanup operations
        }
        
        return true
    }
}

struct ProcessAccessRecovery: RecoveryStrategy {
    func attemptRecovery(from error: Error, context: String) throws -> Bool {
        // Attempt to elevate privileges or request permission
        // This is a placeholder - actual implementation would depend on specific requirements
        return false
    }
}

struct UIFreezeRecovery: RecoveryStrategy {
    func attemptRecovery(from error: Error, context: String) throws -> Bool {
        // Dispatch UI updates to main queue and attempt to unfreeze
        DispatchQueue.main.async {
            // Force UI refresh
            NSApplication.shared.windows.forEach { window in
                window.contentView?.needsDisplay = true
            }
        }
        
        return true
    }
}

struct NetworkTimeoutRecovery: RecoveryStrategy {
    func attemptRecovery(from error: Error, context: String) throws -> Bool {
        // Implement network retry logic with exponential backoff
        return false
    }
}

// MARK: - Extensions for Analytics Integration
extension AnalyticsManager {
    var sessionStartTime: Date? {
        return currentSession.startTime
    }
    
    var sessionId: String {
        return currentSession.sessionId
    }
    
    var userId: String {
        return self.userId
    }
    
    func getRecentEvents(limit: Int) -> [AnalyticsEventData] {
        return Array(eventQueue.suffix(limit))
    }
}

extension Thread {
    static func activeCount() -> Int {
        // This is a simplified implementation
        // In a real app, you might use more sophisticated thread counting
        return 1
    }
}