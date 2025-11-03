# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ForceQUIT is a sophisticated macOS force quit utility built with Swift and SwiftUI. It provides users with an elegant force quit solution with safe restart capabilities, process management, and system monitoring features while maintaining security-first principles and SIP compliance.

## Development Commands

### Core Build Commands
```bash
# Standard build
make build
swift build -c Release

# Debug build
make build-debug
swift build -c Debug

# Clean build artifacts
make clean
swift package clean

# Run the application
swift run ForceQUIT
./run-source-macos.sh
```

### Testing & Quality Assurance
```bash
# Run all tests
make test
swift test

# Run tests with verbose output
swift test --verbose

# Code quality checks
make lint                    # SwiftLint analysis
make format                  # Code formatting (if configured)
make security               # Security analysis
```

### Development Setup
```bash
# Set up development environment
make dev-setup

# Install dependencies
swift package resolve

# Generate Xcode project
swift package generate-xcodeproj
```

### Build System Features
```bash
# Show all available targets
make help

# Performance analysis
make performance

# Continuous integration checks
make ci-check

# Release preparation
make release
```

## Architecture Overview

### Swift Package Structure
```
ForceQUIT/
├── Package.swift             # Swift Package Manager configuration
├── Sources/
│   └── ForceQUIT/            # Main application source
│       ├── ForceQUITApp.swift    # App entry point
│       ├── Views/               # SwiftUI views
│       ├── Models/              # Data models
│       ├── Services/            # Business logic
│       └── Utils/               # Utility functions
├── Tests/
│   └── ForceQUITTests/         # Unit and integration tests
├── scripts/                    # Build and utility scripts
├── docs/                       # Documentation
└── Makefile                   # Build system automation
```

### Core Technologies
- **Swift 5.9+**: Modern Swift with async/await support
- **SwiftUI**: Declarative UI framework for macOS
- **AppKit**: Native macOS framework integration
- **Foundation**: Core data types and utilities
- **Process Management**: Native macOS process APIs

### Swift Configuration
The Package.swift configuration includes:
- **Platform Support**: macOS 12.0+ (SwiftUI 3.0+)
- **Language Features**:
  - Bare slash regex literals
  - Concise magic file
  - Forward trailing closures
  - Import Objective-C forward declarations
- **Compile Flags**: `SWIFTUI_FORCE_QUIT`, `DARK_MODE_OPTIMIZED`
- **Framework Linking**: AppKit, SwiftUI, Foundation

## Implementation Details

### Process Management Architecture
```swift
// Core process management flow
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

### Security Model
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

## Build System Architecture

### Makefile Structure
The comprehensive Makefile provides:
- **Development Workflow**: Build, test, clean, lint
- **Quality Assurance**: Security analysis, performance checks
- **Release Management**: CI checks, release preparation
- **Environment Setup**: Development environment initialization

### Build Targets
```makefile
# Core development targets
build              # Standard Release build
build-debug        # Debug build with symbols
test               # Run unit and integration tests
lint               # SwiftLint code analysis
clean              # Clean build artifacts

# Quality and security targets
security           # Security vulnerability analysis
performance        # Performance profiling
ci-check          # Continuous integration validation

# Development targets
dev-setup          # Initialize development environment
release            # Prepare release build
```

### Cross-Platform Considerations
- **Architecture Support**: Intel (x86_64) and Apple Silicon (arm64)
- **macOS Versions**: Targeting macOS 12.0+ for modern Swift features
- **Swift Package Manager**: Native dependency management
- **No External Dependencies**: Uses only native macOS frameworks

## Development Patterns

### Async/Await Usage
```swift
// Modern Swift concurrency for process operations
func forceQuitProcess(_ process: ProcessInfo) async throws {
    guard canTerminateProcess(process.processIdentifier) else {
        throw ProcessError.insufficientPermissions
    }

    try await withCheckedThrowingContinuation { continuation in
        // Async process termination
        DispatchQueue.global().async {
            let result = self.terminateProcess(process.processIdentifier)
            continuation.resume(with: result)
        }
    }
}
```

### SwiftUI Data Flow
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

## Testing Strategy

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

### Test Execution
```bash
# Run all tests
swift test

# Run specific test
swift test --filter ProcessManagerTests

# Run tests with code coverage
swift test --enable-code-coverage
```

## Important Implementation Notes

### Security Considerations
- **SIP Compliance**: Respect System Integrity Protection
- **Sandboxing**: Operate within App Store sandbox constraints
- **Permissions**: Request appropriate macOS permissions
- **Process Protection**: Never terminate system-critical processes

### Performance Optimization
- **Async Operations**: Use Swift concurrency for non-blocking UI
- **Process Discovery**: Optimize process enumeration performance
- **Memory Management**: Efficient memory usage for large process lists
- **UI Responsiveness**: Maintain smooth UI during operations

### User Experience
- **Dark Mode**: Full dark mode support optimized for extended use
- **Accessibility**: VoiceOver and keyboard navigation support
- **Error Recovery**: Graceful error handling with user guidance
- **Safety First**: Confirmations for destructive operations

### Build Configuration
- **Swift Compiler Flags**: Custom flags for feature toggles
- **Optimization Levels**: Different settings for debug/release
- **Code Signing**: Proper code signing for distribution
- **Universal Binary**: Support for Intel and Apple Silicon