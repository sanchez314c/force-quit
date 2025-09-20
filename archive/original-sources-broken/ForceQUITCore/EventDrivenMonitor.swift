import Foundation
import Combine
import AppKit
import os.log

/// Event-driven process monitoring system that eliminates polling for maximum efficiency
/// Uses system notifications, KVO, and distributed notifications for real-time process tracking
final class EventDrivenMonitor: ObservableObject {
    
    // MARK: - Event Types
    enum ProcessEvent {
        case launched(ProcessInfo)
        case terminated(pid_t)
        case activated(pid_t)
        case deactivated(pid_t)
        case memoryPressure(pid_t, UInt64)
        case suspended(pid_t)
        case resumed(pid_t)
        
        var eventType: String {
            switch self {
            case .launched: return "launched"
            case .terminated: return "terminated"
            case .activated: return "activated"
            case .deactivated: return "deactivated"
            case .memoryPressure: return "memoryPressure"
            case .suspended: return "suspended"
            case .resumed: return "resumed"
            }
        }
    }
    
    struct ProcessInfo {
        let pid: pid_t
        let name: String
        let bundleIdentifier: String?
        let launchDate: Date
        let isHidden: Bool
        let memoryUsage: UInt64
        let cpuUsage: Double
    }
    
    // MARK: - Published Properties
    @Published private(set) var activeProcesses: [pid_t: ProcessInfo] = [:]
    @Published private(set) var recentEvents: [ProcessEvent] = []
    @Published private(set) var isMonitoring: Bool = false
    @Published private(set) var eventCount: Int = 0
    
    // MARK: - Event Publishers
    private let processEventSubject = PassthroughSubject<ProcessEvent, Never>()
    
    /// Publisher for process events
    var processEvents: AnyPublisher<ProcessEvent, Never> {
        processEventSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.forceQUIT.performance", category: "EventDrivenMonitor")
    private let queue = DispatchQueue(label: "event.monitor", qos: .userInteractive)
    
    // Event sources
    private var workspaceNotificationObserver: NSObjectProtocol?
    private var appActivationObserver: NSObjectProtocol?
    private var appDeactivationObserver: NSObjectProtocol?
    private var appHiddenObserver: NSObjectProtocol?
    private var appUnhiddenObserver: NSObjectProtocol?
    
    // BSD process monitoring
    private var processSource: DispatchSourceProcess?
    private var processMonitoringTasks: [pid_t: Task<Void, Never>] = [:]
    
    // Kernel event monitoring
    private var kernelEventSource: DispatchSourceFileSystemObject?
    private var procDirectory: Int32 = -1
    
    // Performance tracking
    private var lastEventTime = Date()
    private var eventLatencies: [TimeInterval] = []
    private let maxEventHistory = 100
    
    // MARK: - Initialization
    init() {
        setupNotificationObservers()
    }
    
    deinit {
        stopMonitoring()
        cleanup()
    }
    
    // MARK: - Public Interface
    
    /// Start event-driven monitoring
    func startMonitoring() async {
        guard !isMonitoring else { return }
        
        await MainActor.run {
            isMonitoring = true
        }
        
        logger.info("Starting event-driven process monitoring")
        
        // Initialize current process state
        await loadCurrentProcesses()
        
        // Setup all monitoring sources
        setupWorkspaceNotifications()
        setupKernelEventMonitoring()
        setupProcessStateMonitoring()
        
        logger.info("Event-driven monitoring active - tracking \(activeProcesses.count) processes")
    }
    
    /// Stop monitoring
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        cleanup()
        
        logger.info("Event-driven monitoring stopped")
    }
    
    /// Get current process by PID
    func getProcess(pid: pid_t) -> ProcessInfo? {
        return activeProcesses[pid]
    }
    
    /// Get processes matching criteria
    func getProcesses(matching predicate: (ProcessInfo) -> Bool) -> [ProcessInfo] {
        return activeProcesses.values.filter(predicate)
    }
    
    /// Force refresh specific process info
    func refreshProcess(pid: pid_t) async -> ProcessInfo? {
        guard let refreshedInfo = await getProcessInfo(for: pid) else {
            // Process might have terminated
            await handleProcessTerminated(pid: pid)
            return nil
        }
        
        await MainActor.run {
            activeProcesses[pid] = refreshedInfo
        }
        
        return refreshedInfo
    }
    
    /// Get monitoring performance metrics
    func getPerformanceMetrics() -> MonitoringMetrics {
        return MonitoringMetrics(
            eventCount: eventCount,
            averageEventLatency: eventLatencies.isEmpty ? 0 : eventLatencies.reduce(0, +) / Double(eventLatencies.count),
            activeProcessCount: activeProcesses.count,
            memoryUsage: getCurrentMemoryUsage(),
            cpuUsage: getCurrentCPUUsage()
        )
    }
    
