# Installation Guide

🚀 **ForceQUIT Installation Instructions**

This guide covers the various ways to install ForceQUIT on your Mac.

## 📋 System Requirements

- **Operating System**: macOS 12.0 (Monterey) or later
- **Architecture**: Intel Mac or Apple Silicon (M1/M2/M3)
- **Memory**: 4GB RAM minimum
- **Storage**: 50MB free space
- **Permissions**: Administrator access for installation

## 🎯 Installation Methods

### Method 1: Direct Download (Recommended)

1. **Download the latest release**:
   - Visit [Releases Page](https://github.com/username/force-quit/releases)
   - Download `ForceQUIT.dmg`

2. **Install the application**:
   ```bash
   # Mount the DMG
   hdiutil attach ForceQUIT.dmg

   # Copy to Applications
   sudo cp -R "/Volumes/ForceQUIT/ForceQUIT.app" /Applications/

   # Set permissions
   sudo chown -R root:wheel "/Applications/ForceQUIT.app"

   # Unmount
   hdiutil detach "/Volumes/ForceQUIT"
   ```

3. **Launch the application**:
   - Open Finder → Applications
   - Double-click ForceQUIT

### Method 2: Homebrew

1. **Install via Homebrew**:
   ```bash
   # Install the formula
   brew install --cask forcequit

   # Or install from tap if available
   brew install username/tap/forcequit
   ```

2. **Launch**:
   ```bash
   open -a ForceQUIT
   ```

### Method 3: Build from Source

1. **Clone the repository**:
   ```bash
   git clone https://github.com/username/force-quit.git
   cd force-quit
   ```

2. **Install dependencies**:
   ```bash
   # Run setup script
   ./setup.sh

   # Or manually install if script fails
   xcode-select --install
   ```

3. **Build and install**:
   ```bash
   # Build the application
   ./scripts/build.sh --universal --dmg

   # Install the DMG
   hdiutil attach dist/ForceQUIT.dmg
   sudo cp -R "/Volumes/ForceQUIT/ForceQUIT.app" /Applications/
   hdiutil detach "/Volumes/ForceQUIT"
   ```

## 🔧 First-Time Setup

### Granting Permissions

On first launch, ForceQUIT may request several permissions:

1. **Accessibility Access**:
   - Go to System Preferences → Security & Privacy → Privacy
   - Select "Accessibility" from the left
   - Click the lock and enter your password
   - Check the box next to ForceQUIT

2. **System Events Access**:
   - Same location as above
   - Select "System Events" from the left
   - Check the box next to ForceQUIT

3. **Full Disk Access** (optional):
   - For enhanced functionality
   - Select "Full Disk Access" from the left
   - Check the box next to ForceQUIT

### Verification

1. **Check the installation**:
   ```bash
   # Verify app exists
   ls -la /Applications/ForceQUIT.app

   # Check code signature (if signed)
   codesign -vvv /Applications/ForceQUIT.app
   ```

2. **Test basic functionality**:
   - Launch ForceQUIT
   - Try quitting a simple application
   - Verify the process termination works

## 🔄 Updates

### Automatic Updates

ForceQUIT includes an automatic update mechanism:

1. **Check for updates**:
   - Open ForceQUIT
   - Click "Check for Updates" in the menu
   - Follow the prompts to update

2. **Manual update**:
   ```bash
   # Download latest version
   curl -L -o ForceQUIT.dmg "https://github.com/username/force-quit/releases/latest/download/ForceQUIT.dmg"

   # Install update
   hdiutil attach ForceQUIT.dmg
   sudo rm -rf /Applications/ForceQUIT.app
   sudo cp -R "/Volumes/ForceQUIT/ForceQUIT.app" /Applications/
   hdiutil detach "/Volumes/ForceQUIT"
   ```

### Homebrew Updates

```bash
# Update Homebrew
brew update

# Upgrade ForceQUIT
brew upgrade --cask forcequit
```

## 🗑️ Uninstallation

### Method 1: Manual Removal

1. **Remove the application**:
   ```bash
   # Remove app bundle
   sudo rm -rf /Applications/ForceQUIT.app

   # Remove support files
   rm -rf ~/Library/Application\ Support/ForceQUIT
   rm -rf ~/Library/Preferences/com.forcequit.app.plist
   rm -rf ~/Library/Caches/com.forcequit.app
   ```

2. **Remove permissions**:
   - Go to System Preferences → Security & Privacy → Privacy
   - Remove ForceQUIT from all permission lists

### Method 2: Homebrew

```bash
# Uninstall via Homebrew
brew uninstall --cask forcequit
```

## 🔍 Troubleshooting

### Common Issues

1. **"App can't be opened because Apple cannot check it for malicious software"**:
   ```bash
   # Allow the app to run
   xattr -rd com.apple.quarantine /Applications/ForceQUIT.app
   ```

2. **"ForceQUIT is damaged and can't be opened"**:
   ```bash
   # Clear quarantine attribute
   xattr -cr /Applications/ForceQUIT.app
   ```

3. **Permission denied errors**:
   - Ensure the app has necessary permissions
   - Try running with administrator privileges
   - Check System Preferences for permission settings

4. **App won't launch**:
   ```bash
   # Check system logs
   log show --predicate 'subsystem == "com.forcequit.app"' --last 5m

   # Try launching from terminal
   open -a ForceQUIT
   ```

### Getting Help

If you encounter installation issues:

1. **Check the logs**:
   ```bash
   # View app logs
   log stream --predicate 'subsystem == "com.forcequit.app"'

   # Check crash reports
   ls -la ~/Library/Logs/DiagnosticReports/ForceQUIT*
   ```

2. **Verify system compatibility**:
   ```bash
   # Check macOS version
   sw_vers

   # Check architecture
   uname -m
   ```

3. **Report issues**:
   - Visit [GitHub Issues](https://github.com/username/force-quit/issues)
   - Include system information and error messages
   - Attach relevant logs if possible

## 🔐 Security

### Code Signing Verification

Verify the app is properly signed:

```bash
# Check signature
codesign -dv --verbose=4 /Applications/ForceQUIT.app

# Verify notarization (if applicable)
spctl -a -vv /Applications/ForceQUIT.app
```

### Security Best Practices

1. **Download from official sources only**
2. **Verify code signatures** after installation
3. **Keep the app updated** to the latest version
4. **Review permission requests** carefully

## 📚 Additional Resources

- [User Guide](guide/README.md) - Learn how to use ForceQUIT
- [Development Guide](DEVELOPMENT.md) - For developers
- [Contributing Guidelines](CONTRIBUTING.md) - For contributors
- [GitHub Repository](https://github.com/username/force-quit) - Source code and issues

---

For installation support, please open an issue on GitHub.