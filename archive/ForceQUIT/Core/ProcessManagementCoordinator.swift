import Foundation
import AppKit
import os.log
import Combine

/// SWARM 2.0 ForceQUIT - Process Management Coordinator
/// Master coordinator that integrates all process management components
/// Provides unified interface and orchestrates complex operations

@MainActor
class ProcessManagementCoordinator: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var state: ProcessManagementState = .idle
    @Published private(set) var processes: [ProcessInfo] = []
    @Published private(set) var systemStatistics: ProcessStatistics?
    @Published private(set) var performanceMetrics: PerformanceMetrics?
    @Published private(set) var recentOperations: [ProcessOperationResult] = []
    @Published private(set) var systemHealthScore: Double = 1.0
    
    // MARK: - Components
    private let processMonitor: ProcessMonitor
    private let processTerminator: ProcessTerminator
    private let systemEventHandler: SystemEventHandler
    private let permissionManager: PermissionManager
    private let processClassifier: ProcessClassifier
    
    // MARK: - Configuration
    private let configuration: ProcessManagementConfiguration
    private let logger = Logger(subsystem: "com.forcequit.app", category: "ProcessManagementCoordinator")
    
    // MARK: - Internal State
    private var cancellables = Set<AnyCancellable>()
    private var operationHistory: [ProcessOperationResult] = []
    private let maxOperationHistory = 1000
    
    // Performance tracking
    private var lastStatisticsUpdate = Date()
    private var statisticsUpdateTimer: Timer?
    
    // MARK: - Initialization
    init(configuration: ProcessManagementConfiguration = .default) {
        self.configuration = configuration
        
        // Initialize components
        self.processMonitor = ProcessMonitor()
        self.processTerminator = ProcessTerminator()
        self.systemEventHandler = SystemEventHandler()
        self.permissionManager = PermissionManager()
        self.processClassifier = ProcessClassifier.shared
        
        setupBindings()
        setupPerformanceMonitoring()
        
        logger.info("ProcessManagementCoordinator initialized with configuration")
    }
    
    deinit {
        statisticsUpdateTimer?.invalidate()
        stopAllOperations()
    }
    
    // MARK: - Public Interface
    
    /// Start the process management system
    func start() async throws {
        logger.info("Starting process management system")
        
        // Check and request necessary permissions
        let permissionResult = await permissionManager.requestPermissions([
            .processTermination, .accessibility, .automation
        ])
        
        guard permissionResult.hasAnyPermissions else {
            state = .requiresPermissions
            throw ProcessOperationError.insufficientPermissions
        }
        
        // Start monitoring
        processMonitor.startMonitoring()
        
        // Start system event handling
        systemEventHandler.startMonitoring { [weak self] event in
            Task { @MainActor in
                self?.handleSystemEvent(event)
            }
        }
        
        // Update state
        state = .monitoring
        
        // Send startup notification
        NotificationCenter.default.post(
            name: .processManagementStateChanged,
            object: self,
            userInfo: ["state": state]
        )
        
        logger.info("Process management system started successfully")
    }
    
    /// Stop the process management system
    func stop() {
        logger.info("Stopping process management system")
        
        stopAllOperations()
        
        state = .idle
        
        NotificationCenter.default.post(
            name: .processManagementStateChanged,
            object: self,
            userInfo: ["state": state]
        )
        
        logger.info("Process management system stopped")
    }
    
    /// Terminate a single process with intelligent strategy selection
    func terminateProcess(_ processInfo: ProcessInfo) async -> ProcessOperationResult {
        logger.info("Initiating process termination: \(processInfo.name, privacy: .public)")
        
        let startTime = Date()
        state = .terminating
        
        // Get termination recommendation from classifier
        if let app = getRunningApplication(for: processInfo) {
            let recommendation = processClassifier.getTerminationRecommendation(for: app)
            
            // Execute termination with recommended strategy
            let terminationResult = await processTerminator.terminateProcess(processInfo, strategy: recommendation.strategy)
            
            // Record the attempt for learning
            processClassifier.recordTerminationAttempt(
                bundleId: processInfo.bundleIdentifier,
                name: processInfo.name,
                success: terminationResult.success,
                method: recommendation.strategy.rawValue
            )
            
            let operationResult = ProcessOperationResult(
                processInfo: processInfo,
                operation: .terminate,
                success: terminationResult.success,
                error: terminationResult.error.map { ProcessOperationError.systemError($0.localizedDescription) },
                duration: Date().timeIntervalSince(startTime)
            )
            
            await recordOperation(operationResult)
            
            state = .monitoring
            
            return operationResult
        } else {
            // Fallback for processes not found in NSRunningApplication
            let operationResult = ProcessOperationResult(
                processInfo: processInfo,
                operation: .terminate,
                success: false,
                error: .processNotFound,
                duration: Date().timeIntervalSince(startTime)
            )
            
            await recordOperation(operationResult)
            state = .monitoring
            
            return operationResult
        }
    }
    
    /// Terminate multiple processes with intelligent batching
    func terminateProcesses(_ processes: [ProcessInfo]) async -> [ProcessOperationResult] {
        logger.info("Initiating batch termination for \(processes.count) processes")
        
        state = .terminating
        
        var results: [ProcessOperationResult] = []
        
        // Group processes by security level for safer batch processing
        let groupedProcesses = Dictionary(grouping: processes) { $0.securityLevel }
        
        // Process in order of increasing risk (low -> medium -> high)
        for securityLevel in [ProcessInfo.SecurityLevel.low, .medium, .high] {
            guard let processesForLevel = groupedProcesses[securityLevel] else { continue }
            
            let batchResults = await processTerminator.terminateProcesses(processesForLevel)
            
            // Convert to ProcessOperationResult
            for terminationResult in batchResults {
                let operationResult = ProcessOperationResult(
                    processInfo: terminationResult.processInfo,
                    operation: .terminate,
                    success: terminationResult.success,
                    error: terminationResult.error.map { ProcessOperationError.systemError($0.localizedDescription) },
                    duration: terminationResult.duration
                )
                
                results.append(operationResult)
                await recordOperation(operationResult)
            }
            
            // Brief pause between security levels
            if securityLevel != .high {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
        
        state = .monitoring
        
        logger.info("Batch termination completed: \(results.filter(\.success).count)/\(results.count) successful")
        
        return results
    }
    
    /// Force quit process bypassing all safety checks
    func emergencyForceQuit(_ processInfo: ProcessInfo) async -> ProcessOperationResult {
        logger.warning("Emergency force quit initiated: \(processInfo.name, privacy: .public)")
        
        let startTime = Date()
        state = .terminating
        
        let terminationResult = await processTerminator.emergencyForceQuit(processInfo)
        
        let operationResult = ProcessOperationResult(
            processInfo: processInfo,
            operation: .forceTerminate,
            success: terminationResult.success,
            error: terminationResult.error.map { ProcessOperationError.systemError($0.localizedDescription) },
            duration: Date().timeIntervalSince(startTime)
        )
        
        await recordOperation(operationResult)
        state = .monitoring
        
        return operationResult
    }
    
    /// Get filtered and sorted processes
    func getProcesses(filter: ProcessFilter = .showAll, 
                     sortBy: ProcessComparisonCriteria = .name,
                     ascending: Bool = true) -> [ProcessInfo] {
        return processes
            .filtered(by: filter) { [weak self] processInfo in
                guard let self = self else { return .other }
                if let app = self.getRunningApplication(for: processInfo) {
                    return self.processClassifier.getProcessCategory(app)
                }
                return .other
            }
            .sorted(by: sortBy, ascending: ascending)
    }
    
    /// Get process groups for organized display
    func getProcessGroups(groupBy: ProcessComparisonCriteria = .securityLevel) -> [ProcessGroup] {
        let grouped = processes.groupedBy(criteria: groupBy)
        
        return grouped.map { key, processes in
            ProcessGroup(
                name: key,
                processes: processes,
                category: nil,
                securityLevel: groupBy == .securityLevel ? ProcessInfo.SecurityLevel(rawValue: key) : nil
            )
        }.sorted { $0.name < $1.name }
    }
    
    /// Refresh system statistics
    func refreshStatistics() {
        let stats = processes.statistics()
        systemStatistics = stats
        systemHealthScore = stats.systemHealthScore
        lastStatisticsUpdate = Date()
        
        // Update performance metrics
        updatePerformanceMetrics()
        
        logger.debug("Statistics refreshed: \(stats.totalProcesses) processes, health score: \(stats.systemHealthScore, privacy: .public)")
    }
    
    /// Get current system access level
    func getSystemAccessLevel() async -> SystemAccessLevel {
        return await permissionManager.checkSystemAccessLevel()
    }
    
    /// Request additional permissions
    func requestPermissions(_ permissions: Set<PermissionType>) async -> PermissionRequestResult {
        return await permissionManager.requestPermissions(permissions)
    }
    
    // MARK: - Private Implementation
    
    private func setupBindings() {
        // Monitor process changes
        processMonitor.$processes
            .receive(on: DispatchQueue.main)
            .assign(to: &$processes)
        
        // Monitor permission changes
        permissionManager.$currentPermissionLevel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] permissionLevel in
                self?.handlePermissionLevelChange(permissionLevel)
            }
            .store(in: &cancellables)
        
        // Monitor system state changes
        systemEventHandler.$systemState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] systemState in
                self?.handleSystemStateChange(systemState)
            }
            .store(in: &cancellables)
        
        // Update statistics when processes change
        processMonitor.$processes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshStatistics()
            }
            .store(in: &cancellables)
    }
    
    private func setupPerformanceMonitoring() {
        statisticsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePerformanceMetrics()
            }
        }
    }
    
    private func stopAllOperations() {
        processMonitor.stopMonitoring()
        systemEventHandler.stopMonitoring()
        statisticsUpdateTimer?.invalidate()
        statisticsUpdateTimer = nil
    }
    
    private func handleSystemEvent(_ event: SystemEvent) {
        logger.debug("System event received: \(event.type.rawValue, privacy: .public)")
        
        // Update system health based on events
        let healthMetrics = systemEventHandler.getSystemHealthMetrics()
        systemHealthScore = healthMetrics.healthScore
        
        // Handle specific events
        switch event.type {
        case .systemWillSleep:
            // Reduce monitoring intensity during sleep
            break
        case .systemDidWake:
            // Refresh everything after wake
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // Wait 2 seconds
                await permissionManager.refreshPermissions()
                refreshStatistics()
            }
        default:
            break
        }
    }
    
    private func handlePermissionLevelChange(_ level: PermissionLevel) {
        logger.info("Permission level changed to: \(level.rawValue, privacy: .public)")
        
        // Update state based on permissions
        if level == .user && state == .requiresPermissions {
            // Still insufficient permissions
            return
        }
        
        if state == .requiresPermissions && level != .user {
            state = .idle
        }
    }
    
    private func handleSystemStateChange(_ systemState: SystemState) {
        logger.debug("System state changed to: \(systemState.rawValue, privacy: .public)")
        
        // Adjust monitoring behavior based on system state
        switch systemState {
        case .busy:
            // Reduce update frequency to avoid system impact
            break
        case .sleeping:
            // Minimal monitoring during sleep
            break
        default:
            // Normal monitoring
            break
        }
    }
    
    private func updatePerformanceMetrics() {
        let processCount = processes.count
        let memoryPressure = calculateMemoryPressure()
        let cpuPressure = calculateCPUPressure()
        let monitorMetrics = processMonitor.performanceMetrics
        
        performanceMetrics = PerformanceMetrics(
            timestamp: Date(),
            processCount: processCount,
            memoryPressure: memoryPressure,
            cpuPressure: cpuPressure,
            averageUpdateTime: monitorMetrics.averageUpdateTime,
            cacheHitRate: monitorMetrics.memoryEfficiency
        )
    }
    
    private func calculateMemoryPressure() -> MemoryPressureLevel {
        guard let stats = systemStatistics else { return .normal }
        
        let totalMemoryGB = Double(stats.totalMemoryUsage) / (1024 * 1024 * 1024)
        
        if totalMemoryGB > 12 { return .critical }
        if totalMemoryGB > 8 { return .high }
        if totalMemoryGB > 4 { return .elevated }
        return .normal
    }
    
    private func calculateCPUPressure() -> CPUPressureLevel {
        guard let stats = systemStatistics else { return .normal }
        
        if stats.averageCPUUsage > 0.8 { return .critical }
        if stats.averageCPUUsage > 0.6 { return .high }
        if stats.averageCPUUsage > 0.4 { return .elevated }
        return .normal
    }
    
    private func recordOperation(_ result: ProcessOperationResult) async {
        recentOperations.insert(result, at: 0)
        
        // Limit recent operations display
        if recentOperations.count > 20 {
            recentOperations = Array(recentOperations.prefix(20))
        }
        
        // Add to full history
        operationHistory.append(result)
        
        // Trim history if needed
        if operationHistory.count > maxOperationHistory {
            operationHistory.removeFirst(operationHistory.count - maxOperationHistory)
        }
        
        // Post notification
        NotificationCenter.default.post(
            name: .processOperationCompleted,
            object: self,
            userInfo: [
                "result": result,
                "success": result.success
            ]
        )
        
        logger.info("Operation recorded: \(result.operation.rawValue) on \(result.processInfo.name, privacy: .public) - \(result.success ? "SUCCESS" : "FAILED")")
    }
    
    private func getRunningApplication(for processInfo: ProcessInfo) -> NSRunningApplication? {
        return NSWorkspace.shared.runningApplications.first { $0.processIdentifier == processInfo.pid }
    }
}

