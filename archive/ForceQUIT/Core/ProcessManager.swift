import Foundation
import AppKit
import Combine
import OSLog

// SWARM 2.0 ForceQUIT - Core Process Management System
// Clean architecture pattern with dependency injection support

@MainActor
class ProcessManager: ObservableObject {
    // MARK: - Published Properties
    @Published var runningProcesses: [ProcessInfo] = []
    @Published var systemMetrics: SystemMetrics = SystemMetrics()
    @Published var isMonitoring: Bool = false
    @Published var lastScanTime: Date = Date()
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.forceQUIT.core", category: "ProcessManager")
    private var workspaceObservers: [NSObjectProtocol] = []
    private var cancellables = Set<AnyCancellable>()
    private let processCache = ProcessCache()
    private let securityValidator = SecurityValidator()
    private let performanceOptimizer = PerformanceOptimizer.shared
    
    // MARK: - Configuration
    private let config = ProcessManagerConfig()
    
    init() {
        setupEventDrivenMonitoring()
        startInitialScan()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Interface
    
    /// Start monitoring system processes with event-driven architecture
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        logger.info("Process monitoring started")
        
        // Initial scan
        Task {
            await performFullScan()
        }
    }
    
    /// Stop all monitoring activities and cleanup
    func stopMonitoring() {
        isMonitoring = false
        cleanup()
        logger.info("Process monitoring stopped")
    }
    
    /// Refresh process list on-demand
    func refreshProcessList() async {
        await performFullScan()
    }
    
    /// Force quit a specific process
    func forceQuitProcess(_ processInfo: ProcessInfo) async -> ProcessTerminationResult {
        logger.info("Attempting to terminate process: \(processInfo.name) (PID: \(processInfo.pid))")
        
        // Security validation
        let securityCheck = await securityValidator.validateTermination(processInfo)
        guard securityCheck.isAllowed else {
            logger.error("Termination blocked: \(securityCheck.reason)")
            return .securityBlocked(reason: securityCheck.reason)
        }
        
        // Find the running application
        guard let app = NSWorkspace.shared.runningApplications.first(where: { 
            $0.processIdentifier == processInfo.pid 
        }) else {
            logger.error("Process not found: \(processInfo.pid)")
            return .processNotFound
        }
        
        // Attempt graceful termination first
        let gracefulResult = await attemptGracefulTermination(app)
        if gracefulResult.success {
            await updateProcessList(after: .termination(processInfo.pid))
            return .success(method: .graceful)
        }
        
        // Force termination if graceful fails
        let forceResult = await attemptForceTermination(app)
        await updateProcessList(after: .termination(processInfo.pid))
        
        return forceResult.success ? .success(method: .force) : .failed(error: forceResult.error)
    }
    
    /// Get current system performance metrics
    func getCurrentSystemMetrics() async -> SystemMetrics {
        return await SystemMetricsCollector.collect()
    }
    
    /// Get detailed process information including resource usage
    func getDetailedProcessInfo(for pid: pid_t) async -> DetailedProcessInfo? {
        return await ProcessInfoCollector.getDetailedInfo(for: pid)
    }
    
    // MARK: - Private Implementation
    
    private func setupEventDrivenMonitoring() {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        
        // Application lifecycle observers
        let launchObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { await self?.handleApplicationLaunched(notification) }
        }
        
