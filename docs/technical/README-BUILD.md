# ForceQUIT Build & Distribution Guide

## Overview

This document provides comprehensive instructions for building, signing, notarizing, and distributing ForceQUIT using the SWARM 2.0 build system.

## Quick Start

### One-Command Build
```bash
./build-pipeline.sh
```

This executes the complete build pipeline:
1. Universal binary compilation (Intel + Apple Silicon)  
2. Code signing with Developer ID
3. Notarization with Apple
4. DMG creation for distribution

## Build Scripts

### 1. Universal Binary Builder (`build-universal.sh`)
Creates universal binary supporting both Intel and Apple Silicon architectures.

```bash
./build-universal.sh
```

**Output:** `dist/ForceQUIT.app` (Universal Binary)

### 2. Code Signing & Notarization (`code-sign-notarize.sh`)
Signs application with Developer ID and submits for Apple notarization.

```bash
# Set required environment variables
export DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)"
export APPLE_ID="your@apple.id"
export APPLE_ID_PASSWORD="app-specific-password"
export TEAM_ID="YOUR_TEAM_ID"

./code-sign-notarize.sh
```

**Output:** 
- `notarized/ForceQUIT.app` (Signed & Notarized)
- `notarized/installer/ForceQUIT-1.0.0.pkg` (Installer Package)
- `notarized/appstore/ForceQUIT-AppStore-1.0.0.pkg` (App Store Package)

### 3. DMG Creator (`create-dmg.sh`)
Creates professional distribution DMG with custom layout.

```bash
./create-dmg.sh
```

**Output:** `dist/ForceQUIT-1.0.0-Signed.dmg` or `dist/ForceQUIT-1.0.0-Unsigned.dmg`

### 4. Automated Pipeline (`build-pipeline.sh`)
Complete automated build, sign, notarize, and package pipeline.

```bash
# Full pipeline
./build-pipeline.sh

# Skip specific steps
./build-pipeline.sh --skip-signing --skip-notarization

# Verbose output
./build-pipeline.sh --verbose

# Show help
./build-pipeline.sh --help
```

## Prerequisites

### Development Environment
- **Xcode 15.0+** with Command Line Tools
- **macOS 12.0+** (for SwiftUI 3.0 features)
- **Swift 5.9+**

### Code Signing Requirements
1. **Apple Developer Account** ($99/year)
2. **Developer ID Application Certificate** installed in Keychain
3. **Developer ID Installer Certificate** (for PKG signing)
4. **App-Specific Password** for notarization

### Setting Up Code Signing

