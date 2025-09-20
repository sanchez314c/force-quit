import Foundation
import Combine
import os.log

/// Ultra-lightweight memory manager ensuring ForceQUIT stays under 10MB base / 20MB peak
/// Uses sophisticated memory profiling and automatic optimization strategies
final class MemoryManager: ObservableObject {
    
    // MARK: - Memory Constraints
    private enum MemoryLimits {
        static let baseLimit: UInt64 = 10 * 1024 * 1024      // 10MB base
        static let peakLimit: UInt64 = 20 * 1024 * 1024      // 20MB peak
        static let warningThreshold: UInt64 = 8 * 1024 * 1024 // 8MB warning
        static let criticalThreshold: UInt64 = 18 * 1024 * 1024 // 18MB critical
    }
    
    // MARK: - Memory Status
    enum MemoryStatus {
        case optimal        // < 8MB
        case warning        // 8-10MB
        case approaching    // 10-18MB
        case critical       // 18-20MB
        case exceeded       // > 20MB
        
        var description: String {
            switch self {
            case .optimal: return "Memory usage optimal"
            case .warning: return "Memory usage elevated"
            case .approaching: return "Approaching memory limit"
            case .critical: return "Critical memory usage"
            case .exceeded: return "Memory limit exceeded"
            }
        }
    }
    
    // MARK: - Published Properties
    @Published private(set) var currentUsage: UInt64 = 0
    @Published private(set) var peakUsage: UInt64 = 0
    @Published private(set) var status: MemoryStatus = .optimal
    @Published private(set) var isMonitoringActive: Bool = false
    
    // MARK: - Private Properties
    private var monitoringTimer: Timer?
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    private let logger = Logger(subsystem: "com.forceQUIT.performance", category: "MemoryManager")
    private let queue = DispatchQueue(label: "memory.monitor", qos: .utility)
    
    // Memory pool management
    private var objectPool = MemoryPool()
    private var imageCache = LRUImageCache(maxSize: 2 * 1024 * 1024) // 2MB image cache
    private var stringCache = LRUStringCache(maxSize: 512 * 1024)    // 512KB string cache
    
    // Optimization strategies
    private var optimizationStrategies: [MemoryOptimizationStrategy] = []
    
    // MARK: - Initialization
    init() {
        setupMemoryPressureMonitoring()
        setupOptimizationStrategies()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
        memoryPressureSource?.cancel()
    }
    
    // MARK: - Public Interface
    
    /// Start memory monitoring
    func startMonitoring() {
        guard !isMonitoringActive else { return }
        
        isMonitoringActive = true
        
        // High-frequency monitoring (every 100ms) for precise control
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateMemoryUsage()
        }
        
