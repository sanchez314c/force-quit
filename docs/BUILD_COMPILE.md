# Build System Documentation

🔧 **ForceQUIT Build System Documentation**

This document describes the comprehensive build system for ForceQUIT, supporting multiple architectures, configurations, and distribution channels.

## 📋 Agent-Driven CLI Build System

ForceQUIT includes a complete CLI-based build system designed for AI agents to execute autonomously without GUI dependencies.

### Key Features
- **Agent-Controlled Compilation**: Pure CLI workflow using `swift build`, `xcodebuild`
- **Multi-Architecture Support**: Intel x64 + Apple Silicon ARM64 + Universal binaries
- **SwiftUI & AppKit Compatibility**: Full framework support
- **Automated Code Signing**: CLI-based code signing and notarization
- **Command-Line Distribution**: DMG and ZIP creation via CLI tools
- **App Bundle Generation**: Complete .app bundles without Xcode GUI
- **Comprehensive Cleanup**: Automated temp file cleanup and optimization

## 🏗️ Build System Overview

The ForceQUIT build system is a complete, production-ready solution that supports:

- **Universal Binary Builds** (Intel x64 + Apple Silicon ARM64)
- **Debug and Release Configurations**
- **Automated Testing Workflows**
- **Code Signing and Notarization**
- **Multi-Channel Distribution**

## 📁 Build System Structure

```
scripts/
├── build.sh                    # Main build script
├── test.sh                     # Test runner
├── deploy.sh                   # Deployment system
├── build/                      # Build utilities
├── test/                       # Test utilities
└── deploy/                     # Deployment utilities

Makefile                        # Build automation
Package.swift                   # Swift package configuration
.swiftlint.yml                  # Code quality configuration
```

## 🚀 Build Scripts

### Main Build Script (`scripts/compile-build-dist-swift.sh`)

Complete CLI-based build system designed for agent execution:

- **Agent-Friendly CLI**: Pure command-line workflow, no GUI dependencies
- **Universal Binaries**: Intel + Apple Silicon + Universal binaries
- **Automated Code Signing**: CLI-based code signing and notarization
- **Multi-Format Distribution**: DMG and ZIP creation via CLI tools
- **App Bundle Generation**: Complete .app bundles without Xcode GUI
- **System Cleanup**: Automated temp file cleanup and optimization

#### Agent CLI Commands
```bash
# Basic build for current architecture
./compile-build-dist-swift.sh

# Universal binary build
./compile-build-dist-swift.sh --arch universal

# Signed and notarized release
./compile-build-dist-swift.sh --sign --notarize

# Complete release with DMG
./compile-build-dist-swift.sh --config release --sign --notarize --dmg
```

#### Build Options
- `--no-clean`: Skip cleaning build artifacts
- `--no-temp-clean`: Skip system temp cleanup
- `--arch ARCH`: Build architecture (x86_64, arm64, universal)
- `--config CONFIG`: Build configuration (debug, release)
- `--sign`: Code sign application
- `--notarize`: Notarize application (requires signing)
- `--dmg`: Create DMG installer
- `--zip`: Create ZIP archive

#### Usage Examples
```bash
# Basic release build
./scripts/build.sh

# Universal binary with DMG
./scripts/build.sh --universal --dmg

# Complete release build
./scripts/build.sh --clean --universal --sign --notarize --dmg
```

#### Build Options
- `--clean`: Clean build directory
- `--universal`: Build universal binary
- `--sign`: Enable code signing
- `--notarize`: Enable notarization
- `--dmg`: Create DMG installer
- `--config CONFIGURATION`: Build configuration

### Development Run Script (`scripts/run-swift-source.sh`)

Agent-controlled development execution:

- **Source Execution**: Run directly from source code
- **Auto-Detection**: Automatic project type detection (SPM, Xcode, main.swift)
- **Development Mode**: Optimized for development workflow
- **Error Handling**: Comprehensive error reporting

#### Development Commands
```bash
# Run from source (auto-detect project type)
./run-swift-source.sh

# Equivalent agent CLI commands
swift run                    # Swift Package Manager
xcodebuild -project MyApp.xcodeproj -scheme MyApp build  # Xcode project
swift Sources/main.swift     # Direct main.swift execution
```

### Project Setup Script (`scripts/swift-project-setup.sh`)

Agent-driven project creation:

- **CLI Project Creation**: Create new Swift projects via CLI
- **Template Support**: SwiftUI and AppKit templates
- **Automated Setup**: Complete project structure creation
- **Build Script Integration**: Automatically include build scripts

