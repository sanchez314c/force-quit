import Foundation
import AppKit
import Combine
import OSLog

// SWARM 2.0 ForceQUIT - Process Monitoring System - OPTIMIZED
// Event-driven architecture - NO POLLING for performance
// Memory Budget: <10MB base, <20MB peak

@MainActor
class ProcessMonitorViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var processes: [ProcessInfo] = []
    @Published var selectedProcesses: Set<ProcessInfo.ID> = []
    @Published var systemHealth: SystemHealthStatus = .normal
    @Published var isScanning: Bool = false
    @Published var lastUpdateTime: Date = Date()
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.forceQUIT.app", category: "ProcessMonitor")
    private var cancellables = Set<AnyCancellable>()
    private let processCache = ProcessCache()
    private var workspaceObservers: [NSObjectProtocol] = []
    
    // Performance optimization - smart monitoring
    private let performanceOptimizer = PerformanceOptimizer.shared
    
    // Performance optimization - differential scanning
    private var lastProcessSnapshot: Set<pid_t> = []
    
    init() {
        setupEventDrivenMonitoring()
        setupPerformanceOptimizationListeners()
        performInitialScan()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Event-Driven Monitoring Setup
    private func setupEventDrivenMonitoring() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        
        // Application lifecycle events - pure event-driven, zero polling
        let launchObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                await self?.handleApplicationLaunched(notification)
            }
        }
        
        let terminateObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                await self?.handleApplicationTerminated(notification)
            }
        }
        
        let activateObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                await self?.handleApplicationActivated(notification)
            }
        }
        
        workspaceObservers = [launchObserver, terminateObserver, activateObserver]
        
        // Optimized health monitoring - triggered by memory pressure events
        PerformanceOptimizer.shared.$isMemoryOptimizationActive
            .sink { [weak self] isOptimizing in
                if isOptimizing {
                    Task { @MainActor in
                        await self?.updateSystemHealth()
                    }
                }
            }
            .store(in: &cancellables)
        
        logger.info("Event-driven process monitoring initialized")
    }
    
    // MARK: - Performance Optimization Integration
    private func setupPerformanceOptimizationListeners() {
        // Listen for performance optimization commands
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OptimizeProcessMonitoring"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let interval = notification.userInfo?["interval"] as? Double {
                self?.adjustMonitoringFrequency(interval)
            }
        }
        
        // Listen for memory pressure warnings
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ReduceUpdateFrequency"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.enableLowPowerMode()
        }
        
        logger.info("Performance optimization listeners configured")
    }
    
    private func adjustMonitoringFrequency(_ interval: TimeInterval) {
        // Dynamically adjust monitoring based on system performance
        logger.info("Adjusting monitoring frequency to \\(interval) seconds")
        
        // Instead of continuous monitoring, switch to demand-based updates
        lastUpdateTime = Date()
    }
    
    private func enableLowPowerMode() {
        // Reduce monitoring to absolute minimum
        logger.warning("Enabling low-power monitoring mode")
        
        // Clear non-essential cached data
        Task {
            await processCache.cleanup()
        }
    }
    
    // MARK: - Initial System Scan
    private func performInitialScan() {
        Task { @MainActor in
            isScanning = true
            
            let runningApps = NSWorkspace.shared.runningApplications
                .filter { !$0.isAgent } // Filter out background agents for cleaner UI
            
            var processInfos: [ProcessInfo] = []
            
            for app in runningApps {
                if let processInfo = await createProcessInfo(from: app) {
                    processInfos.append(processInfo)
                }
            }
            
            self.processes = processInfos.sorted { $0.name < $1.name }
            self.lastProcessSnapshot = Set(runningApps.map { $0.processIdentifier })
            self.lastUpdateTime = Date()
            
            await updateSystemHealth()
            
            logger.info("Initial process scan completed: \\(processInfos.count) applications discovered")
            
            isScanning = false
        }
    }
    
    // MARK: - Event Handlers
    private func handleApplicationLaunched(_ notification: Notification) async {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        if let processInfo = await createProcessInfo(from: app) {
            processes.append(processInfo)
            processes.sort { $0.name < $1.name }
            lastProcessSnapshot.insert(app.processIdentifier)
            lastUpdateTime = Date()
            
            logger.info("Application launched: \\(processInfo.name)")
        }
    }
    
    private func handleApplicationTerminated(_ notification: Notification) async {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        processes.removeAll { $0.pid == app.processIdentifier }
        selectedProcesses.remove(app.processIdentifier)
        lastProcessSnapshot.remove(app.processIdentifier)
        lastUpdateTime = Date()
        
        logger.info("Application terminated: PID \\(app.processIdentifier)")
    }
    
    private func handleApplicationActivated(_ notification: Notification) async {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        // Update the active status of the process
        if let index = processes.firstIndex(where: { $0.pid == app.processIdentifier }) {
            processes[index] = processes[index].updatingActiveState(isActive: true)
            lastUpdateTime = Date()
        }
    }
    
    // MARK: - Process Information Creation
    private func createProcessInfo(from app: NSRunningApplication) async -> ProcessInfo? {
        // Skip system processes and protected processes
        if isProtectedProcess(app) {
            return nil
        }
        
        let securityLevel = determineSecurityLevel(for: app)
        let canSafelyRestart = await checkSafeRestartCapability(for: app)
        
        return ProcessInfo(
            id: app.processIdentifier,
            pid: app.processIdentifier,
            name: app.localizedName ?? "Unknown",
            bundleIdentifier: app.bundleIdentifier,
            icon: app.icon,
            isActive: app.isActive,
            securityLevel: securityLevel,
            canSafelyRestart: canSafelyRestart,
            memoryUsage: getMemoryUsage(for: app.processIdentifier),
            cpuUsage: getCPUUsage(for: app.processIdentifier)
        )
    }
    
    // MARK: - Security and Safety Checks
    private func isProtectedProcess(_ app: NSRunningApplication) -> Bool {
        let protectedProcesses: Set<String> = [
            "kernel_task", "launchd", "loginwindow", "WindowServer",
            "securityd", "systemuiserver", "ForceQUIT"  // Don't show ourselves
        ]
        
        if let bundleId = app.bundleIdentifier,
           protectedProcesses.contains(bundleId) {
            return true
        }
        
        // Additional checks for system processes
        if app.bundleIdentifier?.starts(with: "com.apple.") == true &&
           (app.bundleIdentifier?.contains("loginwindow") == true ||
            app.bundleIdentifier?.contains("WindowServer") == true) {
            return true
        }
        
        return false
    }
    
    private func determineSecurityLevel(for app: NSRunningApplication) -> ProcessInfo.SecurityLevel {
        guard let bundleId = app.bundleIdentifier else { return .medium }
        
        if bundleId.starts(with: "com.apple.") {
            return .high
        } else if app.isAgent {
            return .medium
        } else {
            return .low
        }
    }
    
    private func checkSafeRestartCapability(for app: NSRunningApplication) async -> Bool {
        // Check if the app supports state restoration
        guard let bundleId = app.bundleIdentifier else { return false }
        
        // Apps known to support safe restart
        let safeRestartApps: Set<String> = [
            "com.apple.Safari",
            "com.apple.TextEdit",
            "com.apple.Preview",
            "com.microsoft.VSCode",
            "com.google.Chrome"
        ]
        
        return safeRestartApps.contains(bundleId)
    }
    
    // MARK: - System Health Monitoring
    private func updateSystemHealth() async {
        let processCount = processes.count
        let memoryPressure = getSystemMemoryPressure()
        let cpuUsage = getSystemCPUUsage()
        
        // Determine system health based on metrics
        if processCount > 100 || memoryPressure > 0.9 || cpuUsage > 0.8 {
            systemHealth = .critical
        } else if processCount > 50 || memoryPressure > 0.7 || cpuUsage > 0.6 {
            systemHealth = .warning
        } else {
            systemHealth = .normal
        }
    }
    
    // MARK: - Force Quit Operations
    func forceQuitProcess(_ processInfo: ProcessInfo) async {
        logger.info("Attempting to force quit: \\(processInfo.name) (PID: \\(processInfo.pid))")
        
        guard let app = NSWorkspace.shared.runningApplications.first(where: { 
            $0.processIdentifier == processInfo.pid 
        }) else {
            logger.error("Process not found: \\(processInfo.pid)")
            return
        }
        
        // Graceful termination first (SIGTERM)
        let terminated = app.terminate()
        
        if !terminated {
            // Force termination if graceful fails (SIGKILL)
            logger.warning("Graceful termination failed for \\(processInfo.name), using force termination")
            app.forceTerminate()
        }
        
        // Remove from selection
        selectedProcesses.remove(processInfo.id)
    }
    
    func forceQuitSelectedProcesses() async {
        let processesToQuit = processes.filter { selectedProcesses.contains($0.id) }
        
        for processInfo in processesToQuit {
            await forceQuitProcess(processInfo)
            
            // Small delay between operations for system stability
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        selectedProcesses.removeAll()
    }
    
    // MARK: - Resource Usage Monitoring
    private func getMemoryUsage(for pid: pid_t) -> UInt64 {
        var info = proc_taskinfo()
        let size = MemoryLayout<proc_taskinfo>.size
        
        guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, Int32(size)) == Int32(size) else {
            return 0
        }
        
        return info.pti_resident_size
    }
    
    private func getCPUUsage(for pid: pid_t) -> Double {
        var info = proc_taskinfo()
        let size = MemoryLayout<proc_taskinfo>.size
        
        guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, Int32(size)) == Int32(size) else {
            return 0.0
        }
        
        // Convert to percentage (simplified calculation)
        return Double(info.pti_total_user + info.pti_total_system) / 1000000.0
    }
    
    private func getSystemMemoryPressure() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0.0 }
        
        // Simplified calculation - in real app would use vm_pressure_monitor
        return Double(info.resident_size) / Double(1024 * 1024 * 1024 * 8) // Assume 8GB system
    }
    
    private func getSystemCPUUsage() -> Double {
        // Simplified CPU usage calculation
        // In production, would use host_processor_info
        return 0.1 // Placeholder
    }
    
    // MARK: - Selection Management
    func selectProcess(_ processInfo: ProcessInfo) {
        selectedProcesses.insert(processInfo.id)
    }
    
    func deselectProcess(_ processInfo: ProcessInfo) {
        selectedProcesses.remove(processInfo.id)
    }
    
    func toggleSelection(for processInfo: ProcessInfo) {
        if selectedProcesses.contains(processInfo.id) {
            deselectProcess(processInfo)
        } else {
            selectProcess(processInfo)
        }
    }
    
    func selectAllProcesses() {
        selectedProcesses = Set(processes.map { $0.id })
    }
    
    func deselectAllProcesses() {
        selectedProcesses.removeAll()
    }
    
    // MARK: - Cleanup
    private func cleanup() {
        workspaceObservers.forEach { observer in
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        workspaceObservers.removeAll()
        cancellables.removeAll()
    }
}

// MARK: - System Health Status
enum SystemHealthStatus: String, CaseIterable {
    case normal = "Normal"
    case warning = "Warning"  
    case critical = "Critical"
    
    var color: NSColor {
        switch self {
        case .normal: return NSColor.systemGreen
        case .warning: return NSColor.systemOrange
        case .critical: return NSColor.systemRed
        }
    }
}

// MARK: - Process Cache Actor
actor ProcessCache {
    private var cache: [pid_t: ProcessInfo] = [:]
    private let maxAge: TimeInterval = 30.0
    private var lastCleanup: Date = Date()
    
    func store(_ processInfo: ProcessInfo) {
        cache[processInfo.pid] = processInfo
    }
    
    func retrieve(pid: pid_t) -> ProcessInfo? {
        return cache[pid]
    }
    
    func cleanup() {
        let now = Date()
        if now.timeIntervalSince(lastCleanup) > maxAge {
            // Remove stale entries (simplified)
            cache.removeAll()
            lastCleanup = now
        }
    }
}