import Foundation
import AppKit
import os.log
import IOKit
import IOKit.pwr_mgt

/// SWARM 2.0 ForceQUIT - Advanced System Event Handler
/// Comprehensive system event monitoring and process state change detection
/// Handles workspace notifications, power events, and system state transitions

class SystemEventHandler: ObservableObject {
    // MARK: - Properties
    @Published private(set) var systemState: SystemState = .normal
    @Published private(set) var recentEvents: [SystemEvent] = []
    @Published private(set) var isMonitoring: Bool = false
    
    private let logger = Logger(subsystem: "com.forcequit.app", category: "SystemEventHandler")
    private let eventQueue = DispatchQueue(label: "com.forcequit.systemevents", qos: .userInitiated)
    
    // Event monitoring
    private var workspaceObservers: [NSObjectProtocol] = []
    private var powerAssertionID: IOPMAssertionID = IOPMAssertionID()
    private var systemEventCallback: ((SystemEvent) -> Void)?
    
    // Event filtering and throttling
    private var eventThrottleTimer: Timer?
    private var pendingEvents: [SystemEvent] = []
    private let eventThrottleInterval: TimeInterval = 0.5
    private let maxEventHistory = 500
    
    // System state tracking
    private var lastSleepTime: Date?
    private var lastWakeTime: Date?
    private var isSystemSleeping = false
    
    // MARK: - Initialization
    init() {
        setupSystemEventMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Interface
    
    /// Start monitoring system events
    func startMonitoring(callback: @escaping (SystemEvent) -> Void = { _ in }) {
        guard !isMonitoring else { return }
        
        logger.info("Starting system event monitoring")
        
        systemEventCallback = callback
        isMonitoring = true
        
        setupWorkspaceNotifications()
        setupPowerManagement()
        
        recordEvent(.monitoringStarted(timestamp: Date()))
    }
    
    /// Stop monitoring system events
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        logger.info("Stopping system event monitoring")
        
        isMonitoring = false
        systemEventCallback = nil
        
        removeWorkspaceNotifications()
        cleanupPowerManagement()
        
        recordEvent(.monitoringStopped(timestamp: Date()))
    }
    
    /// Get events filtered by type and time range
    func getEvents(ofType type: SystemEventType? = nil, 
                   since: Date? = nil,
                   limit: Int = 100) -> [SystemEvent] {
        var filteredEvents = recentEvents
        
        if let type = type {
            filteredEvents = filteredEvents.filter { $0.type == type }
        }
        
        if let since = since {
            filteredEvents = filteredEvents.filter { $0.timestamp >= since }
        }
        
        return Array(filteredEvents.suffix(limit))
    }
    
    /// Clear event history
    func clearEventHistory() {
        recentEvents.removeAll()
        logger.info("Event history cleared")
    }
    
    /// Get current system health metrics
    func getSystemHealthMetrics() -> SystemHealthMetrics {
        let recentEventCounts = Dictionary(grouping: getEvents(since: Date().addingTimeInterval(-300))) { $0.type }
            .mapValues { $0.count }
        
        let processEvents = recentEventCounts[.processLaunched] ?? 0 + 
                           recentEventCounts[.processTerminated] ?? 0
        
        let powerEvents = recentEventCounts[.systemWillSleep] ?? 0 +
                         recentEventCounts[.systemDidWake] ?? 0
        
        let userActivityEvents = recentEventCounts[.userSessionActivated] ?? 0 +
                                recentEventCounts[.userSessionDeactivated] ?? 0
        
        return SystemHealthMetrics(
            systemState: systemState,
            recentProcessActivityLevel: processActivityLevel(eventCount: processEvents),
            recentPowerEventCount: powerEvents,
            recentUserActivityLevel: userActivityLevel(eventCount: userActivityEvents),
            totalEventsTracked: recentEvents.count,
            monitoringUptime: isMonitoring ? Date().timeIntervalSince(lastWakeTime ?? Date()) : 0
        )
    }
    