#### Project Creation Commands
```bash
# Create SwiftUI project
./swift-project-setup.sh --name "MyApp" --template swiftui

# Create AppKit project
./swift-project-setup.sh --name "MyApp" --template appkit
```

### Test Script (`scripts/test.sh`)

Comprehensive testing framework:

- **Unit Tests**: Component testing
- **Integration Tests**: System integration
- **UI Tests**: User interface testing
- **Coverage Reporting**: Code coverage analysis

#### Usage Examples
```bash
# Run unit tests
./scripts/test.sh --unit

# Run all tests with coverage
./scripts/test.sh --unit --integration --coverage

# Verbose test output
./scripts/test.sh --verbose
```

### Deploy Script (`scripts/deploy.sh`)

Multi-channel deployment system:

- **GitHub Releases**: Automated release creation
- **Homebrew Formula**: Package manager distribution
- **Direct Download**: Standalone packages

#### Usage Examples
```bash
# Deploy to GitHub
./scripts/deploy.sh --github --release

# Create Homebrew formula
./scripts/deploy.sh --homebrew

# Deploy to all channels
./scripts/deploy.sh --github --homebrew --direct --release
```

## 🔨 Makefile Integration

The Makefile provides convenient targets for common operations:

### Build Targets
```bash
make build              # Basic build
make build-debug        # Debug build
make build-release      # Release build
make build-universal    # Universal binary
make build-signed       # Code signed build
make build-notarized    # Signed and notarized
make build-dmg          # DMG installer
make build-release-complete  # Full release package
```

### Test Targets
```bash
make test               # Run tests
make test-all           # All tests with coverage
make test-integration   # Integration tests
make test-ui            # UI tests
```

### Quality Targets
```bash
make lint               # SwiftLint checks
make lint-fix           # Auto-fix linting issues
make security-check     # Security analysis
make quality-check      # All quality checks
```

### Deployment Targets
```bash
make deploy-github      # Deploy to GitHub
make deploy-homebrew    # Create Homebrew formula
make deploy-direct      # Direct download package
make deploy-all         # Deploy to all channels
```

## 🏗️ Swift Package Manager

### Package Configuration (`Package.swift`)

```swift
let package = Package(
    name: "ForceQUIT",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "ForceQUIT", targets: ["ForceQUIT"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ForceQUIT",
            dependencies: [],
            path: "Sources/ForceQUIT",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImportObjcForwardDeclarations"),
                .define("SWIFTUI_FORCE_QUIT"),
                .define("DARK_MODE_OPTIMIZED")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Foundation")
            ]
        ),
        .testTarget(
            name: "ForceQUITTests",
            dependencies: ["ForceQUIT"],
            path: "Tests/ForceQUITTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
```

### Build Commands

```bash
# Development build
swift build

# Release build
swift build -c release

# Test
swift test

# Clean
swift package clean
```

## 🔧 Build Configurations

### Debug Configuration
- **Optimization**: None (default)
- **Debug Symbols**: Full debug information
- **Assertions**: Enabled
- **Safety Checks**: Enabled

### Release Configuration
- **Optimization**: Full optimization
- **Debug Symbols**: Stripped (unless specified)
- **Assertions**: Disabled
- **Safety Checks**: Optimized

## 🏛️ Universal Binary Support

### Architecture Targets
- **x86_64**: Intel-based Macs
- **arm64**: Apple Silicon (M1/M2/M3)

### Build Process
1. Build for Intel (x86_64)
2. Build for Apple Silicon (arm64)
3. Create universal binary with `lipo`
4. Verify universal binary structure

### Universal Binary Commands
```bash
# Build universal binary
swift build -c release --arch x86_64
swift build -c release --arch arm64
lipo -create x64_binary arm64_binary -output universal_binary

# Verify universal binary
lipo -info universal_binary
```

## 🔒 Code Signing and Notarization

### Development Signing
```bash
# Ad-hoc signing (for development)
codesign --force --sign - ForceQUIT.app

# Development certificate signing
codesign --force --sign "Developer ID Application: Name" ForceQUIT.app
```

### Distribution Signing
```bash
# Production signing
codesign --force --deep --sign "Developer ID Application: Name" ForceQUIT.app

# Verify signature
codesign --verify --verbose ForceQUIT.app
```

### Notarization Process
1. **Create DMG**: Package application in DMG
2. **Upload to Apple**: Submit for notarization
3. **Wait for Approval**: Monitor notarization status
4. **Staple Notarization**: Attach notarization to app
5. **Verify**: Confirm notarization is valid

