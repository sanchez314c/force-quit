# Technology Stack

## Core Technologies
- **Language**: Swift 5.9+
- **Framework**: SwiftUI with AppKit integration  
- **Runtime**: macOS 12.0+ (monterey)
- **Package Manager**: Swift Package Manager (SPM)
- **Build System**: Xcode + SPM with custom build scripts

## Key Dependencies
- SwiftUI (Native UI framework)
- AppKit (macOS system integration)
- Foundation (Core utilities)
- Combine (Reactive programming)
- OSLog (System logging)
- Security Framework (Authorization and sandboxing)

## Development Tools
- **IDE**: Xcode 15+
- **Linter**: SwiftLint (via build phases)
- **Formatter**: swift-format
- **Testing**: XCTest framework
- **Build Tool**: Custom shell scripts + Xcode build system

## Architecture
- **Pattern**: MVVM (Model-View-ViewModel)
- **UI**: SwiftUI with custom animated components
- **Security**: Sandboxed with helper tool for privileged operations
- **Process Management**: NSRunningApplication + Process termination APIs
- **State Management**: @StateObject, @ObservableObject patterns

## Project Type
**macOS Desktop Application** - System utility for elegantly force-quitting applications with advanced UI and safe restart capabilities.

## Special Features
- SWARM 2.0 AI Development Framework integrated
- Multi-modal activation (GUI, menu bar, hotkeys, shake detection)
- Advanced security with SIP compliance
- Performance monitoring and analytics
- Universal binary support (Intel + Apple Silicon)
- Auto-updater system
- Comprehensive build and distribution pipeline

## Build Targets
- ForceQUIT (Main application)
- ForceQUITCore (Core business logic)
- ForceQUITSecurity (Security framework)
- ForceQUITAnalytics (Analytics and monitoring)
- Test suites for each module