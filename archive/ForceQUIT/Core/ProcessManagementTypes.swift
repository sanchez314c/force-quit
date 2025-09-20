import Foundation
import AppKit
import os.log

/// SWARM 2.0 ForceQUIT - Process Management Supporting Types
/// Comprehensive data structures, enums, and extensions for the process management system
/// Provides unified types across ProcessMonitor, ProcessTerminator, SystemEventHandler, and related components

// MARK: - Process Management Configuration

struct ProcessManagementConfiguration {
    // Monitoring settings
    let monitoringInterval: TimeInterval
    let maxProcessCacheSize: Int
    let enableAdvancedMetrics: Bool
    
    // Termination settings
    let gracefulTerminationTimeout: TimeInterval
    let forcefulTerminationTimeout: TimeInterval
    let maxConcurrentTerminations: Int
    
    // Permission settings
    let requireConfirmationForSystemProcesses: Bool
    let enableElevatedPrivileges: Bool
    let permissionCheckInterval: TimeInterval
    
    // UI settings
    let enableAnimations: Bool
    let darkModeCompatible: Bool
    let showAdvancedOptions: Bool
    
    static let `default` = ProcessManagementConfiguration(
        monitoringInterval: 2.0,
        maxProcessCacheSize: 500,
        enableAdvancedMetrics: true,
        gracefulTerminationTimeout: 10.0,
        forcefulTerminationTimeout: 5.0,
        maxConcurrentTerminations: 5,
        requireConfirmationForSystemProcesses: true,
        enableElevatedPrivileges: false,
        permissionCheckInterval: 60.0,
        enableAnimations: true,
        darkModeCompatible: true,
        showAdvancedOptions: false
    )
}

// MARK: - Process Management State

enum ProcessManagementState: String, CaseIterable {
    case idle = "Idle"
    case monitoring = "Monitoring"
    case terminating = "Terminating"
    case error = "Error"
    case requiresPermissions = "RequiresPermissions"
    
    var description: String {
        switch self {
        case .idle: return "System ready"
        case .monitoring: return "Actively monitoring processes"
        case .terminating: return "Terminating processes"
        case .error: return "System error"
        case .requiresPermissions: return "Additional permissions required"
        }
    }
    
    var systemImage: String {
        switch self {
        case .idle: return "checkmark.circle"
        case .monitoring: return "eye"
        case .terminating: return "stop.circle"
        case .error: return "exclamationmark.triangle"
        case .requiresPermissions: return "lock.shield"
        }
    }
    
    var isActiveState: Bool {
        switch self {
        case .monitoring, .terminating: return true
        case .idle, .error, .requiresPermissions: return false
        }
    }
}

// MARK: - Process Operation Results

struct ProcessOperationResult {
    let processInfo: ProcessInfo
    let operation: ProcessOperation
    let success: Bool
    let error: ProcessOperationError?
    let duration: TimeInterval
    let timestamp: Date
    
    init(processInfo: ProcessInfo, operation: ProcessOperation, success: Bool, error: ProcessOperationError? = nil, duration: TimeInterval = 0) {
        self.processInfo = processInfo
        self.operation = operation
        self.success = success
        self.error = error
        self.duration = duration
        self.timestamp = Date()
    }
}

enum ProcessOperation: String, CaseIterable {
    case monitor = "Monitor"
    case terminate = "Terminate"
    case forceTerminate = "ForceTerminate"
    case restart = "Restart"
    case suspend = "Suspend"
    case resume = "Resume"
    case classify = "Classify"
    
    var systemImage: String {
        switch self {
        case .monitor: return "eye"
        case .terminate: return "stop"
        case .forceTerminate: return "stop.fill"
        case .restart: return "arrow.clockwise"
        case .suspend: return "pause"
        case .resume: return "play"
        case .classify: return "tag"
        }
    }
}

enum ProcessOperationError: Error, LocalizedError {
    case processNotFound
    case insufficientPermissions
    case operationTimeout
    case systemError(String)
    case invalidState
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .processNotFound:
            return "Process not found"
        case .insufficientPermissions:
            return "Insufficient permissions to perform operation"
        case .operationTimeout:
            return "Operation timed out"
        case .systemError(let message):
            return "System error: \(message)"
        case .invalidState:
            return "Invalid process state for operation"
        case .userCancelled:
            return "Operation cancelled by user"
        }
    }
}