// MARK: - Statistics and Reporting

extension ProcessManagementCoordinator {
    
    /// Get comprehensive system report
    func generateSystemReport() -> SystemReport {
        let systemHealth = systemEventHandler.getSystemHealthMetrics()
        let accessLevel = Task { await getSystemAccessLevel() }
        
        return SystemReport(
            timestamp: Date(),
            systemState: state,
            processStatistics: systemStatistics ?? processes.statistics(),
            performanceMetrics: performanceMetrics,
            systemHealth: systemHealth,
            recentOperations: Array(recentOperations.prefix(10)),
            permissionStatus: permissionManager.permissionStatus,
            systemHealthScore: systemHealthScore
        )
    }
    
    /// Get operation history for analysis
    func getOperationHistory(limit: Int = 100) -> [ProcessOperationResult] {
        return Array(operationHistory.suffix(limit))
    }
    
    /// Get success rate for specific operation type
    func getOperationSuccessRate(operation: ProcessOperation, timeframe: TimeInterval = 3600) -> Double {
        let since = Date().addingTimeInterval(-timeframe)
        let relevantOperations = operationHistory.filter {
            $0.operation == operation && $0.timestamp >= since
        }
        
        guard !relevantOperations.isEmpty else { return 0.0 }
        
        let successfulOperations = relevantOperations.filter(\.success).count
        return Double(successfulOperations) / Double(relevantOperations.count)
    }
}

// MARK: - System Report

struct SystemReport {
    let timestamp: Date
    let systemState: ProcessManagementState
    let processStatistics: ProcessStatistics
    let performanceMetrics: PerformanceMetrics?
    let systemHealth: SystemHealthMetrics
    let recentOperations: [ProcessOperationResult]
    let permissionStatus: [PermissionType: PermissionStatus]
    let systemHealthScore: Double
    
    var overallStatus: SystemStatus {
        if systemHealthScore > 0.8 { return .excellent }
        if systemHealthScore > 0.6 { return .good }
        if systemHealthScore > 0.4 { return .concerning }
        return .critical
    }
}

enum SystemStatus: String {
    case excellent = "Excellent"
    case good = "Good"
    case concerning = "Concerning"
    case critical = "Critical"
    
    var color: NSColor {
        switch self {
        case .excellent: return .systemGreen
        case .good: return .systemYellow
        case .concerning: return .systemOrange
        case .critical: return .systemRed
        }
    }
}