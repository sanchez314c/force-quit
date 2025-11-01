# Troubleshooting Guide

Solutions to common issues with ForceQUIT.

## Installation Issues

### ForceQUIT Won't Install

#### Problem: "ForceQUIT can't be opened because Apple cannot check it for malicious software"
**Cause**: macOS security settings blocking unsigned apps
**Solution**:
1. Open System Preferences → Security & Privacy
2. Go to the "General" tab
3. Find the message about ForceQUIT
4. Click "Open Anyway"
5. Enter your password when prompted

#### Problem: "The application is damaged and can't be opened"
**Cause**: Corrupted download or incomplete installation
**Solution**:
1. Delete the current ForceQUIT application
2. Clear browser cache and download again
3. Verify the download completed successfully
4. Try installation from a different browser

#### Problem: Installation fails with permission error
**Cause**: Insufficient permissions to write to Applications folder
**Solution**:
1. Drag ForceQUIT to Desktop first
2. Open Finder and go to Applications folder
3. Drag ForceQUIT from Desktop to Applications
4. Enter administrator password when prompted

## Permission Issues

### ForceQUIT Can't See Applications

#### Problem: Process list is empty or incomplete
**Cause**: Missing Accessibility permissions
**Solution**:
1. Open System Preferences → Security & Privacy → Privacy
2. Select "Accessibility" from the left panel
3. Click the lock icon and enter your password
4. Check the box next to ForceQUIT
5. Restart ForceQUIT

#### Problem: ForceQUIT can't terminate specific applications
**Cause**: Application has higher privileges or is protected
**Solution**:
1. Try running ForceQUIT as administrator
2. Check if the application is system-protected
3. Use Activity Monitor as fallback for system processes
4. Restart your Mac and try again

### Permission Keeps Getting Reset

#### Problem: Accessibility permissions keep disabling
**Cause**: System security software or macOS updates
**Solution**:
1. Check if security software is blocking permissions
2. Reset permissions after macOS updates
3. Add ForceQUIT to security software whitelist
4. Consider reinstalling ForceQUIT

## Performance Issues

### ForceQUIT is Slow

#### Problem: Application takes long time to launch
**Cause**: Large number of running processes or system load
**Solution**:
1. Close unnecessary applications
2. Restart ForceQUIT after system startup
3. Check for macOS updates
4. Restart your Mac if performance is poor

#### Problem: Process list updates slowly
**Cause**: High system load or resource-intensive applications
**Solution**:
1. Use the search/filter feature to find specific apps
2. Close resource-intensive applications
3. Check Activity Monitor for system bottlenecks
4. Consider restarting ForceQUIT

#### Problem: UI becomes unresponsive
**Cause**: Memory issues or application conflicts
**Solution**:
1. Force quit ForceQUIT itself using Activity Monitor
2. Restart ForceQUIT
3. Check available system memory
4. Disable other system monitoring utilities

## Application-Specific Issues

### Can't Force Quit Specific Application

#### Problem: Safari won't force quit
**Cause**: Safari has system-level protections
**Solution**:
1. Try "Safe Restart" instead of "Force Quit"
2. Close all Safari windows first
3. Use Activity Monitor as alternative
4. Restart your Mac if necessary

#### Problem: Terminal processes won't terminate
**Cause**: Terminal processes may have child processes
**Solution**:
1. Use "Safe Restart" to handle child processes
2. Check for background shell processes
3. Use Terminal commands: `killall process-name`
4. Restart Terminal application

#### Problem: Development tools (Xcode, etc.) won't quit
**Cause**: Development tools often have complex process trees
**Solution**:
1. Save your work first
2. Use "Safe Restart" to preserve project state
3. Force quit child processes first
4. Use Activity Monitor for complex process trees

## System Integration Issues

### Menu Bar Icon Missing

#### Problem: ForceQUIT menu bar icon doesn't appear
**Cause**: Menu bar is full or icon is disabled
**Solution**:
1. Check ForceQUIT preferences for menu bar setting
2. Hold ⌘ and drag menu bar icons to rearrange
3. Remove unused menu bar icons to make space
4. Restart ForceQUIT