    // MARK: - Private Implementation
    
    private func setupSystemEventMonitoring() {
        // Initial system state detection
        updateSystemState()
    }
    
    private func setupWorkspaceNotifications() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        
        // Application lifecycle events
        workspaceObservers.append(
            notificationCenter.addObserver(
                forName: NSWorkspace.didLaunchApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.handleApplicationLaunch(notification)
            }
        )
        
        workspaceObservers.append(
            notificationCenter.addObserver(
                forName: NSWorkspace.didTerminateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.handleApplicationTerminate(notification)
            }
        )
        
        workspaceObservers.append(
            notificationCenter.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.handleApplicationActivate(notification)
            }
        )
        
        workspaceObservers.append(
            notificationCenter.addObserver(
                forName: NSWorkspace.didDeactivateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                self?.handleApplicationDeactivate(notification)
            }
        )
        
        // System state events
        workspaceObservers.append(
            notificationCenter.addObserver(
                forName: NSWorkspace.willSleepNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleSystemWillSleep()
            }
        )
        
        workspaceObservers.append(
            notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleSystemDidWake()
            }
        )
        
        // Session events
        workspaceObservers.append(
            notificationCenter.addObserver(
                forName: NSWorkspace.sessionDidBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleSessionActivate()
            }
        )
        
        workspaceObservers.append(
            notificationCenter.addObserver(
                forName: NSWorkspace.sessionDidResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleSessionDeactivate()
            }
        )
        
        // Screen lock events
        workspaceObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleScreenUnlock()
            }
        )
        
        workspaceObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleScreenLock()
            }
        )
    }
    
    private func removeWorkspaceNotifications() {
        for observer in workspaceObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
            NotificationCenter.default.removeObserver(observer)
        }
        workspaceObservers.removeAll()
    }
    
    private func setupPowerManagement() {
        // Create power assertion to prevent unexpected sleep during operations
        let assertionName = "ForceQUIT System Monitoring" as CFString
        let assertionLevel = kIOPMAssertionLevelOn
        
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertPreventUserIdleSystemSleep,
            assertionLevel,
            assertionName,
            &powerAssertionID
        )
        
        if result != kIOReturnSuccess {
            logger.warning("Failed to create power assertion: \(result)")
        }
    }
    
    private func cleanupPowerManagement() {
        if powerAssertionID != IOPMAssertionID() {
            IOPMAssertionRelease(powerAssertionID)
            powerAssertionID = IOPMAssertionID()
        }
    }
    
    private func updateSystemState() {
        // Determine current system state based on various factors
        let workspace = NSWorkspace.shared
        
        if isSystemSleeping {
            systemState = .sleeping
        } else if workspace.runningApplications.count < 5 {
            systemState = .minimal
        } else if workspace.runningApplications.filter({ $0.activationPolicy == .regular }).count > 10 {
            systemState = .busy
        } else {
            systemState = .normal
        }
    }
    
    private func recordEvent(_ event: SystemEvent) {
        eventQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Add to pending events for throttling
            self.pendingEvents.append(event)
            
            // Start throttle timer if not already running
            if self.eventThrottleTimer == nil {
                DispatchQueue.main.async {
                    self.eventThrottleTimer = Timer.scheduledTimer(withTimeInterval: self.eventThrottleInterval, repeats: false) { _ in
                        self.processPendingEvents()
                    }
                }
            }
        }
    }
    
    private func processPendingEvents() {
        eventQueue.async { [weak self] in
            guard let self = self else { return }
            
            let eventsToProcess = self.pendingEvents
            self.pendingEvents.removeAll()
            
            DispatchQueue.main.async {
                // Add events to history
                self.recentEvents.append(contentsOf: eventsToProcess)
                
                // Trim history if needed
                if self.recentEvents.count > self.maxEventHistory {
                    self.recentEvents.removeFirst(self.recentEvents.count - self.maxEventHistory)
                }
                
                // Update system state
                self.updateSystemState()
                
                // Notify callback for each event
                for event in eventsToProcess {
                    self.systemEventCallback?(event)
                    self.logger.debug("System event recorded: \(event.type.rawValue, privacy: .public)")
                }
                
                self.eventThrottleTimer = nil
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleApplicationLaunch(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        
        let event = SystemEvent(
            type: .processLaunched,
            timestamp: Date(),
            processInfo: createProcessInfo(from: app),
            metadata: [
                "bundleIdentifier": app.bundleIdentifier ?? "unknown",
                "localizedName": app.localizedName ?? "unknown",
                "activationPolicy": String(describing: app.activationPolicy)
            ]
        )
        
        recordEvent(event)
    }
    
    private func handleApplicationTerminate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        
        let event = SystemEvent(
            type: .processTerminated,
            timestamp: Date(),
            processInfo: createProcessInfo(from: app),
            metadata: [
                "bundleIdentifier": app.bundleIdentifier ?? "unknown",
                "localizedName": app.localizedName ?? "unknown",
                "wasForceTerminated": "false" // We don't know this from the notification
            ]
        )
        
        recordEvent(event)
    }
    
    private func handleApplicationActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        
        let event = SystemEvent(
            type: .processActivated,
            timestamp: Date(),
            processInfo: createProcessInfo(from: app),
            metadata: [
                "bundleIdentifier": app.bundleIdentifier ?? "unknown"
            ]
        )
        
        recordEvent(event)
    }
    
    private func handleApplicationDeactivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        
        let event = SystemEvent(
            type: .processDeactivated,
            timestamp: Date(),
            processInfo: createProcessInfo(from: app),
            metadata: [
                "bundleIdentifier": app.bundleIdentifier ?? "unknown"
            ]
        )
        
        recordEvent(event)
    }
    
    private func handleSystemWillSleep() {
        lastSleepTime = Date()
        isSystemSleeping = true
        
        let event = SystemEvent(
            type: .systemWillSleep,
            timestamp: Date(),
            processInfo: nil,
            metadata: [:]
        )
        
        recordEvent(event)
    }
    
    private func handleSystemDidWake() {
        lastWakeTime = Date()
        isSystemSleeping = false
        
        let sleepDuration = lastSleepTime.map { Date().timeIntervalSince($0) } ?? 0
        
        let event = SystemEvent(
            type: .systemDidWake,
            timestamp: Date(),
            processInfo: nil,
            metadata: [
                "sleepDuration": String(sleepDuration)
            ]
        )
        
        recordEvent(event)
    }
    
    private func handleSessionActivate() {
        let event = SystemEvent(
            type: .userSessionActivated,
            timestamp: Date(),
            processInfo: nil,
            metadata: [:]
        )
        
        recordEvent(event)
    }
    
    private func handleSessionDeactivate() {
        let event = SystemEvent(
            type: .userSessionDeactivated,
            timestamp: Date(),
            processInfo: nil,
            metadata: [:]
        )
        
        recordEvent(event)
    }
    
    private func handleScreenLock() {
        let event = SystemEvent(
            type: .screenLocked,
            timestamp: Date(),
            processInfo: nil,
            metadata: [:]
        )
        
        recordEvent(event)
    }
    
    private func handleScreenUnlock() {
        let event = SystemEvent(
            type: .screenUnlocked,
            timestamp: Date(),
            processInfo: nil,
            metadata: [:]
        )
        
        recordEvent(event)
    }
    
    // MARK: - Helper Methods
    
    private func createProcessInfo(from app: NSRunningApplication) -> ProcessInfo? {
        return ProcessInfo(
            id: app.processIdentifier,
            pid: app.processIdentifier,
            name: app.localizedName ?? app.bundleIdentifier ?? "Unknown",
            bundleIdentifier: app.bundleIdentifier,
            icon: app.icon,
            isActive: app.isActive
        )
    }
    
    private func processActivityLevel(eventCount: Int) -> ProcessActivityLevel {
        if eventCount > 20 { return .high }
        if eventCount > 10 { return .medium }
        if eventCount > 5 { return .low }
        return .minimal
    }
    
    private func userActivityLevel(eventCount: Int) -> UserActivityLevel {
        if eventCount > 10 { return .high }
        if eventCount > 5 { return .medium }
        if eventCount > 2 { return .low }
        return .minimal
    }
}

