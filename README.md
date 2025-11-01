# ForceQUIT

![Status](https://img.shields.io/badge/Status-Active-green)
![Version](https://img.shields.io/badge/Version-1.0.0-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Platform](https://img.shields.io/badge/Platform-macOS_12.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)

🚀 **Elegant macOS Force Quit Utility**

ForceQUIT is a sophisticated macOS application designed to provide users with an elegant force quit solution with safe restart capabilities and enhanced user experience.

## ✨ Features

- **🎨 Elegant Interface**: Modern SwiftUI design with dark mode support
- **🔄 Safe Operations**: Secure process management with proper permissions
- **⚡ Quick Actions**: Fast application termination and restart capabilities
- **🔒 Security First**: SIP-compliant with sandboxing
- **📊 Performance Monitoring**: Built-in system health tracking
- **🌙 Dark Mode**: Beautiful dark mode optimized interface

## 🚀 Quick Start

### Prerequisites
- macOS 12.0+ (Monterey)
- Intel Mac or Apple Silicon

### Installation

```bash
# Clone the repository
git clone https://github.com/username/force-quit.git
cd force-quit

# Run setup script
./setup.sh

# Build and run
./scripts/build.sh && ./run-macos.sh
```

### Alternative Installation Methods

**Download Release**:
1. Visit [Releases](https://github.com/username/force-quit/releases)
2. Download `ForceQUIT.dmg`
3. Install to Applications folder

**Homebrew**:
```bash
brew install --cask forcequit
```

## 📖 Documentation

### User Documentation
- **[Quick Start Guide](docs/QUICK_START.md)** - Get up and running in 5 minutes
- **[Installation Guide](docs/INSTALLATION.md)** - Detailed installation instructions
- **[User FAQ](docs/FAQ.md)** - Common questions and answers
- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Solutions to common issues

### Developer Documentation
- **[Development Guide](docs/DEVELOPMENT.md)** - Development setup and contribution
- **[API Reference](docs/API.md)** - Complete API documentation
- **[Build System](docs/BUILD_COMPILE.md)** - Build and compilation guide
- **[Architecture](docs/ARCHITECTURE.md)** - System architecture and design

### Project Documentation
- **[Documentation Index](docs/DOCUMENTATION_INDEX.md)** - Complete documentation overview
- **[Contributing Guide](docs/CONTRIBUTING.md)** - How to contribute
- **[Security Policy](docs/SECURITY.md)** - Security information and policies
- **[Code of Conduct](docs/CODE_OF_CONDUCT.md)** - Community guidelines

### Planning & Roadmap
- **[Product Requirements](docs/PRD.md)** - Product vision and requirements
- **[Development Workflow](docs/WORKFLOW.md)** - Development processes and CI/CD
- **[TODO & Roadmap](docs/TODO.md)** - Current development priorities

For complete documentation, see the [docs/](docs/) directory.

## 🏗️ Project Structure

```
ForceQUIT/
├── Sources/ForceQUIT/         # Swift source code
├── Tests/                     # Test suite
├── docs/                      # Documentation
├── scripts/                   # Build and deployment scripts
├── assets/                    # Application assets
├── .github/                   # GitHub templates and workflows
└── Makefile                   # Build automation
```

## 🛠️ Development

### Build from Source

```bash
# Development build
make build

# Release build
make build-release

# Universal binary (Intel + Apple Silicon)
make build-universal

# Complete release package
make build-release-complete
```

### Testing

```bash
# Run all tests
make test

# Run tests with coverage
make test-all

# Quality checks
make quality-check
```

### Development Workflow

```bash
# Setup development environment
make dev-setup

# Quick development cycle (build, test, lint)
make dev

# Full quality assurance
make qa
```

## 🔧 Build System

ForceQUIT uses a comprehensive CLI-based build system with:

- **Agent-Driven**: Pure CLI workflow for automated execution
- **Universal Binaries**: Intel x64 + Apple Silicon ARM64
- **Code Signing**: Professional distribution with signing
- **Notarization**: Apple notarization for distribution
- **Multiple Formats**: App bundle, DMG installer, and more
- **CI/CD Ready**: Automated testing and deployment

See [Build System Guide](docs/BUILD_COMPILE.md) for complete build documentation.

## 📊 Technology Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **System Integration**: AppKit, Foundation
- **Build System**: Swift Package Manager
- **Testing**: XCTest
- **Platform**: macOS 12.0+

See [Technical Stack](docs/TECHSTACK.md) for detailed information.

## 🔒 Security

ForceQUIT is designed with security as a primary consideration:

- **Sandbox Compliant**: Operates within macOS sandbox constraints
- **Code Signed**: All releases are properly signed and notarized
- **Permission Management**: Requests only necessary permissions
- **No Data Collection**: All data remains on your device
- **Secure Updates**: Automatic updates with security verification

See [Security Policy](docs/SECURITY.md) for complete security information.

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](docs/CONTRIBUTING.md) for details.

### Quick Contributing Steps

1. Fork repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass (`make quality-check`)
6. Submit a pull request

## 📋 Requirements

- **macOS**: 12.0 (Monterey) or later
- **Architecture**: Universal (Intel x64 + Apple Silicon ARM64)
- **Development**: Xcode 14.0+ or Swift 5.9+
- **Memory**: 4GB RAM minimum
- **Storage**: 50MB free space

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🆘 Support & Community

- **Documentation**: [docs/](docs/) - Complete documentation suite
- **Issues**: [GitHub Issues](https://github.com/username/force-quit/issues) - Bug reports and feature requests
- **Discussions**: [GitHub Discussions](https://github.com/username/force-quit/discussions) - Community discussions
- **Security**: security@forcequit.app - Security-related inquiries

## 🎯 Build Status

- ✅ **Swift Package Manager**: Full SPM integration
- ✅ **Universal Binary**: Intel + Apple Silicon support
- ✅ **Code Signing**: Production-ready distribution
- ✅ **Testing**: Comprehensive test suite
- ✅ **Documentation**: Complete documentation suite
- ✅ **Security**: Security-focused development

---

**ForceQUIT** - Master force quit utility for macOS.

Made with ❤️ for the macOS community.