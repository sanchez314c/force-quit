import Foundation
import OSLog

// MARK: - Analytics Event Types
enum AnalyticsEvent: String, CaseIterable {
    // App Lifecycle
    case appLaunched = "app_launched"
    case appTerminated = "app_terminated"
    case appBackgrounded = "app_backgrounded"
    case appForegrounded = "app_foregrounded"
    
    // Core Functionality
    case forceQuitTriggered = "force_quit_triggered"
    case forceQuitCompleted = "force_quit_completed"
    case processSelected = "process_selected"
    case processDeselected = "process_deselected"
    case selectAllToggled = "select_all_toggled"
    case safeRestartAttempted = "safe_restart_attempted"
    case safeRestartCompleted = "safe_restart_completed"
    
    // UI Interactions
    case windowOpened = "window_opened"
    case windowClosed = "window_closed"
    case settingsOpened = "settings_opened"
    case hotkeysTriggered = "hotkeys_triggered"
    case themeChanged = "theme_changed"
    
    // Performance Metrics
    case processRefreshTime = "process_refresh_time"
    case forceQuitLatency = "force_quit_latency"
    case memoryUsage = "memory_usage"
    case cpuUsage = "cpu_usage"
    
    // Errors
    case permissionDenied = "permission_denied"
    case forceQuitFailed = "force_quit_failed"
    case systemError = "system_error"
}

// MARK: - Analytics Data Models
struct AnalyticsEventData {
    let event: AnalyticsEvent
    let timestamp: Date
    let sessionId: String
    let userId: String
    let appVersion: String
    let osVersion: String
    let properties: [String: Any]
    
    var dictionary: [String: Any] {
        return [
            "event": event.rawValue,
            "timestamp": ISO8601DateFormatter().string(from: timestamp),
            "session_id": sessionId,
            "user_id": userId,
            "app_version": appVersion,
            "os_version": osVersion,
            "properties": properties
        ]
    }
}

struct UserSession {
    let sessionId: String
    let startTime: Date
    var endTime: Date?
    var eventCount: Int = 0
    var crashCount: Int = 0
    var performanceMetrics: [String: Double] = [:]
}

struct PerformanceMetrics {
    let timestamp: Date
    let memoryUsage: Double // MB
    let cpuUsage: Double // Percentage
    let processCount: Int
    let refreshLatency: TimeInterval
    let forceQuitLatency: TimeInterval?
}

// MARK: - Analytics Manager
@MainActor
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private let logger = Logger(subsystem: "com.forcequit.analytics", category: "Analytics")
    private let sessionId = UUID().uuidString
    private let userId: String
    private var currentSession: UserSession
    private var performanceBuffer: [PerformanceMetrics] = []
    private var eventQueue: [AnalyticsEventData] = []
    
    // Privacy and Configuration
    @Published var analyticsEnabled: Bool = true
    @Published var crashReportingEnabled: Bool = true
    @Published var performanceMonitoringEnabled: Bool = true
    
    private let maxEventQueueSize = 1000
    private let flushInterval: TimeInterval = 30.0
    private var flushTimer: Timer?
    
    private init() {
        // Generate or retrieve persistent user ID
        if let savedUserId = UserDefaults.standard.string(forKey: "ForceQUIT_UserID") {
            self.userId = savedUserId
        } else {
            self.userId = UUID().uuidString
            UserDefaults.standard.set(self.userId, forKey: "ForceQUIT_UserID")
        }
        
        self.currentSession = UserSession(
            sessionId: sessionId,
            startTime: Date()
        )
        
        loadPreferences()
        startPerformanceMonitoring()
        startFlushTimer()
        
        // Track app launch
        trackEvent(.appLaunched)
        
        logger.info("Analytics Manager initialized - Session: \(sessionId)")
    }
    
    deinit {
        flushTimer?.invalidate()
        trackEvent(.appTerminated)
        flushEvents()
    }
}

// MARK: - Event Tracking
extension AnalyticsManager {
    func trackEvent(_ event: AnalyticsEvent, properties: [String: Any] = [:]) {
        guard analyticsEnabled else { return }
        
        let eventData = AnalyticsEventData(
            event: event,
            timestamp: Date(),
            sessionId: sessionId,
            userId: userId,
            appVersion: Bundle.main.appVersion,
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            properties: properties
        )
        
        eventQueue.append(eventData)
        currentSession.eventCount += 1
        
        // Flush if queue is getting full
        if eventQueue.count >= maxEventQueueSize {
            flushEvents()
        }
        
        logger.debug("Tracked event: \(event.rawValue) with properties: \(String(describing: properties))")
    }
    
    func trackUserFlow(_ events: [AnalyticsEvent], properties: [String: Any] = [:]) {
        let flowId = UUID().uuidString
        var flowProperties = properties
        flowProperties["flow_id"] = flowId
        flowProperties["flow_length"] = events.count
        
        for (index, event) in events.enumerated() {
            var eventProperties = flowProperties
            eventProperties["flow_step"] = index
            trackEvent(event, properties: eventProperties)
        }
    }
    
    func trackPerformance(_ metrics: PerformanceMetrics) {
        guard performanceMonitoringEnabled else { return }
        
        performanceBuffer.append(metrics)
        
        // Track performance event
        trackEvent(.processRefreshTime, properties: [
            "memory_usage_mb": metrics.memoryUsage,
            "cpu_usage_percent": metrics.cpuUsage,
            "process_count": metrics.processCount,
            "refresh_latency_ms": metrics.refreshLatency * 1000
        ])
        
        // Keep buffer size manageable
        if performanceBuffer.count > 100 {
            performanceBuffer.removeFirst(50)
        }
    }
    
