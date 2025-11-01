# Architecture Documentation

## System Overview

ForceQUIT is a sophisticated macOS force quit utility built with Swift and SwiftUI, designed with security-first principles and modern architectural patterns.

## Core Architecture

### Application Structure
```
ForceQUIT/
├── Sources/ForceQUIT/            # Main application source
│   ├── ForceQUITApp.swift       # App entry point and configuration
│   ├── Views/                   # SwiftUI view components
│   │   ├── ProcessListView.swift
│   │   ├── ProcessDetailView.swift
│   │   └── SettingsView.swift
│   ├── Models/                  # Data models and structures
│   │   ├── ProcessInfo.swift
│   │   └── AppSettings.swift
│   ├── Services/                # Business logic and services
│   │   ├── ProcessManager.swift
│   │   ├── SecurityService.swift
│   │   └── NotificationService.swift
│   └── Utils/                   # Utility functions and extensions
│       ├── ProcessExtensions.swift
│       └── SecurityHelpers.swift
├── Tests/                       # Unit and integration tests
└── Resources/                   # App resources and assets
```

### Technology Stack
- **Swift 5.9+**: Modern Swift with async/await support
- **SwiftUI**: Declarative UI framework for macOS
- **AppKit**: Native macOS framework integration
- **Foundation**: Core data types and utilities
- **Combine**: Reactive programming for data flow

## Design Principles

### Security-First Architecture
- **SIP Compliance**: Respect System Integrity Protection
- **Sandboxing**: Operate within App Store sandbox constraints
- **Process Protection**: Never terminate system-critical processes
- **Permission Validation**: Validate user permissions for all operations

### Performance Architecture
- **Async Operations**: Non-blocking UI with Swift concurrency
- **Process Discovery**: Optimized enumeration algorithms
- **Memory Management**: Efficient resource usage patterns
- **UI Responsiveness**: Maintain smooth interface during operations

### User Experience Design
- **Dark Mode**: Full dark mode support optimized for extended use
- **Accessibility**: VoiceOver and keyboard navigation support
- **Error Recovery**: Graceful error handling with user guidance
- **Safety First**: Confirmations for destructive operations

## Core Components

### Process Management System
```swift
// Core process management architecture
class ProcessManager {
    // 1. Discover running applications
    func discoverProcesses() -> [ProcessInfo]

    // 2. Filter system-critical processes
    func filterSafeProcesses(_ processes: [ProcessInfo]) -> [ProcessInfo]

    // 3. Execute force quit with proper permissions
    func forceQuit(_ process: ProcessInfo) async throws

    // 4. Handle restart capabilities
    func restartApplication(_ process: ProcessInfo) async throws
}
```

### Security Framework
```swift
// Security-first approach with SIP compliance
struct SecurityConstraints {
    static let protectedProcesses: Set<String> = [
        "kernel_task", "launchd", "WindowServer",
        "loginwindow", "SystemUIServer", "Dock"
    ]

    static func canTerminateProcess(_ pid: pid_t) -> Bool {
        // Check process permissions and system criticality
        // Respect System Integrity Protection (SIP)
        // Validate user permissions
    }
}
```

### SwiftUI Interface Architecture
```swift
// Main application structure
@main
struct ForceQUITApp: App {
    var body: some Scene {
        WindowGroup {
            ProcessListView()
                .frame(minWidth: 600, minHeight: 400)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                // Custom app info and about section
            }
        }
    }
}
```

## Data Flow Architecture

### MVVM Pattern Implementation
```swift
// ObservableObject for reactive UI updates
@MainActor
class ProcessListViewModel: ObservableObject {
    @Published var processes: [ProcessInfo] = []
    @Published var isLoading = false
    @Published var selectedProcess: ProcessInfo?

    func refreshProcessList() async {
        isLoading = true
        defer { isLoading = false }

        processes = await processManager.discoverProcesses()
            .filter { processManager.isSafeToTerminate($0) }
    }
}
```

### Error Handling Strategy
```swift
// Comprehensive error handling with user-friendly messages
enum ProcessError: LocalizedError {
    case insufficientPermissions
    case processNotFound
    case systemProtected
    case terminationFailed(pid: pid_t)

    var errorDescription: String? {
        switch self {
        case .insufficientPermissions:
            return "Insufficient permissions to terminate this process"
        case .processNotFound:
            return "Process not found or already terminated"
        case .systemProtected:
            return "This process is protected by the system"
        case .terminationFailed(let pid):
            return "Failed to terminate process \(pid)"
        }
    }
}
```

## Build and Deployment Architecture

### Swift Package Configuration
- **Platform Support**: macOS 12.0+ (SwiftUI 3.0+)
- **Language Features**: Modern Swift 5.9+ features
- **Compile Flags**: Custom feature toggles
- **Framework Linking**: Native macOS frameworks

### Cross-Platform Support
- **Architecture Support**: Intel (x86_64) and Apple Silicon (arm64)
- **Universal Binary**: Single binary for both architectures
- **Native Dependencies**: Uses only built-in macOS frameworks
- **Package Manager**: Swift Package Manager for dependency management

## Testing Architecture

### Test Structure
```swift
// Unit tests for core functionality
class ProcessManagerTests: XCTestCase {
    func testProcessDiscovery() {
        // Test process enumeration
    }

    func testSecurityFiltering() {
        // Test protected process filtering
    }

    func testForceQuitOperation() {
        // Test process termination
    }
}
```

### Quality Assurance
- **Unit Testing**: Comprehensive test coverage for core components
- **Integration Testing**: End-to-end workflow validation
- **Performance Testing**: Memory and CPU usage profiling
- **Security Testing**: Permission and SIP compliance validation

## Future Architecture Considerations

### Scalability
- **Plugin Architecture**: Support for third-party extensions
- **Configuration System**: User-customizable settings and preferences
- **Monitoring Integration**: System health and performance metrics

### Extensibility
- **API Layer**: RESTful API for remote management
- **Scripting Support**: AppleScript and Shell integration
- **Automation**: Workflow automation and scheduling capabilities