# ForceQUIT Build System Documentation

## SWARM 2.0 Framework - BUILD_SYSTEM_DEVELOPER

This document describes the comprehensive build system created for ForceQUIT, a sleek macOS Force Quit utility.

---

## 🏗️ Build System Overview

The ForceQUIT build system is a complete, production-ready solution that supports:

- **Universal Binary Builds** (Intel x64 + Apple Silicon ARM64)
- **Debug and Release Configurations**
- **Automated Testing Workflows**
- **Code Signing and Notarization**
- **Multi-format Distribution** (ZIP, DMG, PKG)
- **CI/CD Integration** (GitHub Actions)
- **Local Development Tools**

---

## 📁 Build System Files

### Core Build Scripts
- `Package.swift` - Enhanced Swift Package Manager configuration
- `swift-build-debug.sh` - Fast debug builds with full symbols
- `swift-build-release.sh` - Optimized release builds  
- `swift-build-universal.sh` - Universal binary builder (Intel + Apple Silicon)
- `master-build-pipeline.sh` - Complete end-to-end build pipeline

### Code Signing & Distribution
- `code-sign-config.sh` - Code signing environment setup
- `code-sign-notarize.sh` - Signing and notarization (existing, enhanced)
- `compile-build-dist-swift.sh` - Distribution package creation (existing)

### Testing & Quality Assurance
- `swift-test-suite.sh` - Comprehensive test execution
- `test-automation.sh` - Local development test automation
- `.github/workflows/ci-cd.yml` - GitHub Actions CI/CD pipeline

### Utilities
- `set-signing-environment.sh` - Code signing environment (auto-generated)
- `test-code-signing.sh` - Code signing validation (auto-generated)

---

## 🚀 Quick Start Guide

### 1. Basic Development Build
```bash
# Debug build for development
./swift-build-debug.sh

# Release build for testing
./swift-build-release.sh
```

### 2. Universal Binary Build
```bash
# Build universal binary (Intel + Apple Silicon)
./swift-build-universal.sh --test --optimize-size
```

### 3. Complete Pipeline
```bash
# Run full build pipeline
./master-build-pipeline.sh --full-pipeline
```

### 4. Testing
```bash
# Run comprehensive test suite
./swift-test-suite.sh

# Test automation with file watching
./test-automation.sh --watch
```

---

## 🔧 Detailed Usage

### Debug Builds
```bash
./swift-build-debug.sh
```
**Features:**
- Fast compilation times
- Full debug symbols
- Extensive logging enabled
- Creates debug app bundle
- Optimized for development workflow

**Outputs:**
- `build/ForceQUIT-debug` - Debug binary
- `build/ForceQUIT-Debug.app` - Debug app bundle

### Release Builds
```bash
./swift-build-release.sh [options]

Options:
  --universal      Build universal binary
  --arch <arch>    Build for specific architecture  
  --optimize-size  Optimize for size (-Osize)
  --keep-symbols   Don't strip debug symbols
```

**Features:**
- Maximum optimization (-O)
- Symbol stripping for size reduction
- Production-ready app bundle
- Distribution archive creation

**Outputs:**
- `build/ForceQUIT-release` - Release binary
- `build/ForceQUIT.app` - Production app bundle
- `dist/ForceQUIT-1.0.0-[arch]-release.zip` - Distribution archive

### Universal Binary Builds
```bash
./swift-build-universal.sh [options]

Options:
  --optimize-size  Enable size optimization
  --keep-symbols   Preserve debug symbols
  --test          Run tests before building
  --sequential    Build architectures sequentially
  --debug         Build debug configuration
```

**Features:**
- Parallel architecture builds (default)
- Intel x64 + Apple Silicon ARM64 support
- Comprehensive binary verification
- Optimized for performance and compatibility

**Outputs:**
- `build/ForceQUIT-universal` - Universal binary
- `dist/ForceQUIT.app` - Universal app bundle
- `dist/ForceQUIT-1.0.0-Universal.zip` - Distribution archive

---

## 🧪 Testing System

### Comprehensive Test Suite
```bash
./swift-test-suite.sh [options]

Options:
  --unit-only         Run unit tests only
  --integration-only  Run integration tests only  
  --performance-only  Run performance tests only
  --security-only     Run security tests only
  --no-coverage       Skip coverage generation
  --sequential        Run tests sequentially
  --verbose           Verbose output
  --fail-fast         Stop on first failure
```