// MARK: - Supporting Types

enum SystemState: String, CaseIterable {
    case normal = "Normal"
    case busy = "Busy"
    case minimal = "Minimal"
    case sleeping = "Sleeping"
    
    var description: String {
        switch self {
        case .normal: return "Normal operation"
        case .busy: return "High system activity"
        case .minimal: return "Minimal system activity"
        case .sleeping: return "System sleeping"
        }
    }
    
    var systemImage: String {
        switch self {
        case .normal: return "desktopcomputer"
        case .busy: return "gauge.high"
        case .minimal: return "gauge.low"
        case .sleeping: return "moon.zzz"
        }
    }
}

enum SystemEventType: String, CaseIterable {
    case processLaunched = "ProcessLaunched"
    case processTerminated = "ProcessTerminated"
    case processActivated = "ProcessActivated"
    case processDeactivated = "ProcessDeactivated"
    case systemWillSleep = "SystemWillSleep"
    case systemDidWake = "SystemDidWake"
    case userSessionActivated = "UserSessionActivated"
    case userSessionDeactivated = "UserSessionDeactivated"
    case screenLocked = "ScreenLocked"
    case screenUnlocked = "ScreenUnlocked"
    case monitoringStarted = "MonitoringStarted"
    case monitoringStopped = "MonitoringStopped"
    
