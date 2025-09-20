import Foundation
import OSLog
import Combine
import AppKit

// SWARM 2.0 ForceQUIT - Ultra-Efficient System State Manager
// Memory-optimized system monitoring with <500KB footprint

@MainActor
class SystemStateManager: ObservableObject {
    static let shared = SystemStateManager()
    
    // MARK: - Published Properties  
    @Published var systemPerformance: SystemPerformance = SystemPerformance()
    @Published var memoryPressure: MemoryPressureLevel = .normal
    @Published var isLowPowerMode: Bool = false
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.forceQUIT.app", category: "SystemStateManager")
    private var performanceOptimizer: PerformanceOptimizer { PerformanceOptimizer.shared }
    private var cancellables = Set<AnyCancellable>()
    
    // Efficient state tracking
    private var lastUpdateTime: Date = Date()
    private var stateUpdateInterval: TimeInterval = 3.0 // Adaptive interval
    private var systemStateTimer: Timer?
    
    private init() {
        startSystemMonitoring()
        setupPerformanceIntegration()
    }
    
    // MARK: - System Monitoring
    private func startSystemMonitoring() {
        // Start with low-frequency monitoring
        startSystemStateTimer()
        
        // React to memory pressure notifications
        setupMemoryPressureHandling()
        
        logger.info("System state monitoring initialized with adaptive intervals")
    }
    
