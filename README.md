# ForceQUIT

![Status](https://img.shields.io/badge/Status-Active-green)
![Version](https://img.shields.io/badge/Version-2.0.0-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Platform](https://img.shields.io/badge/Platform-macOS_12.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)

## Overview
ForceQUIT is an elegant macOS application designed to provide users with a sophisticated solution for quickly closing all open applications. The app serves as a master force quit utility with safe restart capabilities, featuring a dark mode, sleek, and avant-garde design with visual indicators, animations, and enhanced UX elements.

## Key Features
- 🚀 **Elegant Force Quit**: Sophisticated UI for terminating applications
- 🔄 **Safe Restart**: Restart applications that support it safely
- 🎨 **Dark Mode Design**: Sleek, avant-garde interface with lights and indicators
- 🔒 **Security First**: SIP-compliant with proper sandboxing
- ⚡ **Multi-Modal Activation**: GUI, menu bar, hotkeys, and shake detection
- 📊 **Performance Monitoring**: Built-in analytics and system health tracking
- 🛡️ **Advanced Security**: Privilege escalation with helper tools when needed

## Tech Stack
See [dev/tech-stack.md](dev/tech-stack.md) for complete technology details.

**Core**: Swift 5.9+ • SwiftUI • AppKit • macOS 12.0+

## Quick Start
```bash
# Development (from source)
./run-source-macos.sh

# Production (compiled)
./run-macos.sh

# Build application
./scripts/compile-build-dist.sh

# Run tests
swift test
```

## Project Structure
```
ForceQUIT/
├── Sources/              # Swift source modules
│   ├── ForceQUIT/       # Main application
│   ├── ForceQUITCore/   # Core business logic
│   ├── ForceQUITSecurity/ # Security framework
│   └── Analytics/       # Analytics and monitoring
├── Tests/               # Test suites
├── assets/              # Icons, images, resources
├── docs/                # Documentation
├── scripts/             # Build and deployment scripts
└── dev/                 # Development resources
```

## Documentation
- [Technical Architecture](docs/technical/BUILD_SYSTEM_README.md)
- [SWARM Framework Integration](dev/research/SWARM_2.0_MISSION_COMPLETE.md)
- [Security Model](Sources/ForceQUITSecurity/README.md)
- [Build System](docs/technical/DISTRIBUTION_MASTER_GUIDE.md)

## Development
This project utilizes the **SWARM 2.0 AI-driven development framework** - a proven system for coordinated AI development. See `/swarm/` directory for complete framework documentation.

### SWARM Commands
```bash
# Core development workflows
/sc:swarm-new-codebase    # Complete app development
/sc:swarm-codefix         # Automated issue resolution
/sc:swarm-security        # Security hardening
/sc:swarm-performance     # Performance optimization
```

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## Requirements
- **macOS**: 12.0 (Monterey) or later
- **Architecture**: Universal (Intel x64 + Apple Silicon ARM64)
- **Xcode**: 15.0 or later (for development)
- **Swift**: 5.9 or later

## License
MIT License - see [LICENSE](LICENSE) file for details.

## Build Status
- ✅ **Swift Package Manager**: Full SPM integration
- ✅ **Universal Binary**: Intel + Apple Silicon support
- ✅ **Code Signing**: Production-ready distribution
- ✅ **App Store**: Compatible with App Store distribution
- ✅ **Security**: SIP-compliant with proper entitlements