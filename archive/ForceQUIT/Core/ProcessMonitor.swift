import Foundation
import AppKit
import os.log
import libproc

/// SWARM 2.0 ForceQUIT - High-Performance Process Monitor
/// Advanced process monitoring system using NSRunningApplication and BSD task APIs
/// Optimized for real-time monitoring with minimal system impact

class ProcessMonitor: ObservableObject {
    // MARK: - Properties
    @Published private(set) var processes: [ProcessInfo] = []
    @Published private(set) var isMonitoring: Bool = false
    @Published private(set) var lastUpdateTime: Date = Date()
    
    private var monitoringTimer: Timer?
    private var processCache: [pid_t: ProcessInfo] = [:]
    private let processQueue = DispatchQueue(label: "com.forcequit.processmonitor", qos: .userInitiated)
    private let updateInterval: TimeInterval = 2.0 // 2 second update interval for performance
    
    // Performance tracking
    private var averageUpdateTime: TimeInterval = 0.0
    private var updateCount: Int = 0
    private let maxCacheSize = 500
    
    private let logger = Logger(subsystem: "com.forcequit.app", category: "ProcessMonitor")
    
    // MARK: - Initialization
    init() {
        setupNotificationObservers()
    }
    
    deinit {
        stopMonitoring()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Interface
    
    /// Start real-time process monitoring
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        logger.info("Starting process monitoring with \(self.updateInterval)s interval")
        
        isMonitoring = true
        
        // Initial scan
        performInitialScan()
        
        // Setup periodic updates
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateProcessList()
        }
    }
    
    /// Stop process monitoring
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        logger.info("Stopping process monitoring")
        
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        isMonitoring = false
    }
    
    /// Get process by PID
    func getProcess(pid: pid_t) -> ProcessInfo? {
        return processCache[pid]
    }
    
    /// Get processes filtered by criteria
    func getProcesses(filteredBy criteria: ProcessFilterCriteria) -> [ProcessInfo] {
        return processes.filter { criteria.matches($0) }
    }
    
    /// Force refresh process list
    func refreshProcessList() {
        updateProcessList()
    }
    
    // MARK: - Private Implementation
    
    private func setupNotificationObservers() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        
        // Application launch notifications
        notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        
        // Application terminate notifications
        notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidTerminate(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
        
        // Application activate notifications
        notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        
        // Application deactivate notifications
        notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidDeactivate(_:)),
            name: NSWorkspace.didDeactivateApplicationNotification,
            object: nil
        )
    }
    
    private func performInitialScan() {
        processQueue.async { [weak self] in
            guard let self = self else { return }
            
            let startTime = CFAbsoluteTimeGetCurrent()
            let scannedProcesses = self.scanAllProcesses()
            let scanTime = CFAbsoluteTimeGetCurrent() - startTime
            
            DispatchQueue.main.async {
                self.processes = scannedProcesses
                self.rebuildCache()
                self.lastUpdateTime = Date()
                self.logger.info("Initial scan completed: \(scannedProcesses.count) processes in \(scanTime, privacy: .public)s")
            }
        }
    }
    
    private func updateProcessList() {
        processQueue.async { [weak self] in
            guard let self = self else { return }
            
            let startTime = CFAbsoluteTimeGetCurrent()
            let updatedProcesses = self.scanAllProcesses()
            let delta = self.calculateProcessDelta(new: updatedProcesses)
            let updateTime = CFAbsoluteTimeGetCurrent() - startTime
            
            // Update performance metrics
            self.updatePerformanceMetrics(updateTime: updateTime)
            
            guard !delta.isEmpty else { return }
            
            DispatchQueue.main.async {
                self.applyProcessDelta(delta)
                self.lastUpdateTime = Date()
                self.logger.debug("Process update: +\(delta.added.count) -\(delta.removed.count) ~\(delta.modified.count) in \(updateTime, privacy: .public)s")
            }
        }
    }
    
    private func scanAllProcesses() -> [ProcessInfo] {
        var discoveredProcesses: [ProcessInfo] = []
        
        // Get all running applications via NSRunningApplication
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            if let processInfo = createProcessInfo(from: app) {
                discoveredProcesses.append(processInfo)
            }
        }
        
        // Supplement with system processes via BSD APIs
        let systemProcesses = scanSystemProcesses()
        discoveredProcesses.append(contentsOf: systemProcesses)
        
        return discoveredProcesses
    }
    
    private func createProcessInfo(from app: NSRunningApplication) -> ProcessInfo? {
        guard app.processIdentifier > 0 else { return nil }
        
        let pid = app.processIdentifier
        
        // Get resource usage
        let (memoryUsage, cpuUsage) = getProcessResourceUsage(pid: pid)
        
        // Determine security level and restart capability
        let securityLevel = ProcessClassifier.shared.determineSecurityLevel(for: app)
        let canRestart = ProcessClassifier.shared.canSafelyRestart(app)
        
        return ProcessInfo(
            id: pid,
            pid: pid,
            name: app.localizedName ?? app.bundleIdentifier ?? "Unknown",
            bundleIdentifier: app.bundleIdentifier,
            icon: app.icon,
            isActive: app.isActive,
            securityLevel: securityLevel,
            canSafelyRestart: canRestart,
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage
        )
    }
    
    private func scanSystemProcesses() -> [ProcessInfo] {
        var systemProcesses: [ProcessInfo] = []
        let maxProcesses = 2048
        var buffer = Array<pid_t>(repeating: 0, count: maxProcesses)
        
        let processCount = proc_listpids(PROC_ALL_PIDS, 0, &buffer, Int32(maxProcesses * MemoryLayout<pid_t>.size))
        let actualCount = Int(processCount) / MemoryLayout<pid_t>.size
        
        for i in 0..<actualCount {
            let pid = buffer[i]
            guard pid > 0 else { continue }
            
            // Skip if we already have this process from NSRunningApplication
            if processCache[pid] != nil { continue }
            
            if let processInfo = createSystemProcessInfo(pid: pid) {
                systemProcesses.append(processInfo)
            }
        }
        
        return systemProcesses
    }
    
    private func createSystemProcessInfo(pid: pid_t) -> ProcessInfo? {
        var buffer = proc_bsdinfo()
        let size = proc_pidinfo(pid, PROC_PIDTBSDINFO, 0, &buffer, Int32(MemoryLayout<proc_bsdinfo>.size))
        
        guard size > 0 else { return nil }
        
        let name = withUnsafePointer(to: &buffer.pbi_name) {
            $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: buffer.pbi_name)) {
                String(cString: $0)
            }
        }
        
        // Get resource usage
        let (memoryUsage, cpuUsage) = getProcessResourceUsage(pid: pid)
        
        // Classify system process
        let securityLevel = ProcessClassifier.shared.classifySystemProcess(name: name, pid: pid)
        let canRestart = ProcessClassifier.shared.canSafelyRestartSystemProcess(name: name)
        
        return ProcessInfo(
            id: pid,
            pid: pid,
            name: name,
            bundleIdentifier: nil,
            icon: NSWorkspace.shared.icon(forFileType: "public.unix-executable"),
            isActive: false,
            securityLevel: securityLevel,
            canSafelyRestart: canRestart,
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage
        )
    }
    
    private func getProcessResourceUsage(pid: pid_t) -> (memory: UInt64, cpu: Double) {
        // Get memory usage
        var taskInfo = proc_taskinfo()
        let infoSize = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, Int32(MemoryLayout<proc_taskinfo>.size))
        
        let memoryUsage: UInt64 = infoSize > 0 ? taskInfo.pti_resident_size : 0
        
        // CPU usage calculation (simplified for performance)
        let cpuUsage = getCPUUsage(pid: pid)
        
        return (memoryUsage, cpuUsage)
    }
    
    private func getCPUUsage(pid: pid_t) -> Double {
        var taskInfo = proc_taskinfo()
        let size = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, Int32(MemoryLayout<proc_taskinfo>.size))
        
        guard size > 0 else { return 0.0 }
        
        // Simple CPU usage calculation (total time / wall time approximation)
        let totalTime = taskInfo.pti_total_user + taskInfo.pti_total_system
        let cpuUsage = Double(totalTime) / 1_000_000.0 // Convert to seconds
        
        return min(cpuUsage / 100.0, 1.0) // Normalize to 0-1 range
    }
    
    private func calculateProcessDelta(new newProcesses: [ProcessInfo]) -> ProcessDelta {
        let currentPIDs = Set(processes.map { $0.pid })
        let newPIDs = Set(newProcesses.map { $0.pid })
        
        let addedPIDs = newPIDs.subtracting(currentPIDs)
        let removedPIDs = currentPIDs.subtracting(newPIDs)
        let continuingPIDs = currentPIDs.intersection(newPIDs)
        
        let added = Set(newProcesses.filter { addedPIDs.contains($0.pid) })
        let modified = Set(newProcesses.compactMap { newProcess in
            guard continuingPIDs.contains(newProcess.pid),
                  let existing = processCache[newProcess.pid],
                  hasSignificantChanges(existing: existing, new: newProcess) else {
                return nil
            }
            return newProcess
        })
        
        return ProcessDelta(added: added, removed: removedPIDs, modified: modified)
    }
    
    private func hasSignificantChanges(existing: ProcessInfo, new: ProcessInfo) -> Bool {
        let memoryThreshold: UInt64 = 1024 * 1024 // 1MB threshold
        let cpuThreshold: Double = 0.02 // 2% threshold
        
        return abs(Int64(new.memoryUsage) - Int64(existing.memoryUsage)) > Int64(memoryThreshold) ||
               abs(new.cpuUsage - existing.cpuUsage) > cpuThreshold ||
               new.isActive != existing.isActive
    }
    
    private func applyProcessDelta(_ delta: ProcessDelta) {
        var updatedProcesses = processes
        
        // Remove terminated processes
        updatedProcesses.removeAll { delta.removed.contains($0.pid) }
        
        // Add new processes
        updatedProcesses.append(contentsOf: delta.added)
        
        // Update modified processes
        for modifiedProcess in delta.modified {
            if let index = updatedProcesses.firstIndex(where: { $0.pid == modifiedProcess.pid }) {
                updatedProcesses[index] = modifiedProcess
            }
        }
        
        processes = updatedProcesses
        rebuildCache()
    }
    
    private func rebuildCache() {
        processCache.removeAll()
        
        for process in processes {
            processCache[process.pid] = process
        }
        
        // Limit cache size for memory efficiency
        if processCache.count > maxCacheSize {
            let excess = processCache.count - maxCacheSize
            let keysToRemove = Array(processCache.keys.prefix(excess))
            for key in keysToRemove {
                processCache.removeValue(forKey: key)
            }
        }
    }
    
    private func updatePerformanceMetrics(updateTime: TimeInterval) {
        updateCount += 1
        averageUpdateTime = (averageUpdateTime * Double(updateCount - 1) + updateTime) / Double(updateCount)
        
        if updateCount % 100 == 0 {
            logger.info("Performance: \(self.updateCount) updates, avg time: \(self.averageUpdateTime, privacy: .public)s")
        }
    }
    
    // MARK: - Notification Handlers
    
    @objc private func applicationDidLaunch(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        logger.debug("Application launched: \(app.localizedName ?? "Unknown", privacy: .public)")
        
        // Trigger immediate update for responsiveness
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateProcessList()
        }
    }
    
    @objc private func applicationDidTerminate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        logger.debug("Application terminated: \(app.localizedName ?? "Unknown", privacy: .public)")
        
        // Trigger immediate update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateProcessList()
        }
    }
    
    @objc private func applicationDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        
        // Update active state immediately
        if let index = processes.firstIndex(where: { $0.pid == app.processIdentifier }) {
            processes[index] = processes[index].updatingActiveState(isActive: true)
            processCache[app.processIdentifier] = processes[index]
        }
    }
    
    @objc private func applicationDidDeactivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        
        // Update active state immediately
        if let index = processes.firstIndex(where: { $0.pid == app.processIdentifier }) {
            processes[index] = processes[index].updatingActiveState(isActive: false)
            processCache[app.processIdentifier] = processes[index]
        }
    }
}