**Test Types:**
- **Unit Tests** - Core functionality validation
- **Integration Tests** - Component interaction testing
- **Performance Tests** - Performance benchmarking
- **Security Tests** - Security vulnerability scanning

**Outputs:**
- `test-reports/test-results.html` - HTML test report
- `coverage/index.html` - Code coverage report

### Test Automation
```bash
./test-automation.sh [mode]

Modes:
  --watch        Monitor file changes, run tests automatically
  --continuous   Run tests in continuous loop
  --pre-commit   Pre-commit validation mode
```

**Features:**
- File system watching (requires `fswatch`)
- Pre-commit hook integration
- Continuous integration support

---

## 🔐 Code Signing & Notarization

### Setup Code Signing
```bash
./code-sign-config.sh
```

**What it does:**
- Scans for available signing identities
- Creates entitlements files for all targets
- Generates signing environment script
- Creates signing validation tests

**Generated Files:**
- `ForceQUIT.entitlements` - Production entitlements
- `ForceQUIT-AppStore.entitlements` - App Store sandboxed entitlements  
- `ForceQUIT-Debug.entitlements` - Development entitlements
- `set-signing-environment.sh` - Environment configuration
- `test-code-signing.sh` - Signing validation

### Environment Configuration
```bash
# Load signing environment
source ./set-signing-environment.sh

# Set notarization credentials (manual)
export APPLE_ID="your.apple.id@example.com"
export APPLE_ID_PASSWORD="app-specific-password"  
export TEAM_ID="YOUR_TEAM_ID"
```

### Sign and Notarize
```bash
./code-sign-notarize.sh
```

**Outputs:**
- `notarized/ForceQUIT.app` - Signed and notarized app
- `notarized/installer/ForceQUIT-1.0.0.pkg` - Signed installer
- `notarized/appstore/ForceQUIT-AppStore-1.0.0.pkg` - App Store package

---

## 🔄 Master Build Pipeline

The master pipeline orchestrates the entire build process:

```bash
./master-build-pipeline.sh [options]

Options:
  --skip-tests      Skip test execution
  --debug          Build debug version only
  --sign           Enable code signing
  --notarize       Enable notarization (implies --sign)
  --dmg            Create DMG installer
  --installer      Create PKG installer
  --appstore       Prepare App Store package
  --deploy         Deploy artifacts
  --full-pipeline  Run complete pipeline
```

**Pipeline Stages:**
1. **Environment Validation** - Check tools and project structure
2. **Test Suite Execution** - Run comprehensive tests
3. **Debug Build** - Create debug version (if requested)
4. **Release Build** - Create optimized release build
5. **Universal Binary Build** - Build universal binary
6. **Code Signing Setup** - Configure signing environment
7. **Code Signing & Notarization** - Sign and notarize
8. **DMG Creation** - Create disk image installer
9. **Installer Package Creation** - Create PKG installer
10. **App Store Package Preparation** - Prepare for App Store
11. **Artifact Deployment** - Organize final artifacts

---

## 🤖 CI/CD Integration

### GitHub Actions Workflow
Location: `.github/workflows/ci-cd.yml`