    func trackError(_ error: Error, context: String = "", properties: [String: Any] = [:]) {
        var errorProperties = properties
        errorProperties["error_description"] = error.localizedDescription
        errorProperties["context"] = context
        errorProperties["error_domain"] = (error as NSError).domain
        errorProperties["error_code"] = (error as NSError).code
        
        trackEvent(.systemError, properties: errorProperties)
        
        logger.error("Tracked error: \(error.localizedDescription) in context: \(context)")
    }
    
    func trackCrash(_ crashInfo: [String: Any]) {
        guard crashReportingEnabled else { return }
        
        currentSession.crashCount += 1
        
        var crashProperties = crashInfo
        crashProperties["session_duration"] = Date().timeIntervalSince(currentSession.startTime)
        crashProperties["event_count"] = currentSession.eventCount
        
        // Create crash report
        let crashReport = CrashReport(
            sessionId: sessionId,
            userId: userId,
            timestamp: Date(),
            appVersion: Bundle.main.appVersion,
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            crashInfo: crashProperties,
            recentEvents: Array(eventQueue.suffix(20))
        )
        
        saveCrashReport(crashReport)
        
        logger.critical("Crash tracked and saved: \(String(describing: crashInfo))")
    }
}

// MARK: - Data Management
extension AnalyticsManager {
    private func flushEvents() {
        guard !eventQueue.isEmpty else { return }
        
        let eventsToFlush = eventQueue
        eventQueue.removeAll()
        
        // In production, send to analytics service
        saveEventsLocally(eventsToFlush)
        
        logger.info("Flushed \(eventsToFlush.count) events")
    }
    
    private func saveEventsLocally(_ events: [AnalyticsEventData]) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let analyticsPath = documentsPath.appendingPathComponent("ForceQUIT_Analytics")
        
        try? FileManager.default.createDirectory(at: analyticsPath, withIntermediateDirectories: true)
        
        let fileName = "events_\(ISO8601DateFormatter().string(from: Date())).json"
        let fileURL = analyticsPath.appendingPathComponent(fileName)
        
        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: events.map { $0.dictionary },
                options: .prettyPrinted
            )
            try jsonData.write(to: fileURL)
        } catch {
            logger.error("Failed to save events locally: \(error)")
        }
    }
    
    private func saveCrashReport(_ crashReport: CrashReport) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let crashReportsPath = documentsPath.appendingPathComponent("ForceQUIT_CrashReports")
        
        try? FileManager.default.createDirectory(at: crashReportsPath, withIntermediateDirectories: true)
        
        let fileName = "crash_\(crashReport.sessionId).json"
        let fileURL = crashReportsPath.appendingPathComponent(fileName)
        
        do {
            let jsonData = try JSONEncoder().encode(crashReport)
            try jsonData.write(to: fileURL)
        } catch {
            logger.error("Failed to save crash report: \(error)")
        }
    }
    
    private func loadPreferences() {
        analyticsEnabled = UserDefaults.standard.bool(forKey: "ForceQUIT_AnalyticsEnabled")
        crashReportingEnabled = UserDefaults.standard.bool(forKey: "ForceQUIT_CrashReportingEnabled")
        performanceMonitoringEnabled = UserDefaults.standard.bool(forKey: "ForceQUIT_PerformanceMonitoringEnabled")
    }
    
    func savePreferences() {
        UserDefaults.standard.set(analyticsEnabled, forKey: "ForceQUIT_AnalyticsEnabled")
        UserDefaults.standard.set(crashReportingEnabled, forKey: "ForceQUIT_CrashReportingEnabled")
        UserDefaults.standard.set(performanceMonitoringEnabled, forKey: "ForceQUIT_PerformanceMonitoringEnabled")
    }
}

// MARK: - Performance Monitoring
extension AnalyticsManager {
    private func startPerformanceMonitoring() {
        guard performanceMonitoringEnabled else { return }
        
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.capturePerformanceMetrics()
            }
        }
    }
    
    private func capturePerformanceMetrics() {
        let processInfo = ProcessInfo.processInfo
        let task = mach_task_self_
        
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(task, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        let memoryUsage = kerr == KERN_SUCCESS ? Double(info.resident_size) / 1024 / 1024 : 0
        
        let metrics = PerformanceMetrics(
            timestamp: Date(),
            memoryUsage: memoryUsage,
            cpuUsage: processInfo.thermalState == .nominal ? 0.0 : 0.0, // Simplified
            processCount: 0, // To be filled by process manager
            refreshLatency: 0.0, // To be filled by UI
            forceQuitLatency: nil
        )
        
        trackPerformance(metrics)
    }
    
    private func startFlushTimer() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: flushInterval, repeats: true) { [weak self] _ in
            self?.flushEvents()
        }
    }
}

// MARK: - Crash Report Model
struct CrashReport: Codable {
    let sessionId: String
    let userId: String
    let timestamp: Date
    let appVersion: String
    let osVersion: String
    let crashInfo: [String: String] // Simplified for Codable
    let recentEvents: [String] // Simplified event summaries
    
    init(sessionId: String, userId: String, timestamp: Date, appVersion: String, osVersion: String, crashInfo: [String: Any], recentEvents: [AnalyticsEventData]) {
        self.sessionId = sessionId
        self.userId = userId
        self.timestamp = timestamp
        self.appVersion = appVersion
        self.osVersion = osVersion
        
        // Convert Any to String for Codable compliance
        var stringCrashInfo: [String: String] = [:]
        for (key, value) in crashInfo {
            stringCrashInfo[key] = String(describing: value)
        }
        self.crashInfo = stringCrashInfo
        
        self.recentEvents = recentEvents.map { "\($0.event.rawValue)_\($0.timestamp)" }
    }
}

// MARK: - Bundle Extension
extension Bundle {
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
}