// MARK: - Process Filter Criteria
struct ProcessFilterCriteria {
    let securityLevels: Set<ProcessInfo.SecurityLevel>
    let showOnlyActive: Bool
    let showOnlyRestartable: Bool
    let searchText: String
    let minimumMemoryUsage: UInt64
    let minimumCPUUsage: Double
    
    init(securityLevels: Set<ProcessInfo.SecurityLevel> = Set(ProcessInfo.SecurityLevel.allCases),
         showOnlyActive: Bool = false,
         showOnlyRestartable: Bool = false,
         searchText: String = "",
         minimumMemoryUsage: UInt64 = 0,
         minimumCPUUsage: Double = 0.0) {
        
        self.securityLevels = securityLevels
        self.showOnlyActive = showOnlyActive
        self.showOnlyRestartable = showOnlyRestartable
        self.searchText = searchText
        self.minimumMemoryUsage = minimumMemoryUsage
        self.minimumCPUUsage = minimumCPUUsage
    }
    
    func matches(_ process: ProcessInfo) -> Bool {
        // Security level filter
        guard securityLevels.contains(process.securityLevel) else { return false }
        
        // Active state filter
        if showOnlyActive && !process.isActive { return false }
        
        // Restartable filter
        if showOnlyRestartable && !process.canSafelyRestart { return false }
        
        // Search text filter
        if !searchText.isEmpty {
            let matchesName = process.name.localizedCaseInsensitiveContains(searchText)
            let matchesBundleID = process.bundleIdentifier?.localizedCaseInsensitiveContains(searchText) ?? false
            if !matchesName && !matchesBundleID { return false }
        }
        
        // Resource usage filters
        if process.memoryUsage < minimumMemoryUsage { return false }
        if process.cpuUsage < minimumCPUUsage { return false }
        
        return true
    }
}

// MARK: - Performance Extensions
extension ProcessMonitor {
    var performanceMetrics: ProcessMonitorPerformanceMetrics {
        return ProcessMonitorPerformanceMetrics(
            averageUpdateTime: averageUpdateTime,
            updateCount: updateCount,
            processCount: processes.count,
            cacheSize: processCache.count,
            memoryEfficiency: Double(processCache.count) / Double(maxCacheSize)
        )
    }
}

struct ProcessMonitorPerformanceMetrics {
    let averageUpdateTime: TimeInterval
    let updateCount: Int
    let processCount: Int
    let cacheSize: Int
    let memoryEfficiency: Double
    
    var isPerformanceOptimal: Bool {
        return averageUpdateTime < 0.1 && memoryEfficiency < 0.8
    }
}