**Workflow Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main`
- Git tags starting with `v`
- Manual workflow dispatch

**Workflow Jobs:**
1. **Code Quality & Security** - Linting and security analysis
2. **Test Suite** - Matrix testing across test types
3. **Universal Binary Build** - Multi-architecture build
4. **Code Signing & Notarization** - Automated signing
5. **Release Creation** - GitHub release with artifacts
6. **Deployment Notifications** - Success/failure notifications

**Required Secrets:**
```
SIGNING_CERTIFICATE_P12_DATA  # Base64 encoded certificate
SIGNING_CERTIFICATE_PASSWORD  # Certificate password
APPLE_ID                      # Apple ID for notarization
APPLE_ID_PASSWORD            # App-specific password
TEAM_ID                      # Developer team ID
```

---

## 📊 Package.swift Configuration

Enhanced Swift Package Manager configuration with:

### Modern Swift Features
- Swift 5.9 language version
- Strict concurrency enabled
- Upcoming language features enabled
- Experimental features for performance

### Build Optimizations
- Debug: No optimization (-Onone) for debugging
- Release: Maximum optimization (-O) for performance  
- Size optimization (-Osize) option available
- Configuration-specific compiler flags

### Framework Linking
- **AppKit** - System integration
- **SwiftUI** - Modern UI framework
- **Combine** - Reactive programming
- **Security** - Privileged operations
- **ServiceManagement** - Helper tool management
- **OSLog** - Structured logging

### Modular Architecture
- **ForceQUIT** - Main executable
- **ForceQUITCore** - Core functionality library
- **ForceQUITSecurity** - Security and privileges
- **ForceQUITAnalytics** - Performance tracking

### Test Targets
- **ForceQUITTests** - Unit tests
- **ForceQUITSecurityTests** - Security tests
- **ForceQUITAnalyticsTests** - Analytics tests
- **ForceQUITPerformanceTests** - Performance benchmarks

---

## 🛠️ Development Workflow

### Recommended Development Flow
1. **Setup** - Run `./code-sign-config.sh` once
2. **Development** - Use `./swift-build-debug.sh` for quick iterations
3. **Testing** - Run `./test-automation.sh --watch` during development
4. **Pre-commit** - Setup pre-commit hooks with `./test-automation.sh`
5. **Release** - Use `./master-build-pipeline.sh --full-pipeline`

### Performance Tips
- Use `--parallel` builds for faster compilation
- Enable `--optimize-size` for smaller binaries
- Use `--sequential` if parallel builds cause issues
- Cache `.build/` directory in CI for faster builds

---

## 🔍 Troubleshooting

### Common Issues

**Swift Build Failures**
```bash
# Clean build cache
swift package clean
rm -rf .build

# Resolve dependencies
swift package resolve
```

**Code Signing Issues**
```bash
# Validate signing setup
./test-code-signing.sh

# Check available identities
security find-identity -v -p codesigning
```

**Universal Binary Issues**
```bash
# Verify universal binary
lipo -info dist/ForceQUIT.app/Contents/MacOS/ForceQUIT

# Test on both architectures
arch -x86_64 ./build/ForceQUIT-universal
arch -arm64 ./build/ForceQUIT-universal
```

**Test Failures**
```bash
# Run specific test suite
./swift-test-suite.sh --unit-only --verbose

# Check test reports
open test-reports/test-results.html
```

### Debug Information

**Build Artifacts Locations:**
- `build/` - Build outputs
- `dist/` - Distribution packages  
- `notarized/` - Signed artifacts
- `test-reports/` - Test results
- `coverage/` - Coverage reports
- `deployment/` - Final artifacts

**Log Files:**
- CI/CD logs available in GitHub Actions
- Local build output includes timing information
- Test results saved in HTML format

---

## 📈 Build System Features

### ✅ Implemented Features
- ✅ Universal binary support (Intel + Apple Silicon)
- ✅ Debug and release build configurations
- ✅ Comprehensive test automation
- ✅ Code signing configuration system
- ✅ Multi-format distribution (ZIP, DMG, PKG)
- ✅ GitHub Actions CI/CD pipeline
- ✅ Local development tools and automation
- ✅ Build time optimization and parallel processing
- ✅ Error handling and validation
- ✅ Comprehensive documentation

### 🚀 Advanced Capabilities
- **Parallel Architecture Builds** - Build Intel and ARM64 simultaneously
- **Size Optimization** - Minimize binary size for distribution
- **Symbol Management** - Strip symbols for release, keep for debug
- **Automated Testing** - Comprehensive test suite with coverage reporting
- **Signing Automation** - Automated code signing and notarization
- **CI/CD Integration** - Full GitHub Actions workflow
- **Development Tools** - Watch mode, pre-commit hooks, continuous testing

---

## 🎯 Summary

The ForceQUIT build system is a production-ready, comprehensive solution that provides:

1. **Complete Build Coverage** - Debug, release, and universal binary builds
2. **Quality Assurance** - Automated testing with multiple test types
3. **Security** - Code signing and notarization automation
4. **Distribution** - Multiple package formats for different distribution channels
5. **Developer Experience** - Local development tools and automation
6. **CI/CD Ready** - Full GitHub Actions integration
7. **Documentation** - Comprehensive usage and troubleshooting guides

**Ready for immediate use in production environments!**

---

*Built with SWARM 2.0 AI Development Framework*  
*BUILD_SYSTEM_DEVELOPER - SWARM Agent Specialization*