        logger.info("Memory monitoring started - Base limit: \(MemoryLimits.baseLimit / 1024 / 1024)MB, Peak limit: \(MemoryLimits.peakLimit / 1024 / 1024)MB")
    }
    
    /// Stop memory monitoring
    func stopMonitoring() {
        isMonitoringActive = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        logger.info("Memory monitoring stopped")
    }
    
    /// Force immediate memory optimization
    @MainActor
    func optimizeMemoryNow() async {
        logger.info("Forcing immediate memory optimization")
        
        // Execute all optimization strategies
        for strategy in optimizationStrategies {
            await strategy.optimize()
        }
        
        // Clear caches if needed
        if currentUsage > MemoryLimits.warningThreshold {
            clearCaches()
        }
        
        // Force garbage collection
        forceGarbageCollection()
        
        // Update usage after optimization
        updateMemoryUsage()
    }
    
    /// Register a memory-heavy operation
    func registerMemoryOperation<T>(_ operation: @escaping () throws -> T) rethrows -> T {
        let preOpUsage = getCurrentMemoryUsage()
        
        // Check if we have enough memory
        guard preOpUsage < MemoryLimits.criticalThreshold else {
            logger.warning("Blocking operation - memory usage too high: \(preOpUsage / 1024 / 1024)MB")
            throw MemoryError.insufficientMemory
        }
        
        let result = try operation()
        
        // Check post-operation usage
        let postOpUsage = getCurrentMemoryUsage()
        if postOpUsage > MemoryLimits.peakLimit {
            logger.error("Memory limit exceeded after operation: \(postOpUsage / 1024 / 1024)MB")
            Task { @MainActor in
                await self.optimizeMemoryNow()
            }
        }
        
        return result
    }
    
    // MARK: - Memory Profiling
    
    /// Get detailed memory breakdown
    func getMemoryBreakdown() -> MemoryBreakdown {
        let usage = getCurrentMemoryUsage()
        
        return MemoryBreakdown(
            totalUsage: usage,
            imageCache: imageCache.currentSize,
            stringCache: stringCache.currentSize,
            objectPool: objectPool.currentSize,
            systemOverhead: estimateSystemOverhead(),
            timestamp: Date()
        )
    }
    
    /// Get memory usage trend data for analytics
    func getUsageTrend() -> [MemoryDataPoint] {
        // In production, this would return historical data
        // For now, return current snapshot
        return [MemoryDataPoint(timestamp: Date(), memoryUsage: Double(currentUsage) / 1024 / 1024)]
    }
    
    // MARK: - Private Implementation
    
    private func updateMemoryUsage() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let usage = self.getCurrentMemoryUsage()
            
            DispatchQueue.main.async {
                self.currentUsage = usage
                self.peakUsage = max(self.peakUsage, usage)
                self.updateStatus()
                
                // Trigger optimization if needed
                if usage > MemoryLimits.warningThreshold {
                    Task { @MainActor in
                        await self.handleMemoryPressure()
                    }
                }
            }
        }
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
    
    private func updateStatus() {
        switch currentUsage {
        case 0..<MemoryLimits.warningThreshold:
            status = .optimal
        case MemoryLimits.warningThreshold..<MemoryLimits.baseLimit:
            status = .warning
        case MemoryLimits.baseLimit..<MemoryLimits.criticalThreshold:
            status = .approaching
        case MemoryLimits.criticalThreshold..<MemoryLimits.peakLimit:
            status = .critical
        default:
            status = .exceeded
        }
    }
    
    @MainActor
    private func handleMemoryPressure() async {
        logger.warning("Memory pressure detected: \(currentUsage / 1024 / 1024)MB")
        
        switch status {
        case .optimal:
            break // No action needed
            
        case .warning:
            // Light optimization
            imageCache.trimToSize(1 * 1024 * 1024) // Trim to 1MB
            
        case .approaching:
            // Moderate optimization
            clearCaches()
            objectPool.compact()
            
        case .critical:
            // Aggressive optimization
            await optimizeMemoryNow()
            
        case .exceeded:
            // Emergency optimization
            await emergencyMemoryRecovery()
        }
    }
    
    @MainActor
    private func emergencyMemoryRecovery() async {
        logger.critical("Emergency memory recovery initiated")
        
        // Clear all caches
        imageCache.clear()
        stringCache.clear()
        objectPool.clear()
        
        // Execute all optimization strategies
        for strategy in optimizationStrategies {
            await strategy.emergencyOptimize()
        }
        
        // Force multiple garbage collections
        for _ in 0..<3 {
            forceGarbageCollection()
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        // Final usage check
        updateMemoryUsage()
        
        if currentUsage > MemoryLimits.peakLimit {
            logger.fault("Emergency recovery failed - memory still exceeds limit")
            // In production, might need to gracefully degrade features or exit
        }
    }
    
    private func setupMemoryPressureMonitoring() {
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: queue)
        
        memoryPressureSource?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            let event = self.memoryPressureSource?.mask
            if event?.contains(.critical) == true {
                self.logger.critical("System memory pressure: CRITICAL")
                Task { @MainActor in
                    await self.emergencyMemoryRecovery()
                }
            } else if event?.contains(.warning) == true {
                self.logger.warning("System memory pressure: WARNING")
                Task { @MainActor in
                    await self.handleMemoryPressure()
                }
            }
        }
        
        memoryPressureSource?.resume()
    }
    
    private func setupOptimizationStrategies() {
        optimizationStrategies = [
            ImageOptimizationStrategy(imageCache: imageCache),
            StringOptimizationStrategy(stringCache: stringCache),
            ObjectPoolOptimizationStrategy(objectPool: objectPool)
        ]
    }
    
    private func clearCaches() {
        imageCache.trimToSize(1 * 1024 * 1024) // Keep 1MB
        stringCache.trimToSize(256 * 1024)     // Keep 256KB
    }
    
    private func forceGarbageCollection() {
        // Swift doesn't have explicit GC, but we can help the ARC
        autoreleasepool {
            // Force autoreleasepool drain
        }
    }
    
    private func estimateSystemOverhead() -> UInt64 {
        // Estimate SwiftUI, system frameworks overhead
        return 2 * 1024 * 1024 // ~2MB estimated overhead
    }
}

// MARK: - Supporting Types

