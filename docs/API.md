# API Documentation

🚀 **ForceQUIT API Reference**

This document describes the internal API and interfaces provided by ForceQUIT.

## 📋 Overview

ForceQUIT provides both internal APIs for development and external interfaces for system integration. The APIs are designed around Swift's modern concurrency model and follow best practices for macOS applications.

## 🏗️ Core Architecture

### Main Components

```swift
// Main application entry point
@main
struct ForceQUITApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Process Management API

#### ProcessManager

The core process management functionality:

```swift
class ProcessManager: ObservableObject {
    // Get all running processes
    func getAllProcesses() -> [ProcessInfo]

    // Terminate a process gracefully
    func terminateProcess(_ pid: pid_t) throws -> Bool

    // Force quit a process
    func forceQuitProcess(_ pid: pid_t) throws -> Bool

    // Restart a process if supported
    func restartProcess(_ pid: pid_t) throws -> Bool
}
```

**ProcessInfo Structure**:

```swift
struct ProcessInfo: Identifiable, Codable {
    let id: UUID
    let pid: pid_t
    let name: String
    let bundleIdentifier: String?
    let icon: NSImage?
    let cpuUsage: Double
    let memoryUsage: Int64
    let launchTime: Date
    let isCritical: Bool
    let canRestart: Bool
}
```

#### Process Detection

```swift
class ProcessDetector {
    // Detect processes by name
    func detectProcesses(named name: String) -> [pid_t]

    // Detect processes by bundle identifier
    func detectProcesses(bundleId: String) -> [pid_t]

    // Monitor process lifecycle
    func startMonitoring(callback: @escaping (ProcessInfo) -> Void)
}
```

## 🎨 User Interface API

### Main Views

#### ContentView

```swift
struct ContentView: View {
    @StateObject private var processManager = ProcessManager()
    @State private var selectedProcess: ProcessInfo?

    var body: some View {
        NavigationView {
            ProcessListView(processes: processManager.processes)
        }
    }
}
```

#### ProcessListView

```swift
struct ProcessListView: View {
    let processes: [ProcessInfo]
    @Binding var selectedProcess: ProcessInfo?

    var body: some View {
        List(processes) { process in
            ProcessRowView(process: process)
        }
    }
}
```

#### ProcessRowView

```swift
struct ProcessRowView: View {
    let process: ProcessInfo

    var body: some View {
        HStack {
            AsyncImage(url: process.iconURL) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading) {
                Text(process.name).font(.headline)
                Text(process.bundleIdentifier ?? "Unknown").font(.caption)
            }

            Spacer()

            ProcessActionsView(process: process)
        }
    }
}
```

### Process Actions

```swift
struct ProcessActionsView: View {
    let process: ProcessInfo
    @StateObject private var processManager = ProcessManager()

    var body: some View {
        HStack {
            Button("Quit") {
                try? processManager.terminateProcess(process.pid)
            }

            if process.canRestart {
                Button("Restart") {
                    try? processManager.restartProcess(process.pid)
                }
            }

            Button("Force Quit", role: .destructive) {
                try? processManager.forceQuitProcess(process.pid)
            }
        }
    }
}
```

## 🔒 Security API

### Permission Manager

```swift
class PermissionManager: ObservableObject {
    // Check accessibility permissions
    func checkAccessibilityPermissions() -> Bool

    // Request accessibility permissions
    func requestAccessibilityPermissions() -> Bool

    // Check system events permissions
    func checkSystemEventsPermissions() -> Bool

    // Request system events permissions
    func requestSystemEventsPermissions() -> Bool
}
```

### Sandbox Manager

```swift
class SandboxManager {
    // Check if app is sandboxed
    var isSandboxed: Bool { get }

    // Request file system access
    func requestFileSystemAccess(to path: URL) -> Bool

    // Check network access
    var hasNetworkAccess: Bool { get }
}
```

## 📊 Performance Monitoring API

### Performance Monitor

```swift
class PerformanceMonitor: ObservableObject {
    @Published var cpuUsage: Double = 0
    @Published var memoryUsage: Int64 = 0
    @Published var diskUsage: Int64 = 0

    // Start monitoring
    func startMonitoring()

    // Stop monitoring
    func stopMonitoring()

    // Get current metrics
    func getCurrentMetrics() -> SystemMetrics
}
```

#### SystemMetrics Structure

```swift
struct SystemMetrics: Codable {
    let timestamp: Date
    let cpuUsage: Double
    let memoryUsage: Int64
    let memoryPressure: Double
    let diskUsage: Int64
    let networkActivity: NetworkActivity
}
```

## 🔧 Configuration API

### App Configuration

```swift
struct AppConfiguration: Codable {
    var theme: Theme
    var animationsEnabled: Bool
    var autoRefreshInterval: TimeInterval
    var showCriticalProcesses: Bool
    var defaultAction: ProcessAction

    enum Theme: String, CaseIterable, Codable {
        case system, light, dark
    }

    enum ProcessAction: String, CaseIterable, Codable {
        case quit, forceQuit, restart
    }
}
```

### Configuration Manager

```swift
class ConfigurationManager: ObservableObject {
    @Published var configuration = AppConfiguration()

    // Load configuration
    func loadConfiguration()

    // Save configuration
    func saveConfiguration()

    // Reset to defaults
    func resetToDefaults()

    // Update specific setting
    func updateSetting<T>(_ keyPath: WritableKeyPath<AppConfiguration, T>, to value: T)
}
```

## 🌐 External Integration API

### AppleScript Support

ForceQUIT provides AppleScript commands for automation:

```applescript
-- Get all running processes
tell application "ForceQUIT"
    set allProcesses to get all processes