// MARK: - Process Statistics and Metrics

struct ProcessStatistics {
    let totalProcesses: Int
    let activeProcesses: Int
    let systemProcesses: Int
    let userProcesses: Int
    let totalMemoryUsage: UInt64
    let averageCPUUsage: Double
    let highImpactProcesses: Int
    let restartableProcesses: Int
    
    var memoryUsageFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(totalMemoryUsage))
    }
    
    var averageCPUUsageFormatted: String {
        return String(format: "%.1f%%", averageCPUUsage * 100)
    }
    
    var systemHealthScore: Double {
        var score: Double = 1.0
        
        // Reduce score for high process count
        if totalProcesses > 200 {
            score *= 0.8
        }
        
        // Reduce score for high memory usage (over 8GB)
        if totalMemoryUsage > 8_589_934_592 {
            score *= 0.7
        }
        
        // Reduce score for high average CPU usage
        if averageCPUUsage > 0.7 {
            score *= 0.6
        }
        
        // Reduce score for many high-impact processes
        if highImpactProcesses > 10 {
            score *= 0.8
        }
        
        return max(0.0, min(1.0, score))
    }
    
    var isSystemHealthy: Bool {
        return systemHealthScore > 0.7
    }
}

// MARK: - Process Management Events

enum ProcessManagementEvent: String {
    case systemStarted = "SystemStarted"
    case systemStopped = "SystemStopped"
    case processDiscovered = "ProcessDiscovered"
    case processLost = "ProcessLost"
    case terminationStarted = "TerminationStarted"
    case terminationCompleted = "TerminationCompleted"
    case permissionRequested = "PermissionRequested"
    case permissionGranted = "PermissionGranted"
    case permissionDenied = "PermissionDenied"
    case errorOccurred = "ErrorOccurred"
    
    var category: EventCategory {
        switch self {
        case .systemStarted, .systemStopped:
            return .system
        case .processDiscovered, .processLost:
            return .process
        case .terminationStarted, .terminationCompleted:
            return .process
        case .permissionRequested, .permissionGranted, .permissionDenied:
            return .user
        case .errorOccurred:
            return .system
        }
    }
}

struct ProcessManagementEventData {
    let event: ProcessManagementEvent
    let timestamp: Date
    let processInfo: ProcessInfo?
    let metadata: [String: Any]
    
    init(event: ProcessManagementEvent, processInfo: ProcessInfo? = nil, metadata: [String: Any] = [:]) {
        self.event = event
        self.timestamp = Date()
        self.processInfo = processInfo
        self.metadata = metadata
    }
}

// MARK: - Process Comparison and Sorting

enum ProcessComparisonCriteria: String, CaseIterable {
    case name = "Name"
    case pid = "PID"
    case memoryUsage = "Memory"
    case cpuUsage = "CPU"
    case securityLevel = "Security"
    case impactScore = "Impact"
    case createdAt = "Created"
    
    var systemImage: String {
        switch self {
        case .name: return "textformat.abc"
        case .pid: return "number"
        case .memoryUsage: return "memorychip"
        case .cpuUsage: return "cpu"
        case .securityLevel: return "shield"
        case .impactScore: return "gauge"
        case .createdAt: return "clock"
        }
    }
    
    func compare(_ lhs: ProcessInfo, _ rhs: ProcessInfo) -> ComparisonResult {
        switch self {
        case .name:
            return lhs.name.compare(rhs.name)
        case .pid:
            return lhs.pid < rhs.pid ? .orderedAscending : 
                   lhs.pid > rhs.pid ? .orderedDescending : .orderedSame
        case .memoryUsage:
            return lhs.memoryUsage < rhs.memoryUsage ? .orderedAscending :
                   lhs.memoryUsage > rhs.memoryUsage ? .orderedDescending : .orderedSame
        case .cpuUsage:
            return lhs.cpuUsage < rhs.cpuUsage ? .orderedAscending :
                   lhs.cpuUsage > rhs.cpuUsage ? .orderedDescending : .orderedSame
        case .securityLevel:
            let lhsLevel = SecurityLevelRank(lhs.securityLevel)
            let rhsLevel = SecurityLevelRank(rhs.securityLevel)
            return lhsLevel < rhsLevel ? .orderedAscending :
                   lhsLevel > rhsLevel ? .orderedDescending : .orderedSame
        case .impactScore:
            return lhs.systemImpactScore < rhs.systemImpactScore ? .orderedAscending :
                   lhs.systemImpactScore > rhs.systemImpactScore ? .orderedDescending : .orderedSame
        case .createdAt:
            return lhs.createdAt.compare(rhs.createdAt)
        }
    }
    
