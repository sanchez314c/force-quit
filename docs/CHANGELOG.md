# Changelog

🚀 **ForceQUIT Version History**

All notable changes to ForceQUIT will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Repository standardization and build system overhaul
- Comprehensive testing framework
- Enhanced documentation suite
- Multi-platform deployment support

### Changed
- Modernized Swift package structure
- Updated build scripts for better CI/CD integration
- Improved file organization and project structure

### Fixed
- Fixed package structure issues
- Resolved dependency conflicts

### Removed
- Legacy archive directory and duplicate files
- Redundant build scripts
- Outdated documentation

## [1.0.0] - 2024-10-29

### Added
- Initial release of ForceQUIT
- Elegant macOS force quit utility
- SwiftUI-based user interface
- Process detection and management
- Safe restart capabilities
- Dark mode support
- Visual indicators and animations
- Multi-modal activation (GUI, menu bar, hotkeys)
- Performance monitoring
- Security compliance with sandboxing

### Features
- **Process Management**
  - Detect running applications
  - Graceful process termination
  - Force quit unresponsive applications
  - Safe restart for supported apps

- **User Interface**
  - Modern SwiftUI design
  - Dark mode optimized
  - Animated visual feedback
  - Intuitive process list view
  - Quick action buttons

- **Security**
  - SIP-compliant architecture
  - Sandbox compliance
  - Permission management
  - Code signing support

- **Performance**
  - Real-time system monitoring
  - CPU and memory usage tracking
  - Application launch time optimization
  - Efficient resource management

- **Integration**
  - Menu bar integration
  - Global hotkeys support
  - Shake detection (optional)
  - AppleScript support

### System Requirements
- macOS 12.0 (Monterey) or later
- Intel Mac or Apple Silicon
- 4GB RAM minimum
- 50MB free disk space

### Documentation
- Complete user guide
- Installation instructions
- Development documentation
- API reference
- Contributing guidelines

### Known Issues
- None at release

---

## Version Format

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html):

- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality in a backward compatible manner
- **PATCH**: Backward compatible bug fixes

## Release Schedule

- **Major releases**: As needed for significant features
- **Minor releases**: Every 2-3 months for new features
- **Patch releases**: As needed for bug fixes

## Supported Versions

- **Current version**: Full support including features and bug fixes
- **Previous major version**: Security updates and critical bug fixes only
- **Older versions**: No support

## Getting Updates

### Automatic Updates
ForceQUIT includes automatic update checking:
- Checks for updates on launch
- Notifies user of available updates
- Downloads and installs updates with user consent

### Manual Updates
Users can manually check for updates:
1. Open ForceQUIT
2. Click "Check for Updates" in the menu
3. Follow the prompts to update

### Package Managers
Updates available through:
- Homebrew: `brew upgrade --cask forcequit`
- Direct download from GitHub releases

## Security Updates

Security updates are handled as follows:
- Critical security issues: Immediate patch release
- Non-critical issues: Included in next regular release
- Security advisories published on GitHub

## Changelog Maintenance

This changelog is maintained:
- For each release
- For all notable changes
- Following Keep a Changelog format
- Using semantic versioning

For release notes and announcements, see the [GitHub Releases](https://github.com/username/force-quit/releases) page.