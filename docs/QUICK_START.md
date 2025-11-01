# Quick Start Guide

Get up and running with ForceQUIT in under 5 minutes.

## Installation

### Option 1: Download from App Store (Recommended)
1. Open App Store on your Mac
2. Search for "ForceQUIT"
3. Click "Get" or price button to download
4. Wait for installation to complete

### Option 2: Direct Download
1. Visit [ForceQUIT website](https://forcequit.app)
2. Download the latest version
3. Double-click the downloaded `.dmg` file
4. Drag ForceQUIT to Applications folder

## First Launch Setup

### Grant Permissions
1. Launch ForceQUIT from Applications folder
2. System will prompt for Accessibility permissions
3. Click "Open System Preferences"
4. Check the box next to ForceQUIT
5. Enter your password when prompted

### Verify Installation
1. ForceQUIT icon should appear in Dock
2. Application window opens showing running processes
3. Menu bar icon appears (if enabled)

## Basic Usage

### Force Quit an Application
1. **Select Application**: Click on the unresponsive app in the process list
2. **Review Details**: Check process information in the detail panel
3. **Force Quit**: Click the red "Force Quit" button
4. **Confirm**: Click "Force Quit" in the confirmation dialog

### Safe Restart an Application
1. **Select Application**: Choose the application from the list
2. **Safe Restart**: Click the blue "Safe Restart" button
3. **Wait**: Application will attempt to save state and restart

### Keyboard Shortcuts
- **⌘ + Q**: Force Quit selected application
- **⌘ + R**: Safe Restart selected application
- **⌘ + F**: Search/filter applications
- **⌘ + .**: Refresh process list

## Common Scenarios

### Frozen Application
```bash
# When an app is completely unresponsive:
1. Select the frozen application
2. Click "Force Quit" (red button)
3. Confirm the action
4. Application will terminate immediately
```

### Memory-Intensive Application
```bash
# When an app is using too much memory:
1. Look at the Memory column in process list
2. Select high-memory usage application
3. Use "Safe Restart" to preserve data
4. Monitor memory usage after restart
```

### Multiple Unresponsive Applications
```bash
# When several apps are frozen:
1. Use ⌘ + Click to select multiple applications
2. Review selected applications in detail panel
3. Click "Force Quit All" (appears with multiple selections)
4. Confirm batch operation
```

## Interface Overview

### Main Window
- **Process List**: All running applications with resource usage
- **Detail Panel**: Information about selected application
- **Action Buttons**: Force Quit, Safe Restart, etc.
- **Search Bar**: Filter applications by name
- **Status Bar**: System resource overview

### Menu Bar
- **Quick Access**: Launch ForceQUIT from menu bar
- **System Monitor**: View system resource usage
- **Recent Applications**: Quick access to recently used apps
- **Preferences**: Access application settings

## Troubleshooting

### Permission Issues
**Problem**: ForceQUIT can't see or terminate applications
**Solution**: 
1. Open System Preferences → Security & Privacy → Privacy
2. Select "Accessibility" from left panel
3. Check if ForceQUIT is enabled
4. If not, click the lock icon and add ForceQUIT

### Application Not Listed
**Problem**: Specific application doesn't appear in list
**Solution**:
1. Click "Refresh" button (⌘ + R)
2. Check if application is actually running
3. Verify ForceQUIT has proper permissions
4. Restart ForceQUIT if needed

### Force Quit Fails
**Problem**: Clicking Force Quit doesn't work
**Solution**:
1. Try "Safe Restart" instead
2. Check if application has higher privileges
3. Restart ForceQUIT with administrator privileges
4. Use Activity Monitor as fallback

## Next Steps

### Customize Your Experience
- Open Preferences to customize interface
- Set up keyboard shortcuts
- Configure notification preferences
- Enable menu bar integration

### Learn Advanced Features
- Read the [User Guide](API.md) for detailed features
- Check [Troubleshooting Guide](TROUBLESHOOTING.md) for common issues
- Explore [Development Documentation](DEVELOPMENT.md) if you're a developer

### Get Help
- Visit our [FAQ](FAQ.md) for common questions
- Report issues on GitHub
- Join our community forum

## Tips & Tricks

### Productivity Tips
- **Use Search**: Type application name to quickly find it
- **Keyboard Navigation**: Use arrow keys to navigate process list
- **Batch Operations**: Select multiple apps with ⌘ + Click
- **Resource Monitoring**: Keep an eye on CPU and Memory columns

### Safety Tips
- **Save Work**: Always save important work before force quitting
- **Check Dependencies**: Some apps depend on others - restart in order
- **System Processes**: Never force quit system processes (protected automatically)
- **Backup Data**: Regular backups prevent data loss

### Performance Tips
- **Close Unused Apps**: Free up system resources
- **Monitor Memory**: Watch for memory leaks in applications
- **Regular Restarts**: Restart applications periodically to clear memory
- **System Updates**: Keep macOS updated for best performance

---

**Need more help?** Check our complete [Documentation Index](DOCUMENTATION_INDEX.md) or contact support.