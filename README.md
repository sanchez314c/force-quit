# ForceQUIT 🚪

> Elegant macOS Force Quit Utility - Safe process termination with modern UI

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift](https://img.shields.io/badge/Swift-5.9+-FA7343?logo=swift)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0+-346DA0?logo=swift)](https://developer.apple.com/xcode/swiftui/)
[![Platform](https://img.shields.io/badge/Platform-macOS%2012.0%2B-lightgrey)](https://github.com/sanchez314c/force-quit/releases)

## 📸 Main Interface

![ForceQUIT Screenshot](build_resources/screenshots/ForceQUIT.png)

> The Ultimate macOS Force Quit Utility - Safe Process Management with Style

ForceQUIT is a sophisticated macOS application that provides an elegant force quit solution with safe restart capabilities. Built with Swift and SwiftUI, it offers a modern dark UI for managing applications, processes, and system services while maintaining security-first principles and System Integrity Protection (SIP) compliance.

## ✨ Features

- 🎨 **Elegant Interface** - Modern SwiftUI design with dark mode support
- 🔒 **Security First** - SIP-compliant with sandboxing and proper permissions
- ⚡ **Quick Actions** - Fast application termination and restart capabilities
- 📊 **Process Monitoring** - Built-in system health tracking and resource monitoring
- 🌙 **Dark Mode Optimized** - Beautiful interface optimized for extended use
- 🔄 **Safe Restart** - Intelligent application restart with state preservation
- 🛡️ **Protected Processes** - Automatically filters system-critical processes
- 🚀 **Native Performance** - Built with native macOS frameworks for optimal speed
- 🔍 **Process Search** - Quick search and filtering for large process lists
- ⌨️ **Keyboard Navigation** - Full keyboard accessibility and shortcuts

## 📸 Screenshots

<details>
<summary>View Screenshots</summary>

![Main Interface](build_resources/screenshots/main-interface.png)
*Main interface showing running applications and processes*

![Process Details](build_resources/screenshots/process-details.png)
*Detailed process information and management options*

![Dark Mode](build_resources/screenshots/dark-mode.png)
*Beautiful dark mode optimized for extended use*

</details>

## 🚀 Quick Start - One-Command Build & Run

### Option 1: One-Command Solution (Recommended)

```bash
# Clone and build
git clone https://github.com/sanchez314c/force-quit.git
cd force-quit

# Build and run with a single command!
./scripts/build-release-run.sh
```

### Option 2: Development Mode

```bash
# Run in development mode with hot reload
./scripts/build-release-run.sh --dev
```

### Build Options

```bash
# Build only (don't launch)
./scripts/build-release-run.sh --build-only

# Clean build
./scripts/build-release-run.sh --clean

# Build for specific architecture
./scripts/build-release-run.sh --arch universal
./scripts/build-release-run.sh --arch intel
./scripts/build-release-run.sh --arch apple-silicon
```

## 📋 Prerequisites

For running from source:
- **macOS** 12.0+ (Monterey) for SwiftUI 3.0+ and async/await support
- **Xcode** 14.0+ or Swift 5.9+ command line tools
- **Git** for version control

The application will guide you through any required permissions.

## 🛠️ Installation

### Detailed Installation

```bash
# Clone the repository
git clone https://github.com/sanchez314c/force-quit.git
cd force-quit

# Option 1: Use the setup script
./scripts/setup.sh

# Option 2: Manual installation
swift package resolve

# Build and run
./scripts/build-release-run.sh
```

### Building from Source

```bash
# One-command build for current platform
./scripts/build-release-run.sh --build-only

# Build universal binary (Intel + Apple Silicon)
./scripts/build-release-run.sh --arch universal --build-only

# Debug build
swift build -c debug

# Release build
swift build -c release
```

### Build Output Locations

After building, find your executables in:
- **macOS**: `.build/release/ForceQUIT` and `dist/ForceQUIT.app`
- **Universal**: `dist/ForceQUIT-universal.app`

## 📖 Usage

### 1. Starting the Application

- **Pre-built Binary**: Double-click the ForceQUIT.app in Applications
- **From Source**: Run `./run-source-macos.sh` or `swift run ForceQUIT`

### 2. Managing Processes

- **View Applications**: See all running applications with resource usage
- **System Processes**: Filter to view system-level processes
- **Search**: Use the search bar to find specific processes quickly

### 3. Force Quit Operations

- **Safe Force Quit**: Terminates applications gracefully when possible
- **Force Termination**: Uses system-level termination for unresponsive apps
- **Process Protection**: Automatically prevents termination of system-critical processes

### 4. Application Restart

- **Smart Restart**: Attempts to restart applications with state preservation
- **Clean Restart**: Forces a clean restart of problematic applications
- **Recovery Mode**: Special handling for crashed or corrupted applications

### 5. Keyboard Shortcuts

- **⌘+Q**: Quit selected application
- **⌘+⌥+Q**: Force quit selected application
- **⌘+R**: Restart selected application
- **⌘+F**: Focus search field
- **↑/↓**: Navigate process list
- **Enter**: Show process details

## 🔧 Configuration

### Directory Structure

```
~/Library/Application Support/ForceQUIT/
├── config.json          # Application configuration
├── preferences.plist     # User preferences
├── logs/                # Application logs
└── temp/                # Temporary files
```

### Environment Variables

```bash
# Set custom log level
export FORCEQUIT_LOG_LEVEL=debug

# Enable debug mode
export FORCEQUIT_DEBUG=1

# Disable animations
export FORCEQUIT_NO_ANIMATIONS=1
```

### Security Settings

ForceQUIT operates with these security principles:
- **SIP Compliant**: Never terminates System Integrity Protection protected processes
- **Sandbox Aware**: Respects macOS sandbox constraints
- **Permission Minimal**: Requests only necessary macOS permissions
- **Privacy First**: No data collection or network access

## 🐛 Troubleshooting

### Common Issues

<details>
<summary>Permission denied</summary>

The app will prompt for necessary permissions automatically. If that fails:
```bash
# Reset permissions
sudo tccutil reset All com.sanchez314c.forcequit
```
</details>

<details>
<summary>Process won't terminate</summary>

1. Check if the process is system-protected
2. Ensure you have sufficient permissions
3. Try using "Force Termination" instead of "Force Quit"
4. Check logs in `~/Library/Logs/ForceQUIT/`
</details>

<details>
<summary>App won't launch</summary>

1. Ensure macOS 12.0 or later
2. Check security preferences in System Settings
3. Verify app signature: `codesign -dv ForceQUIT.app`
4. Try building from source
</details>

<details>
<summary>Build errors</summary>

1. Update Swift tools: `swift package update`
2. Clean build: `swift package clean`
3. Verify Xcode command line tools are installed
</details>

## 📁 Project Structure

```
force-quit/
├── Package.swift           # Swift Package Manager configuration
├── Sources/
│   └── ForceQUIT/         # Main application source
│       ├── ForceQUITApp.swift    # App entry point
│       ├── Views/               # SwiftUI views
│       ├── Models/              # Data models
│       ├── Services/            # Business logic
│       └── Utils/               # Utility functions
├── Tests/
│   └── ForceQUITTests/         # Unit and integration tests
├── build_resources/            # Build resources and assets
│   ├── icons/                # Application icons
│   └── screenshots/          # Application screenshots
├── scripts/                   # Build and utility scripts
│   ├── build-release-run.sh   # Main build script
│   ├── setup.sh              # Environment setup
│   └── temp-cleanup.sh       # Cleanup utilities
├── docs/                     # Documentation
├── archive/                  # Archived/backup files
└── dist/                     # Build outputs (generated)
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests or create issues for bug reports and feature requests.

### Development Setup

```bash
# Clone the repo
git clone https://github.com/sanchez314c/force-quit.git
cd force-quit

# Install dependencies
swift package resolve

# Run in development mode
swift run ForceQUIT

# Run tests
swift test

# Build for release
swift build -c release

# Code quality checks
make lint
make test
```

### Code Style

This project follows:
- **Swift Style Guide**: Official Swift style guidelines
- **SwiftUI Best Practices**: Modern SwiftUI patterns
- **Security First**: All code must pass security review
- **Testing**: Minimum 80% code coverage required

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Apple** - For SwiftUI and the amazing macOS platform
- **Swift Community** - For excellent tools and libraries
- **System Integrity Protection** - For keeping macOS secure
- **Open Source Contributors** - For making better software possible

## 🔗 Links

- [Report Issues](https://github.com/sanchez314c/force-quit/issues)
- [Request Features](https://github.com/sanchez314c/force-quit/issues/new?labels=enhancement)
- [Discussions](https://github.com/sanchez314c/force-quit/discussions)
- [Security Policy](docs/SECURITY.md)

---

**ForceQUIT v1.0** - Elegant macOS Force Quit Utility
Built with AI!