    private func SecurityLevelRank(_ level: ProcessInfo.SecurityLevel) -> Int {
        switch level {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }
}

// MARK: - Process Filtering

struct ProcessFilter {
    let securityLevels: Set<ProcessInfo.SecurityLevel>
    let categories: Set<ProcessCategory>
    let showOnlyActive: Bool
    let showOnlyRestartable: Bool
    let showOnlyHighImpact: Bool
    let searchText: String
    let minimumMemoryUsage: UInt64
    let minimumCPUUsage: Double
    
    static let showAll = ProcessFilter(
        securityLevels: Set(ProcessInfo.SecurityLevel.allCases),
        categories: Set(ProcessCategory.allCases),
        showOnlyActive: false,
        showOnlyRestartable: false,
        showOnlyHighImpact: false,
        searchText: "",
        minimumMemoryUsage: 0,
        minimumCPUUsage: 0.0
    )
    
    func matches(_ processInfo: ProcessInfo, category: ProcessCategory) -> Bool {
        // Security level filter
        if !securityLevels.contains(processInfo.securityLevel) {
            return false
        }
        
        // Category filter
        if !categories.contains(category) {
            return false
        }
        
        // Active state filter
        if showOnlyActive && !processInfo.isActive {
            return false
        }
        
        // Restartable filter
        if showOnlyRestartable && !processInfo.canSafelyRestart {
            return false
        }
        
        // High impact filter
        if showOnlyHighImpact && !processInfo.isForceQuitCandidate {
            return false
        }
        
        // Search text filter
        if !searchText.isEmpty {
            let searchTextLower = searchText.lowercased()
            let nameMatch = processInfo.name.lowercased().contains(searchTextLower)
            let bundleIdMatch = processInfo.bundleIdentifier?.lowercased().contains(searchTextLower) ?? false
            
            if !nameMatch && !bundleIdMatch {
                return false
            }
        }
        
        // Resource usage filters
        if processInfo.memoryUsage < minimumMemoryUsage {
            return false
        }
        
        if processInfo.cpuUsage < minimumCPUUsage {
            return false
        }
        
        return true
    }
}

// MARK: - Process Group Operations

struct ProcessGroup {
    let name: String
    let processes: [ProcessInfo]
    let category: ProcessCategory?
    let securityLevel: ProcessInfo.SecurityLevel?
    
    var totalMemoryUsage: UInt64 {
        processes.reduce(0) { $0 + $1.memoryUsage }
    }
    
    var averageCPUUsage: Double {
        guard !processes.isEmpty else { return 0.0 }
        return processes.reduce(0) { $0 + $1.cpuUsage } / Double(processes.count)
    }
    
    var canTerminateAll: Bool {
        processes.allSatisfy { $0.securityLevel != .high }
    }
    
    var canRestartAll: Bool {
        processes.allSatisfy { $0.canSafelyRestart }
    }
}

// MARK: - Performance Monitoring

struct PerformanceMetrics {
    let timestamp: Date
    let processCount: Int
    let memoryPressure: MemoryPressureLevel
    let cpuPressure: CPUPressureLevel
    let averageUpdateTime: TimeInterval
    let cacheHitRate: Double
    
    var overallPerformance: PerformanceLevel {
        var score: Double = 1.0
        
        // Memory pressure impact
        switch memoryPressure {
        case .normal: score *= 1.0
        case .elevated: score *= 0.8
        case .high: score *= 0.6
        case .critical: score *= 0.4
        }
        
        // CPU pressure impact
        switch cpuPressure {
        case .normal: score *= 1.0
        case .elevated: score *= 0.8
        case .high: score *= 0.6
        case .critical: score *= 0.4
        }
        
        // Update time impact
        if averageUpdateTime > 0.5 {
            score *= 0.7
        }
        
        // Cache efficiency impact
        if cacheHitRate < 0.8 {
            score *= 0.8
        }
        
        if score > 0.8 { return .excellent }
        if score > 0.6 { return .good }
        if score > 0.4 { return .poor }
        return .critical
    }
}

enum MemoryPressureLevel: String, CaseIterable {
    case normal = "Normal"
    case elevated = "Elevated"
    case high = "High"
    case critical = "Critical"
    