    var category: EventCategory {
        switch self {
        case .processLaunched, .processTerminated, .processActivated, .processDeactivated:
            return .process
        case .systemWillSleep, .systemDidWake:
            return .power
        case .userSessionActivated, .userSessionDeactivated, .screenLocked, .screenUnlocked:
            return .user
        case .monitoringStarted, .monitoringStopped:
            return .system
        }
    }
}

enum EventCategory: String, CaseIterable {
    case process = "Process"
    case power = "Power"
    case user = "User"
    case system = "System"
}

enum ProcessActivityLevel: String {
    case minimal = "Minimal"
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

enum UserActivityLevel: String {
    case minimal = "Minimal"
    case low = "Low" 
    case medium = "Medium"
    case high = "High"
}

struct SystemEvent {
    let type: SystemEventType
    let timestamp: Date
    let processInfo: ProcessInfo?
    let metadata: [String: String]
    
    var category: EventCategory {
        type.category
    }
}

struct SystemHealthMetrics {
    let systemState: SystemState
    let recentProcessActivityLevel: ProcessActivityLevel
    let recentPowerEventCount: Int
    let recentUserActivityLevel: UserActivityLevel
    let totalEventsTracked: Int
    let monitoringUptime: TimeInterval
    
    var healthScore: Double {
        var score: Double = 1.0
        
        // Reduce score for high activity
        switch recentProcessActivityLevel {
        case .minimal: score *= 1.0
        case .low: score *= 0.9
        case .medium: score *= 0.8
        case .high: score *= 0.6
        }
        
        // Reduce score for excessive power events
        if recentPowerEventCount > 5 {
            score *= 0.7
        }
        
        // System state impact
        switch systemState {
        case .normal: score *= 1.0
        case .busy: score *= 0.8
        case .minimal: score *= 0.9
        case .sleeping: score *= 1.0
        }
        
        return max(0.0, min(1.0, score))
    }
    
    var isHealthy: Bool {
        healthScore > 0.7
    }
}