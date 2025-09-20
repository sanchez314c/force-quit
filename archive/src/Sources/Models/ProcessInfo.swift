import Foundation
import AppKit

// SWARM 2.0 ForceQUIT - Memory Optimized Process Information

// Memory pool for efficient ProcessInfo management
class ProcessInfoPool {
    static let shared = ProcessInfoPool()
    private var pool: [ProcessInfo] = []
    private let poolLock = NSLock()
    private let maxPoolSize = 100 // Limit pool size
    
    private init() {}
    
    func borrow() -> ProcessInfo? {
        poolLock.lock()
        defer { poolLock.unlock() }
        return pool.popLast()
    }
    
    func returnToPool(_ processInfo: ProcessInfo) {
        poolLock.lock()
        defer { poolLock.unlock() }
        if pool.count < maxPoolSize {
            pool.append(processInfo)
        }
    }
    
    func clear() {
        poolLock.lock()
        defer { poolLock.unlock() }
        pool.removeAll()
    }
}

struct ProcessInfo: Identifiable, Hashable, Equatable {
    // MARK: - Properties
    let id: pid_t // Using PID as unique identifier
    let pid: pid_t
    let name: String
    let bundleIdentifier: String?
    let icon: NSImage? // Consider weak reference or lazy loading for memory efficiency
    let isActive: Bool
    let securityLevel: SecurityLevel
    let canSafelyRestart: Bool
    let memoryUsage: UInt64 // Bytes
    let cpuUsage: Double    // Percentage 0.0-1.0
    let createdAt: Date
    
    // MARK: - Computed Properties
    var memoryUsageFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(memoryUsage))
    }
    
    var cpuUsageFormatted: String {
        return String(format: "%.1f%%", cpuUsage * 100)
    }
    
    var statusColor: NSColor {
        if !isActive {
            return NSColor.systemGray
        }
        
        switch securityLevel {
        case .low:
            return NSColor.systemGreen
        case .medium:
            return NSColor.systemOrange  
        case .high:
            return NSColor.systemRed
        }
    }
    
    var safetyIndicator: String {
        canSafelyRestart ? "↻" : "⚠"
    }
    
    // MARK: - Initialization
    init(id: pid_t, 
         pid: pid_t,
         name: String,
         bundleIdentifier: String? = nil,
         icon: NSImage? = nil,
         isActive: Bool = false,
         securityLevel: SecurityLevel = .low,
         canSafelyRestart: Bool = false,
         memoryUsage: UInt64 = 0,
         cpuUsage: Double = 0.0) {
        
        self.id = id
        self.pid = pid
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.icon = icon
        self.isActive = isActive
        self.securityLevel = securityLevel
        self.canSafelyRestart = canSafelyRestart
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.createdAt = Date()
    }
    
    // MARK: - Security Level
    enum SecurityLevel: String, CaseIterable {
        case low = "User"
        case medium = "Agent"
        case high = "System"
        
        var description: String {
            switch self {
            case .low:
                return "Safe to terminate - User application"
            case .medium:
                return "Caution advised - Background agent"
            case .high:
                return "Dangerous - System process"
            }
        }
        
        var systemImage: String {
            switch self {
            case .low: return "person.crop.circle"
            case .medium: return "gear"
            case .high: return "lock.shield"
            }
        }
    }
    
    // MARK: - State Updates
    func updatingActiveState(isActive: Bool) -> ProcessInfo {
        return ProcessInfo(
            id: self.id,
            pid: self.pid,
            name: self.name,
            bundleIdentifier: self.bundleIdentifier,
            icon: self.icon,
            isActive: isActive,
            securityLevel: self.securityLevel,
            canSafelyRestart: self.canSafelyRestart,
            memoryUsage: self.memoryUsage,
            cpuUsage: self.cpuUsage
        )
    }
    
    func updatingResourceUsage(memory: UInt64, cpu: Double) -> ProcessInfo {
        return ProcessInfo(
            id: self.id,
            pid: self.pid,
            name: self.name,
            bundleIdentifier: self.bundleIdentifier,
            icon: self.icon,
            isActive: self.isActive,
            securityLevel: self.securityLevel,
            canSafelyRestart: self.canSafelyRestart,
            memoryUsage: memory,
            cpuUsage: cpu
        )
    }
    
    // MARK: - Hashable & Equatable
    func hash(into hasher: inout Hasher) {
        hasher.combine(pid)
    }
    
    static func == (lhs: ProcessInfo, rhs: ProcessInfo) -> Bool {
        return lhs.pid == rhs.pid
    }
}

