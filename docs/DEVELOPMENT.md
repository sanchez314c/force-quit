# Development Guide

🚀 **ForceQUIT Development Documentation**

This guide covers the development setup, architecture, and contribution guidelines for ForceQUIT.

## 🏗️ Architecture

### Core Components

ForceQUIT is built using a modular Swift architecture with the following main components:

- **Process Management**: Core process detection and termination
- **UI Layer**: SwiftUI-based user interface
- **Security**: Sandbox compliance and permission handling
- **Performance**: System monitoring and optimization

### Technology Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **System Integration**: AppKit, Foundation
- **Build System**: Swift Package Manager
- **Testing**: XCTest
- **Platform**: macOS 12.0+

## 🛠️ Development Setup

### Prerequisites

- macOS 12.0+ (Monterey)
- Xcode 14.0+ or Swift 5.9+ toolchain
- Git

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/username/force-quit.git
cd force-quit

# Run the setup script
./setup.sh

# Open in Xcode (optional)
open Package.swift
```

### Development Workflow

```bash
# Build for development
swift build

# Run tests
swift test

# Run with coverage
swift test --enable-code-coverage

# Build for release
swift build -c release

# Run the application
./run-source-macos.sh
```

## 📁 Project Structure

```
ForceQUIT/
├── Sources/
│   └── ForceQUIT/
│       ├── main.swift              # Application entry point
│       ├── Core/                   # Core functionality
│       ├── UI/                     # User interface
│       ├── Security/               # Security components
│       └── Performance/            # Performance monitoring
├── scripts/
│   ├── build.sh                    # Main build script
│   ├── test.sh                     # Test runner
│   └── deploy.sh                   # Deployment script
├── docs/                           # Documentation
├── tests/                          # Test suite
└── assets/                         # Application assets
```

## 🧪 Testing

### Test Structure

ForceQUIT uses a comprehensive testing framework with multiple test categories:

- **Unit Tests**: Test individual components in isolation
- **Integration Tests**: Test component interactions and workflows
- **UI Tests**: Test user interface interactions and user experience
- **Performance Tests**: Test performance characteristics and benchmarks

### Test Categories

#### Unit Tests
- Application lifecycle management
- Process enumeration and filtering
- Force quit operations and safety checks
- Error handling and edge cases
- Security model validation

#### Integration Tests
- End-to-end force quit workflows
- System integration and permissions
- Multi-process scenarios
- Resource management integration

#### UI Tests
- Interface responsiveness and accessibility
- User interactions and workflows
- Visual feedback and state changes
- Keyboard navigation and shortcuts

#### Performance Tests
- Application launch time (< 2 seconds)
- Force quit operation speed (< 1 second)
- Memory usage monitoring (< 50MB baseline)
- Resource efficiency benchmarks

### Running Tests

```bash
# Run all tests
swift test

# Run tests with verbose output
swift test --verbose

# Run tests with code coverage
swift test --enable-code-coverage

# Run specific test
swift test --filter ProcessManagerTests

# Run tests from specific file
swift test --filter ForceQUITTests/ProcessTests
```

### Test Coverage Goals

- **Target Coverage**: >90% for core functionality
- **Critical Path Coverage**: 100% for force quit operations
- **Security Coverage**: 100% for safety checks
- **UI Coverage**: >80% for user interface components

### Test Environment Setup

```bash
# Install test dependencies
swift package resolve

# Run tests in clean environment
swift package clean && swift test

# Run tests with specific configuration
FORCEQUIT_TEST_MODE=true swift test
```

### Writing Tests

```swift
import XCTest
@testable import ForceQUIT

class ProcessManagerTests: XCTestCase {
    var processManager: ProcessManager!
    
    override func setUp() {
        super.setUp()
        processManager = ProcessManager()
    }
    
    override func tearDown() {
        processManager = nil
        super.tearDown()
    }
    
    func testProcessDiscovery() {
        // Given: System is running
        // When: Discovering processes
        let processes = processManager.discoverProcesses()
        
        // Then: Should find running applications
        XCTAssertFalse(processes.isEmpty, "Should discover running processes")
    }
    
    func testSecurityFiltering() {
        // Given: List of processes including system processes
        let allProcesses = createMockProcesses()
        
        // When: Filtering for safe processes
        let safeProcesses = processManager.filterSafeProcesses(allProcesses)
        
        // Then: Should exclude system-critical processes
        let systemProcesses = safeProcesses.filter { $0.isSystemCritical }
        XCTAssertTrue(systemProcesses.isEmpty, "Should not include system-critical processes")
    }
    
    func testForceQuitOperation() async {
        // Given: Test process that can be safely terminated
        let testProcess = createMockProcess()
        
        // When: Attempting force quit
        do {
            try await processManager.forceQuit(testProcess)
            // Then: Should succeed without error
            XCTAssertTrue(true, "Force quit should succeed")
        } catch {
            XCTFail("Force quit should not throw error: \(error)")
        }
    }
}
```

### Test Data and Mocks

```swift
// Mock process for testing
extension ProcessInfo {
    static func mock(
        pid: pid_t = 1234,
        name: String = "TestApp",
        bundleIdentifier: String = "com.test.app",
        isSystemCritical: Bool = false
    ) -> ProcessInfo {
        return ProcessInfo(
            processIdentifier: pid,
            processName: name,
            bundleIdentifier: bundleIdentifier,
            isSystemCritical: isSystemCritical
        )
    }
}