end tell

-- Quit a specific process
tell application "ForceQUIT"
    quit process id 1234
end tell

-- Force quit a process by name
tell application "ForceQUIT"
    force quit process named "Safari"
end tell
```

### URL Scheme Integration

```swift
// Handle URL schemes
func handleURL(_ url: URL) -> Bool {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
        return false
    }

    switch components.host {
    case "quit":
        return handleQuitAction(components)
    case "restart":
        return handleRestartAction(components)
    default:
        return false
    }
}
```

Supported URL schemes:
- `forcequit://quit?pid=1234` - Quit process with PID
- `forcequit://quit?name=Safari` - Quit process by name
- `forcequit://restart?pid=1234` - Restart process with PID

## 🔍 Debugging API

### Debug Logger

```swift
class DebugLogger {
    enum LogLevel: String, CaseIterable {
        case debug, info, warning, error, critical
    }

    // Log message
    func log(_ message: String, level: LogLevel = .info, category: String = "general")

    // Log error
    func logError(_ error: Error, category: String = "general")

    // Get log entries
    func getLogEntries(since date: Date? = nil) -> [LogEntry]
}
```

### Diagnostics

```swift
class DiagnosticCollector {
    // Collect system information
    func collectSystemInfo() -> SystemInfo

    // Collect app performance data
    func collectPerformanceData() -> PerformanceData

    // Generate diagnostic report
    func generateDiagnosticReport() -> DiagnosticReport
}
```

## 🧪 Testing API

### Test Utilities

```swift
class TestUtils {
    // Create mock process
    static func createMockProcess(pid: pid_t = 9999, name: String = "TestApp") -> ProcessInfo

    // Create test environment
    static func createTestEnvironment() -> TestEnvironment

    // Clean up test data
    static func cleanupTestData()
}
```

### Test Doubles

```swift
// Mock ProcessManager for testing
class MockProcessManager: ProcessManagerProtocol {
    var mockProcesses: [ProcessInfo] = []
    var shouldThrowError = false

    func getAllProcesses() -> [ProcessInfo] {
        if shouldThrowError {
            throw TestError.mockError
        }
        return mockProcesses
    }
}
```

## 📝 Event System

### Event Bus

```swift
class EventBus {
    // Publish event
    func publish<T>(_ event: T)

    // Subscribe to events
    func subscribe<T>(to type: T.Type, handler: @escaping (T) -> Void)

    // Unsubscribe from events
    func unsubscribe<T>(to type: T.Type, handler: @escaping (T) -> Void)
}
```

### Event Types

```swift
// Process terminated event
struct ProcessTerminatedEvent {
    let process: ProcessInfo
    let terminationReason: TerminationReason
}

// App launched event
struct AppLaunchedEvent {
    let process: ProcessInfo
}

// Configuration changed event
struct ConfigurationChangedEvent {
    let keyPath: PartialKeyPath<AppConfiguration>
    let oldValue: Any
    let newValue: Any
}
```

## 🔐 Error Handling

### Error Types

```swift
enum ForceQUITError: LocalizedError {
    case processNotFound(pid: pid_t)
    case insufficientPermissions
    case processTerminationFailed(pid: pid_t, reason: String)
    case configurationError(String)
    case securityError(String)

    var errorDescription: String? {
        switch self {
        case .processNotFound(let pid):
            return "Process with PID \(pid) not found"
        case .insufficientPermissions:
            return "Insufficient permissions to perform this operation"
        case .processTerminationFailed(let pid, let reason):
            return "Failed to terminate process \(pid): \(reason)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .securityError(let message):
            return "Security error: \(message)"
        }
    }
}
```

### Result Types

```swift
typealias ProcessResult = Result<Void, ForceQUITError>
typealias ProcessListResult = Result<[ProcessInfo], ForceQUITError>
typealias ConfigurationResult = Result<Void, ForceQUITError>
```

## 📚 Usage Examples

### Basic Process Management

```swift
// Get process manager
let processManager = ProcessManager()

// Get all processes
let processes = processManager.getAllProcesses()

// Find Safari
let safariProcesses = processes.filter {
    $0.name.contains("Safari") || $0.bundleIdentifier?.contains("safari") == true
}

// Quit Safari
if let safari = safariProcesses.first {
    do {
        try processManager.terminateProcess(safari.pid)
        print("Safari terminated successfully")
    } catch {
        print("Failed to terminate Safari: \(error)")
    }
}
```

### Performance Monitoring

```swift
// Start performance monitoring
let monitor = PerformanceMonitor()
monitor.startMonitoring()

// Get current metrics
let metrics = monitor.getCurrentMetrics()
print("CPU Usage: \(metrics.cpuUsage)%")
print("Memory Usage: \(metrics.memoryUsage / 1024 / 1024) MB")

// Monitor for changes
monitor.$cpuUsage
    .sink { cpuUsage in
        if cpuUsage > 80 {
            print("High CPU usage detected: \(cpuUsage)%")
        }
    }
    .store(in: &cancellables)
```

### Configuration Management

```swift
// Get configuration manager
let configManager = ConfigurationManager()

// Load current configuration
configManager.loadConfiguration()

// Update theme
configManager.updateSetting(\.theme, to: .dark)

// Enable animations
configManager.updateSetting(\.animationsEnabled, to: true)

// Save changes
configManager.saveConfiguration()
```

---

For more detailed implementation information, see the [Development Guide](DEVELOPMENT.md).