    var systemImage: String {
        switch self {
        case .normal: return "memorychip"
        case .elevated: return "memorychip.fill"
        case .high: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.octagon"
        }
    }
    
    var color: NSColor {
        switch self {
        case .normal: return .systemGreen
        case .elevated: return .systemYellow
        case .high: return .systemOrange
        case .critical: return .systemRed
        }
    }
}

enum CPUPressureLevel: String, CaseIterable {
    case normal = "Normal"
    case elevated = "Elevated"
    case high = "High" 
    case critical = "Critical"
    
    var systemImage: String {
        switch self {
        case .normal: return "cpu"
        case .elevated: return "cpu.fill"
        case .high: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.octagon"
        }
    }
    
    var color: NSColor {
        switch self {
        case .normal: return .systemGreen
        case .elevated: return .systemYellow
        case .high: return .systemOrange
        case .critical: return .systemRed
        }
    }
}

enum PerformanceLevel: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case poor = "Poor"
    case critical = "Critical"
    
    var systemImage: String {
        switch self {
        case .excellent: return "checkmark.circle.fill"
        case .good: return "checkmark.circle"
        case .poor: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
    
    var color: NSColor {
        switch self {
        case .excellent: return .systemGreen
        case .good: return .systemYellow
        case .poor: return .systemOrange
        case .critical: return .systemRed
        }
    }
}

// MARK: - Extensions

extension Array where Element == ProcessInfo {
    
    func sorted(by criteria: ProcessComparisonCriteria, ascending: Bool = true) -> [ProcessInfo] {
        let sorted = self.sorted { lhs, rhs in
            let result = criteria.compare(lhs, rhs)
            return result == .orderedAscending
        }
        
        return ascending ? sorted : sorted.reversed()
    }
    
    func filtered(by filter: ProcessFilter, categoryProvider: (ProcessInfo) -> ProcessCategory) -> [ProcessInfo] {
        return self.filter { processInfo in
            let category = categoryProvider(processInfo)
            return filter.matches(processInfo, category: category)
        }
    }
    
    func groupedBy(criteria: ProcessComparisonCriteria) -> [String: [ProcessInfo]] {
        return Dictionary(grouping: self) { processInfo in
            switch criteria {
            case .securityLevel:
                return processInfo.securityLevel.rawValue
            case .name:
                return String(processInfo.name.prefix(1)).uppercased()
            case .memoryUsage:
                let mb = processInfo.memoryUsage / (1024 * 1024)
                if mb < 50 { return "< 50 MB" }
                if mb < 200 { return "50-200 MB" }
                if mb < 500 { return "200-500 MB" }
                return "> 500 MB"
            case .cpuUsage:
                if processInfo.cpuUsage < 0.1 { return "Low" }
                if processInfo.cpuUsage < 0.5 { return "Medium" }
                return "High"
            default:
                return "Other"
            }
        }
    }
    
    func statistics() -> ProcessStatistics {
        let totalProcesses = count
        let activeProcesses = filter(\.isActive).count
        let systemProcesses = filter { $0.securityLevel == .high }.count
        let userProcesses = filter { $0.securityLevel == .low }.count
        let totalMemoryUsage = reduce(0) { $0 + $1.memoryUsage }
        let averageCPUUsage = isEmpty ? 0.0 : reduce(0) { $0 + $1.cpuUsage } / Double(count)
        let highImpactProcesses = filter(\.isForceQuitCandidate).count
        let restartableProcesses = filter(\.canSafelyRestart).count
        
        return ProcessStatistics(
            totalProcesses: totalProcesses,
            activeProcesses: activeProcesses,
            systemProcesses: systemProcesses,
            userProcesses: userProcesses,
            totalMemoryUsage: totalMemoryUsage,
            averageCPUUsage: averageCPUUsage,
            highImpactProcesses: highImpactProcesses,
            restartableProcesses: restartableProcesses
        )
    }
}

extension ProcessInfo.SecurityLevel {
    var priority: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let processManagementStateChanged = Notification.Name("ProcessManagementStateChanged")
    static let processOperationCompleted = Notification.Name("ProcessOperationCompleted")
    static let systemHealthChanged = Notification.Name("SystemHealthChanged")
    static let permissionStatusChanged = Notification.Name("PermissionStatusChanged")
}