#### Problem: Menu bar icon is unresponsive
**Cause**: Application freeze or system issue
**Solution**:
1. Option + Click the icon to force menu refresh
2. Restart ForceQUIT from Activity Monitor
3. Restart your Mac if the issue persists
4. Check for macOS updates

### Keyboard Shortcuts Not Working

#### Problem: Keyboard shortcuts don't respond
**Cause**: Shortcuts disabled or conflicting with other apps
**Solution**:
1. Check ForceQUIT preferences for shortcut settings
2. Look for shortcut conflicts in System Preferences
3. Restart ForceQUIT to refresh shortcuts
4. Try different shortcut combinations

#### Problem: Global shortcuts don't work when ForceQUIT is not frontmost
**Cause**: Accessibility permissions or system settings
**Solution**:
1. Verify Accessibility permissions are enabled
2. Check System Preferences → Keyboard → Shortcuts
3. Ensure ForceQUIT is in Accessibility list
4. Restart ForceQUIT with administrator privileges

## Crash and Error Issues

### ForceQUIT Crashes on Launch

#### Problem: Application crashes immediately when opened
**Cause**: Corrupted preferences or system incompatibility
**Solution**:
1. Delete ForceQUIT preferences: `~/Library/Preferences/com.forcequit.plist`
2. Reset Accessibility permissions
3. Check macOS compatibility (requires macOS 12.0+)
4. Reinstall ForceQUIT

#### Problem: Random crashes during use
**Cause**: Memory issues or application conflicts
**Solution**:
1. Check available system memory
2. Disable other system monitoring utilities
3. Update to latest ForceQUIT version
4. Report crash with details to developers

### Error Messages

#### Problem: "Insufficient permissions to terminate process"
**Cause**: Process has higher privileges than ForceQUIT
**Solution**:
1. Run ForceQUIT as administrator
2. Use Activity Monitor with administrator privileges
3. Restart your Mac and try again
4. Check if process is system-protected

#### Problem: "Process not found or already terminated"
**Cause**: Process terminated between listing and action
**Solution**:
1. Refresh process list (⌘ + R)
2. This is normal behavior - no action needed
3. Check if application successfully terminated
4. Look for the application in the updated list

## Network and Update Issues

### Can't Check for Updates

#### Problem: Update check fails with network error
**Cause**: Network connectivity or firewall issues
**Solution**:
1. Check internet connection
2. Disable VPN and try again
3. Check firewall settings
4. Try manual download from website

#### Problem: Update download fails
**Cause**: Server issues or interrupted download
**Solution**:
1. Wait a few minutes and try again
2. Check ForceQUIT website for manual download
3. Clear download cache and retry
4. Use different network connection

## Data and Settings Issues

### Settings Not Saving

#### Problem: Preferences reset after restart
**Cause**: Permissions issue or corrupted preferences
**Solution**:
1. Check ForceQUIT has write permissions
2. Delete corrupted preferences file
3. Reset permissions on preferences folder
4. Reinstall ForceQUIT if necessary

### Lost Application Data

#### Problem: Application state lost after force quit
**Cause**: Force quit doesn't save application state
**Solution**:
1. Use "Safe Restart" instead of "Force Quit"
2. Save work before force quitting applications
3. Enable auto-save in target applications
4. Use application-specific recovery features

## Getting Help

### Collecting Information for Support

When reporting issues, include:
1. **macOS Version**: From Apple menu → About This Mac
2. **ForceQUIT Version**: From ForceQUIT → About
3. **Error Message**: Exact text of any error messages
4. **Steps to Reproduce**: Detailed steps that cause the issue
5. **System Information**: Available memory, disk space, etc.

### Contact Options

- **GitHub Issues**: Report bugs and feature requests
- **Support Email**: For technical support and questions
- **Community Forum**: For user-to-user help
- **Documentation**: Check [FAQ](FAQ.md) for common questions

### Emergency Procedures

If ForceQUIT causes system instability:
1. **Force Quit ForceQUIT**: Use Activity Monitor to terminate ForceQUIT
2. **Safe Mode**: Restart Mac in Safe Mode to troubleshoot
3. **System Restore**: Use Time Machine if system is unstable
4. **Contact Support**: Reach out for immediate assistance

---

**Still having issues?** Check our [FAQ](FAQ.md) or [Documentation Index](DOCUMENTATION_INDEX.md) for more resources.