    private func startSystemStateTimer() {
        systemStateTimer?.invalidate()
        systemStateTimer = Timer.scheduledTimer(withTimeInterval: stateUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateSystemState()
            }
        }
    }
    
    private func setupMemoryPressureHandling() {
        // Listen for system memory pressure notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NSProcessInfoThermalStateDidChangeNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleThermalStateChange()
            }
        }
    }
    
    private func setupPerformanceIntegration() {
        // Monitor performance optimizer state for adaptive behavior
        performanceOptimizer.$isMemoryOptimizationActive
            .sink { [weak self] isOptimizing in
                Task { @MainActor in
                    await self?.adjustMonitoringFrequency(forMemoryOptimization: isOptimizing)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - State Updates
    private func updateSystemState() async {
        let startTime = Date()
        
        // Update system performance metrics efficiently
        await updateSystemPerformanceMetrics()
        
        // Update memory pressure level
        await updateMemoryPressureLevel()
        
        // Check for low power mode
        updateLowPowerMode()
        
        // Adaptive interval adjustment based on update time
        let updateDuration = Date().timeIntervalSince(startTime)
        await adjustUpdateIntervalBasedOnPerformance(updateDuration)
        
        lastUpdateTime = Date()
    }
    
    private func updateSystemPerformanceMetrics() async {
        var newPerformance = SystemPerformance()
        
        // Efficient memory usage calculation
        newPerformance.memoryUsage = await getSystemMemoryUsage()
        newPerformance.cpuUsage = getSystemCPUUsage()
        newPerformance.activeProcessCount = getActiveProcessCount()
        newPerformance.systemLoad = calculateSystemLoad()
        
        systemPerformance = newPerformance
    }
    
    private func updateMemoryPressureLevel() async {
        let memoryUsage = await getSystemMemoryUsage()
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        let pressureRatio = Double(memoryUsage) / Double(totalMemory)
        
        let newPressureLevel: MemoryPressureLevel
        if pressureRatio > 0.9 {
            newPressureLevel = .critical
        } else if pressureRatio > 0.7 {
            newPressureLevel = .warning
        } else {
            newPressureLevel = .normal
        }
        
        if newPressureLevel != memoryPressure {
            memoryPressure = newPressureLevel
            await reactToMemoryPressureChange(newPressureLevel)
        }
    }
    
    private func updateLowPowerMode() {
        let thermalState = ProcessInfo.processInfo.thermalState
        isLowPowerMode = thermalState == .critical || thermalState == .serious
    }
    
    // MARK: - Efficient System Metrics
    private func getSystemMemoryUsage() async -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? info.resident_size : 0
    }
    
    private func getSystemCPUUsage() -> Double {
        // Ultra-lightweight CPU usage estimation
        let loadAverage = getSystemLoadAverage()
        return min(loadAverage / Double(ProcessInfo.processInfo.processorCount), 1.0)
    }
    
    private func getSystemLoadAverage() -> Double {
        var loadAvg: [Double] = [0.0, 0.0, 0.0]
        let result = getloadavg(&loadAvg, 3)
        return result > 0 ? loadAvg[0] : 0.0
    }
    
    private func getActiveProcessCount() -> Int {
        // Estimate based on workspace applications (lightweight)
        return NSWorkspace.shared.runningApplications.count
    }
    
    private func calculateSystemLoad() -> SystemLoad {
        let cpuUsage = systemPerformance.cpuUsage
        let memoryPressureValue = memoryPressure.numericValue
        
        let averageLoad = (cpuUsage + memoryPressureValue) / 2.0
        
        if averageLoad > 0.8 { return .high }
        if averageLoad > 0.5 { return .medium }
        return .low
    }
    
    // MARK: - Adaptive Behavior
    private func adjustMonitoringFrequency(forMemoryOptimization isOptimizing: Bool) async {
        let newInterval: TimeInterval = isOptimizing ? 5.0 : 3.0
        
        if abs(stateUpdateInterval - newInterval) > 0.1 {
            stateUpdateInterval = newInterval
            startSystemStateTimer()
            logger.info("Adjusted monitoring interval to \\(newInterval)s")
        }
    }
    
    private func adjustUpdateIntervalBasedOnPerformance(_ updateDuration: TimeInterval) async {
        // If updates are taking too long, reduce frequency
        if updateDuration > 0.1 && stateUpdateInterval < 5.0 {
            stateUpdateInterval = min(stateUpdateInterval + 0.5, 5.0)
            startSystemStateTimer()
            logger.warning("Increased update interval due to slow performance")
        }
    }
    
    private func reactToMemoryPressureChange(_ newLevel: MemoryPressureLevel) async {
        switch newLevel {
        case .critical:
            logger.critical("Critical memory pressure detected")
            await performanceOptimizer.enableEmergencyOptimization()
            stateUpdateInterval = 5.0 // Reduce monitoring frequency
            
        case .warning:
            logger.warning("Memory pressure warning")
            await performanceOptimizer.enableMemoryOptimization()
            stateUpdateInterval = 4.0
            
        case .normal:
            logger.info("Memory pressure normalized")
            stateUpdateInterval = 3.0
        }
        
        startSystemStateTimer()
    }
    
    private func handleThermalStateChange() async {
        let thermalState = ProcessInfo.processInfo.thermalState
        
        switch thermalState {
        case .critical, .serious:
            logger.warning("Thermal throttling detected - enabling low power mode")
            await performanceOptimizer.enableLowPowerMode()
            
        case .nominal, .fair:
            logger.info("Thermal state normalized")
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Public Interface
    func forceSystemStateUpdate() async {
        await updateSystemState()
    }
    
    func getSystemHealthSummary() -> SystemHealthSummary {
        return SystemHealthSummary(
            overallHealth: calculateOverallHealth(),
            memoryPressure: memoryPressure,
            systemLoad: systemPerformance.systemLoad,
            isLowPowerMode: isLowPowerMode,
            activeProcessCount: systemPerformance.activeProcessCount
        )
    }
    
    private func calculateOverallHealth() -> SystemHealth {
        let factors: [Double] = [
            systemPerformance.cpuUsage,
            memoryPressure.numericValue,
            systemPerformance.systemLoad.numericValue
        ]
        
        let averageStress = factors.reduce(0, +) / Double(factors.count)
        
        if averageStress > 0.8 { return .critical }
        if averageStress > 0.6 { return .warning }
        if averageStress > 0.4 { return .fair }
        return .excellent
    }
    
    deinit {
        systemStateTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - Supporting Types
struct SystemPerformance {
    var memoryUsage: UInt64 = 0
    var cpuUsage: Double = 0.0
    var activeProcessCount: Int = 0
    var systemLoad: SystemLoad = .low
    
    var memoryUsageFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        return formatter.string(fromByteCount: Int64(memoryUsage))
    }
    
    var cpuUsageFormatted: String {
        return String(format: "%.1f%%", cpuUsage * 100)
    }
}

enum MemoryPressureLevel: String, CaseIterable {
    case normal = "Normal"
    case warning = "Warning"  
    case critical = "Critical"
    
    var numericValue: Double {
        switch self {
        case .normal: return 0.0
        case .warning: return 0.7
        case .critical: return 0.9
        }
    }
    
    var color: NSColor {
        switch self {
        case .normal: return NSColor.systemGreen
        case .warning: return NSColor.systemOrange
        case .critical: return NSColor.systemRed
        }
    }
}

enum SystemLoad: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var numericValue: Double {
        switch self {
        case .low: return 0.2
        case .medium: return 0.5
        case .high: return 0.8
        }
    }
}

enum SystemHealth: String, CaseIterable {
    case excellent = "Excellent"
    case fair = "Fair"
    case warning = "Warning"
    case critical = "Critical"
    
    var color: NSColor {
        switch self {
        case .excellent: return NSColor.systemGreen
        case .fair: return NSColor.systemBlue
        case .warning: return NSColor.systemOrange
        case .critical: return NSColor.systemRed
        }
    }
}

struct SystemHealthSummary {
    let overallHealth: SystemHealth
    let memoryPressure: MemoryPressureLevel
    let systemLoad: SystemLoad
    let isLowPowerMode: Bool
    let activeProcessCount: Int
    let timestamp: Date = Date()
}