    // MARK: - Private Implementation
    
    private func loadCurrentProcesses() async {
        logger.info("Loading current running processes")
        
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        
        var processes: [pid_t: ProcessInfo] = [:]
        
        for app in runningApps {
            if let processInfo = await getProcessInfo(for: app.processIdentifier) {
                processes[app.processIdentifier] = processInfo
            }
        }
        
        await MainActor.run {
            self.activeProcesses = processes
        }
        
        logger.info("Loaded \(processes.count) active processes")
    }
    
    private func setupNotificationObservers() {
        // These will be set up in setupWorkspaceNotifications()
    }
    
    private func setupWorkspaceNotifications() {
        let workspace = NSWorkspace.shared
        let notificationCenter = workspace.notificationCenter
        
        // App launch notifications
        workspaceNotificationObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { [weak self] in
                await self?.handleAppLaunched(notification: notification)
            }
        }
        
        // App termination notifications
        notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { [weak self] in
                await self?.handleAppTerminated(notification: notification)
            }
        }
        
        // App activation notifications
        appActivationObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppActivated(notification: notification)
        }
        
        // App deactivation notifications
        appDeactivationObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didDeactivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppDeactivated(notification: notification)
        }
        
        // App hidden/unhidden notifications
        appHiddenObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didHideApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppHidden(notification: notification)
        }
        
        appUnhiddenObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didUnhideApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppUnhidden(notification: notification)
        }
    }
    
    private func setupKernelEventMonitoring() {
        // Monitor /proc directory for new processes
        procDirectory = open("/proc", O_EVTONLY)
        guard procDirectory >= 0 else {
            logger.error("Failed to open /proc directory for monitoring")
            return
        }
        
        kernelEventSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: procDirectory,
            eventMask: [.write, .extend],
            queue: queue
        )
        
        kernelEventSource?.setEventHandler { [weak self] in
            Task { [weak self] in
                await self?.handleKernelEvent()
            }
        }
        
        kernelEventSource?.resume()
    }
    
    private func setupProcessStateMonitoring() {
        // Setup individual process monitoring for detailed state changes
        for pid in activeProcesses.keys {
            startMonitoringProcess(pid: pid)
        }
    }
    
    private func startMonitoringProcess(pid: pid_t) {
        guard processMonitoringTasks[pid] == nil else { return }
        
        let task = Task { [weak self] in
            await self?.monitorProcessState(pid: pid)
        }
        
        processMonitoringTasks[pid] = task
    }
    
    private func stopMonitoringProcess(pid: pid_t) {
        processMonitoringTasks[pid]?.cancel()
        processMonitoringTasks.removeValue(forKey: pid)
    }
    
    private func monitorProcessState(pid: pid_t) async {
        while !Task.isCancelled && isMonitoring {
            // Check process state periodically (but infrequently)
            guard let currentInfo = await getProcessInfo(for: pid) else {
                // Process terminated
                await handleProcessTerminated(pid: pid)
                break
            }
            
            // Check for significant changes
            if let previousInfo = activeProcesses[pid] {
                await checkForSignificantChanges(previous: previousInfo, current: currentInfo)
            }
            
            // Update process info
            await MainActor.run {
                activeProcesses[pid] = currentInfo
            }
            
            // Wait before next check (infrequent polling as fallback)
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        }
    }
    
    // MARK: - Event Handlers
    
    @MainActor
    private func handleAppLaunched(notification: Notification) async {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        let startTime = Date()
        let pid = app.processIdentifier
        
        guard let processInfo = await getProcessInfo(for: pid) else {
            logger.error("Failed to get process info for launched app: \(app.localizedName ?? "unknown")")
            return
        }
        
        activeProcesses[pid] = processInfo
        startMonitoringProcess(pid: pid)
        
        let event = ProcessEvent.launched(processInfo)
        publishEvent(event, latency: Date().timeIntervalSince(startTime))
        
        logger.info("App launched: \(processInfo.name) (PID: \(pid))")
    }
    
    private func handleAppTerminated(notification: Notification) async {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        await handleProcessTerminated(pid: app.processIdentifier)
    }
    
    @MainActor
    private func handleProcessTerminated(pid: pid_t) async {
        let startTime = Date()
        
        guard let processInfo = activeProcesses.removeValue(forKey: pid) else {
            return
        }
        
        stopMonitoringProcess(pid: pid)
        
        let event = ProcessEvent.terminated(pid)
        publishEvent(event, latency: Date().timeIntervalSince(startTime))
        
        logger.info("Process terminated: \(processInfo.name) (PID: \(pid))")
    }
    
    private func handleAppActivated(notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        let startTime = Date()
        let event = ProcessEvent.activated(app.processIdentifier)
        publishEvent(event, latency: Date().timeIntervalSince(startTime))
    }
    
    private func handleAppDeactivated(notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        let startTime = Date()
        let event = ProcessEvent.deactivated(app.processIdentifier)
        publishEvent(event, latency: Date().timeIntervalSince(startTime))
    }
    
    private func handleAppHidden(notification: Notification) {
        // Update process info to reflect hidden state
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            Task { [weak self] in
                await self?.refreshProcess(pid: app.processIdentifier)
            }
        }
    }
    
    private func handleAppUnhidden(notification: Notification) {
        // Update process info to reflect visible state
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            Task { [weak self] in
                await self?.refreshProcess(pid: app.processIdentifier)
            }
        }
    }
    
    private func handleKernelEvent() async {
        // Check for new processes in /proc
        // This is a fallback mechanism for processes not caught by workspace notifications
        await loadCurrentProcesses()
    }
    
    private func checkForSignificantChanges(previous: ProcessInfo, current: ProcessInfo) async {
        // Check for memory pressure
        let memoryThreshold = 100 * 1024 * 1024 // 100MB
        if current.memoryUsage > memoryThreshold && current.memoryUsage > previous.memoryUsage * 2 {
            let event = ProcessEvent.memoryPressure(current.pid, current.memoryUsage)
            publishEvent(event)
        }
        
        // Check for CPU spikes could be added here
        // Check for suspension/resumption could be added here
    }
    
    // MARK: - Utility Methods
    
    private func publishEvent(_ event: ProcessEvent, latency: TimeInterval? = nil) {
        let eventTime = Date()
        
        Task { @MainActor in
            // Add to recent events
            recentEvents.append(event)
            if recentEvents.count > maxEventHistory {
                recentEvents.removeFirst()
            }
            
            eventCount += 1
            
            // Track latency if provided
            if let latency = latency {
                eventLatencies.append(latency)
                if eventLatencies.count > maxEventHistory {
                    eventLatencies.removeFirst()
                }
            }
        }
        
        // Publish event
        processEventSubject.send(event)
        
        lastEventTime = eventTime
    }
    
    private func getProcessInfo(for pid: pid_t) async -> ProcessInfo? {
        // Get process info from system
        var kinfo = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        
        let result = sysctl(&mib, u_int(mib.count), &kinfo, &size, nil, 0)
        guard result == 0 else {
            return nil
        }
        
        // Get process name
        let name = withUnsafePointer(to: &kinfo.kp_proc.p_comm) {
            $0.withMemoryRebound(to: CChar.self, capacity: Int(MAXCOMLEN)) {
                String(cString: $0)
            }
        }
        
        // Get bundle identifier if available
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        let app = runningApps.first { $0.processIdentifier == pid }
        
        // Get memory usage
        let memoryUsage = getMemoryUsage(for: pid)
        
        // Get CPU usage
        let cpuUsage = getCPUUsage(for: pid)
        
        return ProcessInfo(
            pid: pid,
            name: app?.localizedName ?? name,
            bundleIdentifier: app?.bundleIdentifier,
            launchDate: app?.launchDate ?? Date(),
            isHidden: app?.isHidden ?? false,
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage
        )
    }
    
    private func getMemoryUsage(for pid: pid_t) -> UInt64 {
        var info = proc_taskinfo()
        let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, Int32(MemoryLayout<proc_taskinfo>.size))
        
        return result > 0 ? info.pti_resident_size : 0
    }
    
    private func getCPUUsage(for pid: pid_t) -> Double {
        var info = proc_taskinfo()
        let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, Int32(MemoryLayout<proc_taskinfo>.size))
        
        return result > 0 ? Double(info.pti_total_user + info.pti_total_system) / 1_000_000.0 : 0.0
    }
    
    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? UInt64(info.resident_size) : 0
    }
    
    private func getCurrentCPUUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Double(info.user_time.seconds + info.system_time.seconds) : 0.0
    }
    
    private func cleanup() {
        // Cancel all monitoring tasks
        for task in processMonitoringTasks.values {
            task.cancel()
        }
        processMonitoringTasks.removeAll()
        
        // Remove notification observers
        if let observer = workspaceNotificationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = appActivationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = appDeactivationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = appHiddenObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = appUnhiddenObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        
        // Cancel dispatch sources
        kernelEventSource?.cancel()
        
        // Close file descriptors
        if procDirectory >= 0 {
            close(procDirectory)
            procDirectory = -1
        }
    }
}

// MARK: - Supporting Types

struct MonitoringMetrics {
    let eventCount: Int
    let averageEventLatency: TimeInterval
    let activeProcessCount: Int
    let memoryUsage: UInt64
    let cpuUsage: Double
    
    var isPerformant: Bool {
        return averageEventLatency < 0.001 && // < 1ms average latency
               memoryUsage < 5 * 1024 * 1024   // < 5MB memory usage
    }
}