// Test helper functions
func createMockProcesses() -> [ProcessInfo] {
    return [
        .mock(name: "Safari", bundleIdentifier: "com.apple.Safari", isSystemCritical: true),
        .mock(name: "TestApp", bundleIdentifier: "com.test.app", isSystemCritical: false),
        .mock(name: "Finder", bundleIdentifier: "com.apple.finder", isSystemCritical: true)
    ]
}
```

### Performance Testing

```swift
class PerformanceTests: XCTestCase {
    func testProcessDiscoveryPerformance() {
        // Given: Performance measurement
        measure {
            // When: Discovering processes
            let processManager = ProcessManager()
            _ = processManager.discoverProcesses()
        }
        // Then: Should complete within acceptable time
        // XCTest will automatically measure and report performance
    }
    
    func testMemoryUsage() {
        // Given: Memory measurement
        let startMemory = getCurrentMemoryUsage()
        
        // When: Performing operations
        let processManager = ProcessManager()
        let processes = processManager.discoverProcesses()
        _ = processManager.filterSafeProcesses(processes)
        
        // Then: Memory usage should be reasonable
        let endMemory = getCurrentMemoryUsage()
        let memoryIncrease = endMemory - startMemory
        XCTAssertLessThan(memoryIncrease, 10 * 1024 * 1024, "Should use less than 10MB additional memory")
    }
}
```

### Continuous Integration Testing

```yaml
# .github/workflows/test.yml
name: Test Suite

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Swift
        run: |
          xcode-select --install
          swift --version
          
      - name: Install Dependencies
        run: swift package resolve
        
      - name: Run Tests
        run: swift test --verbose --enable-code-coverage
        
      - name: Generate Coverage Report
        run: |
          xcrun llvm-cov report \
            .build/debug/ForceQUIT.xctest/Contents/MacOS/ForceQUIT \
            -instr-profile=.build/debug/codecov/default.profdata \
            -format=html > coverage.html
            
      - name: Upload Coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.html
```

### Writing Tests

```swift
import XCTest
@testable import ForceQUIT

class ForceQUITTests: XCTestCase {
    func testProcessDetection() {
        // Test process detection logic
    }

    func testUITermination() {
        // Test UI termination workflow
    }
}
```

## 🔨 Building

### Development Builds

```bash
# Debug build
swift build -c debug

# Run debug build
./run-source-macos.sh
```

### Release Builds

```bash
# Basic release build
./scripts/build.sh

# Universal binary
./scripts/build.sh --universal

# Signed and notarized
./scripts/build.sh --sign --notarize --dmg

# Complete release build
./scripts/build.sh --clean --universal --sign --notarize --dmg
```

### Build Options

- `--clean`: Clean build directory before building
- `--universal`: Build universal binary (Intel + Apple Silicon)
- `--sign`: Enable code signing
- `--notarize`: Enable notarization
- `--dmg`: Create DMG installer
- `--config CONFIGURATION`: Build configuration (Debug|Release)

## 🚀 Deployment

### GitHub Release

```bash
./scripts/deploy.sh --github --release \
    --token $GITHUB_TOKEN \
    --repo username/force-quit \
    --tag v1.0.0
```

### Homebrew Formula

```bash
./scripts/deploy.sh --homebrew
```

### Direct Download

```bash
./scripts/deploy.sh --direct
```

## 🔧 Configuration

### Environment Variables

- `FORCEQUIT_LOG_LEVEL`: Logging level (debug|info|warn|error)
- `FORCEQUIT_CONFIG_PATH`: Path to configuration file
- `FORCEQUIT_DEV_MODE`: Enable development mode

### Build Configuration

Key configuration options in `Package.swift`:

- **Minimum macOS Version**: 12.0
- **Swift Language Version**: 5.9
- **Compiler Flags**: Optimized for performance

## 🔍 Debugging

### Debug Build

```bash
# Build with debug symbols
swift build -c debug

# Run with debugger
lldb .build/debug/ForceQUIT
```

### Logging

Enable debug logging:

```swift
import os.log

let logger = Logger(subsystem: "com.forcequit.app", category: "main")
logger.debug("Debug message")
```

### Common Issues

1. **Build Failures**: Clean build directory and rebuild
2. **Permission Errors**: Check code signing certificates
3. **Test Failures**: Ensure test environment is properly set up

## 📊 Performance

### Monitoring

Use built-in performance monitoring:

```swift
import Performance

let monitor = PerformanceMonitor()
monitor.startMonitoring()
```

### Optimization

- Profile with Instruments
- Use release builds for performance testing
- Monitor memory usage
- Optimize critical paths

## 🔒 Security

### Code Signing

```bash
# Sign with developer certificate
./scripts/build.sh --sign --developer-id "Developer ID Application: Name"
```

### Sandbox Compliance

The app follows macOS sandboxing guidelines:

- File system access is limited
- Network access is controlled
- System integration requires permissions

## 🤝 Contributing

### Before Contributing

1. Read the [Contributing Guide](CONTRIBUTING.md)
2. Set up development environment
3. Run existing tests
4. Create a feature branch

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint for code style enforcement
- Document public APIs
- Keep functions focused and small

## 📚 Resources

### Documentation

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [AppKit Documentation](https://developer.apple.com/documentation/appkit/)
- [Swift Package Manager](https://www.swift.org/package-manager/)

### Tools

- [Xcode](https://developer.apple.com/xcode/) - IDE for Swift development
- [SwiftLint](https://github.com/realm/SwiftLint) - Code style enforcement
- [Instruments](https://developer.apple.com/xcode/features/instruments/) - Performance analysis

## 🆘 Getting Help

- **Issues**: [GitHub Issues](https://github.com/username/force-quit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/username/force-quit/discussions)
- **Documentation**: [Project Docs](../docs/)

---

For specific development questions, please open an issue or start a discussion.