### Notarization Commands
```bash
# Submit for notarization
xcrun altool --notarize-app \
    --primary-bundle-id "com.forcequit.app" \
    --username "apple@example.com" \
    --password "app-specific-password" \
    --file ForceQUIT.dmg

# Staple notarization
xcrun stapler staple ForceQUIT.app
```

## 📊 Build Performance

### Optimization Strategies
- **Parallel Compilation**: Multi-core builds
- **Incremental Builds**: Only rebuild changed files
- **Caching**: Build artifact caching
- **Link-Time Optimization**: LTO for release builds

### Build Times
- **Debug Build**: ~30 seconds
- **Release Build**: ~45 seconds
- **Universal Build**: ~90 seconds
- **With Signing**: +30 seconds
- **With Notarization**: +5-10 minutes

## 🧪 Testing Integration

### Build-Time Testing
- **Unit Tests**: Run on every build
- **Integration Tests**: Run on release builds
- **UI Tests**: Run before deployment
- **Performance Tests**: Run in CI/CD

### Quality Gates
- **SwiftLint**: Code style checks
- **Security Scanning**: Vulnerability detection
- **Dependency Checks**: License and security validation
- **Binary Analysis**: Security and compliance checks

## 🚀 Deployment Automation

### CI/CD Pipeline
1. **Code Commit**: Trigger build on push
2. **Build Application**: Multi-architecture build
3. **Run Tests**: Comprehensive test suite
4. **Quality Checks**: Code quality and security
5. **Create Release**: GitHub release with assets
6. **Deploy Channels**: Multiple distribution channels

### Deployment Targets
- **GitHub Releases**: Primary distribution
- **Homebrew**: Package manager integration
- **Direct Download**: Website distribution
- **App Store**: Future consideration

## 🔍 Agent CLI Reference

### Essential CLI Commands for Agents
```bash
# Development Tools Setup
xcode-select --install                    # Install development tools
swift --version                           # Check Swift version
xcodebuild -version                      # Check Xcode version

# Project Creation and Management
swift package init --type executable     # Create SPM project
mkdir -p Sources Resources               # Create directories
swift package show-dependencies          # Show package dependencies

# Build Commands (Agent-Executable)
swift build                              # Debug build
swift build -c release                   # Release build
swift run                               # Build and run
swift package clean                      # Clean build artifacts

# Xcode Project Commands
xcodebuild -project MyApp.xcodeproj -scheme MyApp -configuration Release
xcodebuild -showBuildSettings           # Show build settings
xcodebuild -list                        # List schemes and targets

# Code Signing Commands (Agent-Executable)
security find-identity -v -p codesigning           # List signing identities
codesign --force --sign "Developer ID" MyApp.app   # Sign application
codesign --verify --verbose=4 MyApp.app            # Verify signature

# Notarization Commands (Agent-Executable)
xcrun notarytool submit MyApp.zip --keychain-profile "AC_PASSWORD"
xcrun stapler staple MyApp.app           # Staple notarization

# Distribution Commands (Agent-Executable)
zip -r MyApp.zip MyApp.app               # Create ZIP
hdiutil create -srcfolder MyApp.app -format UDZO MyApp.dmg  # Create DMG

# Analysis Commands
xcrun size MyApp                        # Show binary size
otool -L MyApp                          # Show linked libraries
```

## 🔍 Debugging and Troubleshooting

### Common Build Issues
- **Swift Version**: Ensure Swift 5.9+ is installed
- **Xcode Tools**: Install Xcode Command Line Tools
- **Dependencies**: Resolve package dependencies
- **Code Signing**: Configure certificates and profiles

### Debug Commands
```bash
# Debug build
swift build -c debug

# Verbose build
swift build --verbose

# Clean build
swift package clean && swift build

# Check dependencies
swift package resolve
```

### Log Analysis
```bash
# Build logs
swift build 2>&1 | tee build.log

# Test logs
swift test --verbose 2>&1 | tee test.log

# System logs for runtime issues
log stream --predicate 'subsystem == "com.forcequit.app"'
```

## 📚 Additional Resources

### Documentation
- [Swift Package Manager](https://www.swift.org/package-manager/)
- [Xcode Build System](https://developer.apple.com/xcode/)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)

### Tools
- [SwiftLint](https://github.com/realm/SwiftLint) - Code quality
- [Xcode](https://developer.apple.com/xcode/) - Development environment
- [Instruments](https://developer.apple.com/xcode/features/instruments/) - Performance analysis

---

This build system is designed for professional macOS application development with emphasis on automation, quality, and distribution.