// MARK: - Process Delta for Efficient Updates
struct ProcessDelta {
    let added: Set<ProcessInfo>
    let removed: Set<pid_t>
    let modified: Set<ProcessInfo>
    
    var isEmpty: Bool {
        added.isEmpty && removed.isEmpty && modified.isEmpty
    }
    
    static let empty = ProcessDelta(added: [], removed: [], modified: [])
}

// MARK: - Process Filtering and Sorting
extension Array where Element == ProcessInfo {
    
    func filtered(by searchText: String) -> [ProcessInfo] {
        guard !searchText.isEmpty else { return self }
        
        return self.filter { process in
            process.name.localizedCaseInsensitiveContains(searchText) ||
            process.bundleIdentifier?.localizedCaseInsensitiveContains(searchText) == true
        }
    }
    
    func sorted(by criteria: ProcessSortCriteria, ascending: Bool = true) -> [ProcessInfo] {
        let sorted = self.sorted { lhs, rhs in
            switch criteria {
            case .name:
                return lhs.name < rhs.name
            case .memoryUsage:
                return lhs.memoryUsage < rhs.memoryUsage
            case .cpuUsage:
                return lhs.cpuUsage < rhs.cpuUsage
            case .securityLevel:
                return lhs.securityLevel.rawValue < rhs.securityLevel.rawValue
            }
        }
        
        return ascending ? sorted : sorted.reversed()
    }
    
    func groupedBySecurityLevel() -> [ProcessInfo.SecurityLevel: [ProcessInfo]] {
        return Dictionary(grouping: self) { $0.securityLevel }
    }
}

// MARK: - Sort Criteria
enum ProcessSortCriteria: String, CaseIterable {
    case name = "Name"
    case memoryUsage = "Memory"
    case cpuUsage = "CPU"
    case securityLevel = "Security"
    
    var systemImage: String {
        switch self {
        case .name: return "textformat.abc"
        case .memoryUsage: return "memorychip"
        case .cpuUsage: return "cpu"
        case .securityLevel: return "shield"
        }
    }
}

// MARK: - Performance Monitoring Extensions
extension ProcessInfo {
    /// Memory efficiency score (0.0 = memory hog, 1.0 = efficient)
    var memoryEfficiencyScore: Double {
        let mbUsage = Double(memoryUsage) / (1024 * 1024)
        if mbUsage < 50 { return 1.0 }
        if mbUsage < 200 { return 0.8 }
        if mbUsage < 500 { return 0.6 }
        if mbUsage < 1024 { return 0.4 }
        return 0.2
    }
    
    /// CPU efficiency score (0.0 = CPU intensive, 1.0 = efficient)
    var cpuEfficiencyScore: Double {
        if cpuUsage < 0.05 { return 1.0 }
        if cpuUsage < 0.15 { return 0.8 }
        if cpuUsage < 0.30 { return 0.6 }
        if cpuUsage < 0.50 { return 0.4 }
        return 0.2
    }
    
    /// Overall performance impact (higher = more impact on system)
    var systemImpactScore: Double {
        let memoryImpact = (1.0 - memoryEfficiencyScore) * 0.6
        let cpuImpact = (1.0 - cpuEfficiencyScore) * 0.4
        return memoryImpact + cpuImpact
    }
    
    /// Candidate for force quit based on resource usage
    var isForceQuitCandidate: Bool {
        return systemImpactScore > 0.7 && securityLevel == .low
    }
}

// MARK: - Debug Information
struct ProcessDebugInfo {
    let processInfo: ProcessInfo
    let memoryBreakdown: MemoryBreakdown
    let performanceMetrics: ProcessPerformanceMetrics
    let timestamp: Date
    
    struct MemoryBreakdown {
        let resident: UInt64
        let virtual: UInt64
        let shared: UInt64
        let compressed: UInt64
    }
    
    struct ProcessPerformanceMetrics {
        let threads: Int
        let fileDescriptors: Int
        let ports: Int
        let contextSwitches: UInt64
    }
}