enum MemoryError: LocalizedError {
    case insufficientMemory
    case allocationFailed
    
    var errorDescription: String? {
        switch self {
        case .insufficientMemory:
            return "Insufficient memory available"
        case .allocationFailed:
            return "Memory allocation failed"
        }
    }
}

struct MemoryBreakdown {
    let totalUsage: UInt64
    let imageCache: UInt64
    let stringCache: UInt64
    let objectPool: UInt64
    let systemOverhead: UInt64
    let timestamp: Date
    
    var breakdown: [String: UInt64] {
        return [
            "Total": totalUsage,
            "Images": imageCache,
            "Strings": stringCache,
            "Objects": objectPool,
            "System": systemOverhead,
            "Other": totalUsage - (imageCache + stringCache + objectPool + systemOverhead)
        ]
    }
}

struct MemoryDataPoint {
    let timestamp: Date
    let memoryUsage: Double
}

// MARK: - Memory Optimization Strategies

protocol MemoryOptimizationStrategy {
    func optimize() async
    func emergencyOptimize() async
}

class ImageOptimizationStrategy: MemoryOptimizationStrategy {
    private weak var imageCache: LRUImageCache?
    
    init(imageCache: LRUImageCache) {
        self.imageCache = imageCache
    }
    
    func optimize() async {
        await imageCache?.trimToSize(1 * 1024 * 1024) // 1MB
    }
    
    func emergencyOptimize() async {
        await imageCache?.clear()
    }
}

class StringOptimizationStrategy: MemoryOptimizationStrategy {
    private weak var stringCache: LRUStringCache?
    
    init(stringCache: LRUStringCache) {
        self.stringCache = stringCache
    }
    
    func optimize() async {
        await stringCache?.trimToSize(256 * 1024) // 256KB
    }
    
    func emergencyOptimize() async {
        await stringCache?.clear()
    }
}

class ObjectPoolOptimizationStrategy: MemoryOptimizationStrategy {
    private weak var objectPool: MemoryPool?
    
    init(objectPool: MemoryPool) {
        self.objectPool = objectPool
    }
    
    func optimize() async {
        await objectPool?.compact()
    }
    
    func emergencyOptimize() async {
        await objectPool?.clear()
    }
}

// MARK: - Memory Pool Implementation

class MemoryPool {
    private var objects: [AnyObject] = []
    private let lock = NSLock()
    
    var currentSize: UInt64 {
        lock.lock()
        defer { lock.unlock() }
        return UInt64(objects.count * MemoryLayout<AnyObject>.size)
    }
    
    func compact() {
        lock.lock()
        defer { lock.unlock() }
        objects.removeAll(keepingCapacity: false)
    }
    
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        objects.removeAll()
    }
}

// MARK: - LRU Cache Implementations

class LRUImageCache {
    private var cache: [String: NSImage] = [:]
    private var accessOrder: [String] = []
    private let maxSize: UInt64
    private let lock = NSLock()
    
    init(maxSize: UInt64) {
        self.maxSize = maxSize
    }
    
    var currentSize: UInt64 {
        lock.lock()
        defer { lock.unlock() }
        return UInt64(cache.values.reduce(0) { $0 + estimateImageSize($1) })
    }
    
    func trimToSize(_ targetSize: UInt64) {
        lock.lock()
        defer { lock.unlock() }
        
        while currentSize > targetSize && !cache.isEmpty {
            if let oldest = accessOrder.first {
                cache.removeValue(forKey: oldest)
                accessOrder.removeFirst()
            }
        }
    }
    
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
        accessOrder.removeAll()
    }
    
    private func estimateImageSize(_ image: NSImage) -> Int {
        let size = image.size
        return Int(size.width * size.height * 4) // Assume 4 bytes per pixel
    }
}

class LRUStringCache {
    private var cache: [String: String] = [:]
    private var accessOrder: [String] = []
    private let maxSize: UInt64
    private let lock = NSLock()
    
    init(maxSize: UInt64) {
        self.maxSize = maxSize
    }
    
    var currentSize: UInt64 {
        lock.lock()
        defer { lock.unlock() }
        return UInt64(cache.values.reduce(0) { $0 + $1.utf8.count })
    }
    
    func trimToSize(_ targetSize: UInt64) {
        lock.lock()
        defer { lock.unlock() }
        
        while currentSize > targetSize && !cache.isEmpty {
            if let oldest = accessOrder.first {
                cache.removeValue(forKey: oldest)
                accessOrder.removeFirst()
            }
        }
    }
    
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
        accessOrder.removeAll()
    }
}