1. **Generate Certificates:**
   - Log into [Apple Developer Portal](https://developer.apple.com/)
   - Navigate to Certificates, Identifiers & Profiles
   - Create "Developer ID Application" certificate
   - Download and install in Keychain

2. **Create App-Specific Password:**
   - Visit [appleid.apple.com](https://appleid.apple.com/)
   - Go to Sign-In and Security → App-Specific Passwords
   - Generate password for "ForceQUIT Notarization"

3. **Configure Environment:**
   ```bash
   export DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)"
   export DEVELOPER_ID_INSTALLER="Developer ID Installer: Your Name (TEAMID)"  
   export APPLE_ID="your@apple.id"
   export APPLE_ID_PASSWORD="xxxx-xxxx-xxxx-xxxx"
   export TEAM_ID="YOUR_TEAM_ID"
   ```

## Build Pipeline Options

### Environment Variables
- `BUILD_NUMBER`: Build number (default: 1)
- `SKIP_TESTS`: Skip test execution (default: false)
- `SKIP_SIGNING`: Skip code signing (default: false) 
- `SKIP_NOTARIZATION`: Skip notarization (default: false)
- `SKIP_DMG`: Skip DMG creation (default: false)
- `CLEAN_BUILD`: Clean previous builds (default: true)
- `VERBOSE`: Enable verbose logging (default: false)

### Command Line Flags
```bash
--skip-tests           Skip test execution
--skip-signing         Skip code signing
--skip-notarization    Skip notarization  
--skip-dmg             Skip DMG creation
--no-clean             Don't clean previous builds
--verbose              Enable verbose logging
--help                 Show help message
```

## Distribution Targets

### 1. Direct Distribution
**Recommended for beta testing and direct downloads**

**Files:**
- `ForceQUIT-1.0.0-Signed.dmg` - Signed and notarized DMG
- `ForceQUIT-1.0.0.pkg` - Installer package

**Distribution:**
- Upload to GitHub Releases
- Host on your website
- Distribute via email/cloud storage

### 2. App Store Distribution  
**For Mac App Store submission**

**Files:**
- `ForceQUIT-AppStore-1.0.0.pkg` - App Store package

**Submission:**
1. Upload using Transporter app
2. Submit via App Store Connect
3. Wait for review (1-7 days)

### 3. Enterprise Distribution
**For organization-wide deployment**

**Files:**
- `ForceQUIT-1.0.0.pkg` - Installer package  
- Custom deployment scripts

## Build Verification

### Universal Binary Verification
```bash
# Check architecture support
file dist/ForceQUIT.app/Contents/MacOS/ForceQUIT
lipo -info dist/ForceQUIT.app/Contents/MacOS/ForceQUIT

# Expected output:
# Architectures in the fat file: ForceQUIT are: x86_64 arm64
```

### Code Signature Verification  
```bash
# Verify signature
codesign --verify --verbose=4 notarized/ForceQUIT.app

# Check notarization
spctl --assess --verbose=4 --type execute notarized/ForceQUIT.app

# Expected: "notarized/ForceQUIT.app: accepted"
```

### DMG Verification
```bash
# Verify DMG integrity
hdiutil verify dist/ForceQUIT-1.0.0-Signed.dmg

# Mount and test
hdiutil attach dist/ForceQUIT-1.0.0-Signed.dmg
```

## Troubleshooting

### Common Build Issues

**Xcode Project Not Found:**
```
❌ Xcode project not found
```
**Solution:** Ensure `ForceQUIT.xcodeproj/project.pbxproj` exists

**Source Files Missing:**
```  
❌ Main source file not found: src/Sources/main.swift
```
**Solution:** Verify source files are in `src/Sources/` directory

**Code Signing Failed:**
```
❌ Code signing failed
```
**Solutions:**
1. Verify certificates are installed in Keychain
2. Check certificate validity dates
3. Ensure correct DEVELOPER_ID_APPLICATION variable

**Notarization Failed:**
```
❌ Notarization failed
```
**Solutions:**
1. Verify Apple ID and app-specific password
2. Check Team ID matches your developer account
3. Ensure app is properly code signed first

### Build Performance
- **Clean builds:** 2-5 minutes
- **Incremental builds:** 30-60 seconds
- **Full pipeline:** 5-10 minutes (including notarization wait)

### Logs and Debugging
Build logs are automatically saved to:
- `logs/pipeline-YYYYMMDD-HHMMSS.log`
- `logs/build-report-YYYYMMDD-HHMMSS.json`

Enable verbose mode for detailed output:
```bash
./build-pipeline.sh --verbose
```

## Continuous Integration

### GitHub Actions Example
```yaml
name: Build ForceQUIT
on: [push, pull_request]

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build Universal Binary
        run: ./build-universal.sh
      - name: Upload Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: ForceQUIT-${{ github.sha }}
          path: dist/ForceQUIT.app
```

## Security Best Practices

1. **Never commit certificates** to version control
2. **Use environment variables** for sensitive data
3. **Rotate app-specific passwords** periodically
4. **Validate signatures** before distribution
5. **Test on clean systems** before release

## Support

For build issues:
1. Check this documentation
2. Review build logs in `logs/` directory  
3. Verify environment configuration
4. Test individual build scripts

---

**SWARM 2.0 Build System**  
*Transforming ideas into production-ready applications*