        let terminateObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { await self?.handleApplicationTerminated(notification) }
        }
        
        let activateObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { await self?.handleApplicationActivated(notification) }
        }
        
        workspaceObservers = [launchObserver, terminateObserver, activateObserver]
        
        // System metrics monitoring
        Timer.publish(every: config.metricsUpdateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.updateSystemMetrics() }
            }
            .store(in: &cancellables)
    }
    
    private func startInitialScan() {
        Task {
            await performFullScan()
        }
    }
    
    private func performFullScan() async {
        logger.debug("Performing full process scan")
        
        let apps = NSWorkspace.shared.runningApplications
            .filter { !config.shouldExcludeProcess($0) }
        
        var processInfos: [ProcessInfo] = []
        
        for app in apps {
            if let processInfo = await createProcessInfo(from: app) {
                processInfos.append(processInfo)
                await processCache.store(processInfo)
            }
        }
        
        runningProcesses = processInfos.sorted { $0.name < $1.name }
        lastScanTime = Date()
        
        await updateSystemMetrics()
        
        logger.info("Process scan completed: \(processInfos.count) applications found")
    }
    
    private func createProcessInfo(from app: NSRunningApplication) async -> ProcessInfo? {
        // Check if this is a protected system process
        if securityValidator.isProtectedProcess(app) {
            return nil
        }
        
        let resourceInfo = await ProcessResourceCollector.collect(for: app.processIdentifier)
        let securityLevel = securityValidator.determineSecurityLevel(for: app)
        let safeRestartCapability = await SafeRestartCapabilityChecker.check(app)
        
        return ProcessInfo(
            id: app.processIdentifier,
            pid: app.processIdentifier,
            name: app.localizedName ?? app.bundleIdentifier ?? "Unknown",
            bundleIdentifier: app.bundleIdentifier,
            icon: app.icon,
            isActive: app.isActive,
            securityLevel: securityLevel,
            canSafelyRestart: safeRestartCapability,
            memoryUsage: resourceInfo.memoryUsage,
            cpuUsage: resourceInfo.cpuUsage
        )
    }
    
    private func attemptGracefulTermination(_ app: NSRunningApplication) async -> TerminationResult {
        return await withCheckedContinuation { continuation in
            let success = app.terminate()
            
            // Give the app time to close gracefully
            DispatchQueue.main.asyncAfter(deadline: .now() + config.gracefulTerminationTimeout) {
                continuation.resume(returning: TerminationResult(
                    success: success,
                    error: success ? nil : "Graceful termination failed"
                ))
            }
        }
    }
    
    private func attemptForceTermination(_ app: NSRunningApplication) async -> TerminationResult {
        return await withCheckedContinuation { continuation in
            let success = app.forceTerminate()
            continuation.resume(returning: TerminationResult(
                success: success,
                error: success ? nil : "Force termination failed"
            ))
        }
    }
    
    private func updateSystemMetrics() async {
        systemMetrics = await getCurrentSystemMetrics()
    }
    
    private func updateProcessList(after event: ProcessEvent) async {
        switch event {
        case .launch(let pid):
            // Process already handled by event observer
            break
        case .termination(let pid):
            runningProcesses.removeAll { $0.pid == pid }
            await processCache.remove(pid: pid)
        case .activation(let pid):
            if let index = runningProcesses.firstIndex(where: { $0.pid == pid }) {
                runningProcesses[index] = runningProcesses[index].updatingActiveState(isActive: true)
            }
        }
        
        lastScanTime = Date()
    }
    
    // MARK: - Event Handlers
    
    private func handleApplicationLaunched(_ notification: Notification) async {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              isMonitoring else { return }
        
        if let processInfo = await createProcessInfo(from: app) {
            runningProcesses.append(processInfo)
            runningProcesses.sort { $0.name < $1.name }
            await processCache.store(processInfo)
            
            logger.info("New application detected: \(processInfo.name)")
        }
    }
    
    private func handleApplicationTerminated(_ notification: Notification) async {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              isMonitoring else { return }
        
        await updateProcessList(after: .termination(app.processIdentifier))
        logger.info("Application terminated: PID \(app.processIdentifier)")
    }
    
    private func handleApplicationActivated(_ notification: Notification) async {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              isMonitoring else { return }
        
        await updateProcessList(after: .activation(app.processIdentifier))
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        workspaceObservers.forEach { observer in
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        workspaceObservers.removeAll()
        cancellables.removeAll()
        
        Task {
            await processCache.clear()
        }
    }
}

// MARK: - Supporting Types

struct ProcessManagerConfig {
    let metricsUpdateInterval: TimeInterval = 5.0
    let gracefulTerminationTimeout: TimeInterval = 3.0
    let excludedBundleIdentifiers: Set<String> = [
        "com.apple.finder",
        "com.apple.dock",
        "com.apple.systemuiserver",
        "com.forceQUIT.app"
    ]
    
    func shouldExcludeProcess(_ app: NSRunningApplication) -> Bool {
        guard let bundleId = app.bundleIdentifier else { return false }
        return excludedBundleIdentifiers.contains(bundleId)
    }
}

struct SystemMetrics {
    var memoryPressure: Double = 0.0
    var cpuUsage: Double = 0.0
    var processCount: Int = 0
    var timestamp: Date = Date()
    
    var healthStatus: SystemHealthStatus {
        if processCount > 100 || memoryPressure > 0.9 || cpuUsage > 0.8 {
            return .critical
        } else if processCount > 50 || memoryPressure > 0.7 || cpuUsage > 0.6 {
            return .warning
        } else {
            return .normal
        }
    }
}

struct DetailedProcessInfo {
    let processInfo: ProcessInfo
    let threads: Int
    let fileDescriptors: Int
    let networkConnections: Int
    let parentProcessID: pid_t?
    let launchTime: Date
    let memoryBreakdown: MemoryBreakdown
    
    struct MemoryBreakdown {
        let resident: UInt64
        let virtual: UInt64
        let shared: UInt64
        let compressed: UInt64
    }
}

enum ProcessTerminationResult {
    case success(method: TerminationMethod)
    case failed(error: String)
    case securityBlocked(reason: String)
    case processNotFound
    
    enum TerminationMethod {
        case graceful
        case force
    }
}

private struct TerminationResult {
    let success: Bool
    let error: String?
}

private enum ProcessEvent {
    case launch(pid_t)
    case termination(pid_t)
    case activation(pid_t)
}

// MARK: - Process Cache Actor

actor ProcessCache {
    private var cache: [pid_t: ProcessInfo] = [:]
    private let maxCacheSize = 200
    
    func store(_ processInfo: ProcessInfo) {
        cache[processInfo.pid] = processInfo
        
        // Cleanup if cache gets too large
        if cache.count > maxCacheSize {
            let oldestKeys = cache.keys.shuffled().prefix(cache.count - maxCacheSize)
            for key in oldestKeys {
                cache.removeValue(forKey: key)
            }
        }
    }
    
    func retrieve(pid: pid_t) -> ProcessInfo? {
        return cache[pid]
    }
    
    func remove(pid: pid_t) {
        cache.removeValue(forKey: pid)
    }
    
    func clear() {
        cache.removeAll()
    }
}

// MARK: - Security Validator

private class SecurityValidator {
    private let protectedProcesses: Set<String> = [
        "kernel_task", "launchd", "loginwindow", "WindowServer",
        "securityd", "systemuiserver", "coreauthd"
    ]
    
    func isProtectedProcess(_ app: NSRunningApplication) -> Bool {
        if let bundleId = app.bundleIdentifier {
            if protectedProcesses.contains(bundleId) {
                return true
            }
            
            // System processes from Apple
            if bundleId.starts(with: "com.apple.") && 
               (bundleId.contains("system") || bundleId.contains("core")) {
                return true
            }
        }
        
        return false
    }
    
    func determineSecurityLevel(for app: NSRunningApplication) -> ProcessInfo.SecurityLevel {
        guard let bundleId = app.bundleIdentifier else { return .medium }
        
        if bundleId.starts(with: "com.apple.") {
            return .high
        } else if app.isAgent {
            return .medium
        } else {
            return .low
        }
    }
    
    func validateTermination(_ processInfo: ProcessInfo) async -> SecurityValidationResult {
        // Check if process is critical system component
        if processInfo.securityLevel == .high {
            return SecurityValidationResult(
                isAllowed: false,
                reason: "Cannot terminate system processes"
            )
        }
        
        // Additional runtime security checks could go here
        return SecurityValidationResult(isAllowed: true, reason: "")
    }
}

private struct SecurityValidationResult {
    let isAllowed: Bool
    let reason: String
}

// MARK: - Resource Collection Utilities

private struct ProcessResourceCollector {
    static func collect(for pid: pid_t) async -> ResourceInfo {
        let memoryUsage = getMemoryUsage(for: pid)
        let cpuUsage = getCPUUsage(for: pid)
        
        return ResourceInfo(
            memoryUsage: memoryUsage,
            cpuUsage: cpuUsage
        )
    }
    
    private static func getMemoryUsage(for pid: pid_t) -> UInt64 {
        var info = proc_taskinfo()
        let size = MemoryLayout<proc_taskinfo>.size
        
        guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, Int32(size)) == Int32(size) else {
            return 0
        }
        
        return info.pti_resident_size
    }
    
    private static func getCPUUsage(for pid: pid_t) -> Double {
        var info = proc_taskinfo()
        let size = MemoryLayout<proc_taskinfo>.size
        
        guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, Int32(size)) == Int32(size) else {
            return 0.0
        }
        
        return Double(info.pti_total_user + info.pti_total_system) / 1_000_000.0
    }
}

private struct ResourceInfo {
    let memoryUsage: UInt64
    let cpuUsage: Double
}

// MARK: - System Metrics Collector

private struct SystemMetricsCollector {
    static func collect() async -> SystemMetrics {
        var metrics = SystemMetrics()
        
        metrics.memoryPressure = await getMemoryPressure()
        metrics.cpuUsage = await getCPUUsage()
        metrics.processCount = NSWorkspace.shared.runningApplications.count
        metrics.timestamp = Date()
        
        return metrics
    }
    
    private static func getMemoryPressure() async -> Double {
        // Simplified memory pressure calculation
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0.0 }
        
        // Estimate system memory usage (simplified)
        return Double(info.resident_size) / Double(8 * 1024 * 1024 * 1024) // Assume 8GB system
    }
    
    private static func getCPUUsage() async -> Double {
        // Placeholder implementation - would use host_processor_info in production
        return 0.1
    }
}

// MARK: - Safe Restart Capability Checker

private struct SafeRestartCapabilityChecker {
    private static let safeRestartCapableApps: Set<String> = [
        "com.apple.Safari",
        "com.apple.TextEdit",
        "com.apple.Preview",
        "com.microsoft.VSCode",
        "com.google.Chrome",
        "com.mozilla.firefox"
    ]
    
    static func check(_ app: NSRunningApplication) async -> Bool {
        guard let bundleId = app.bundleIdentifier else { return false }
        return safeRestartCapableApps.contains(bundleId)
    }
}

// MARK: - Process Info Collector

private struct ProcessInfoCollector {
    static func getDetailedInfo(for pid: pid_t) async -> DetailedProcessInfo? {
        // This would collect detailed process information using system APIs
        // For now, returning nil as a placeholder
        return nil
    }
}