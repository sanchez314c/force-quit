# Frequently Asked Questions (FAQ)

## General Questions

### What is ForceQUIT?
ForceQUIT is a sophisticated macOS force quit utility built with Swift and SwiftUI that provides users with an elegant force quit solution with safe restart capabilities, process management, and system monitoring features.

### Is ForceQUIT safe to use?
Yes. ForceQUIT is built with security-first principles and respects System Integrity Protection (SIP). It never terminates system-critical processes and operates within App Store sandbox constraints.

### What are the system requirements?
- macOS 12.0+ (Monterey or later)
- Apple Silicon (M1/M2/M3) or Intel Mac
- Administrator privileges for process termination

## Installation & Setup

### How do I install ForceQUIT?
See the [Installation Guide](INSTALLATION.md) for detailed installation instructions.

### Do I need to grant permissions?
Yes, ForceQUIT requires Accessibility permissions to monitor and terminate applications. You'll be prompted to grant these permissions on first launch.

### Why does ForceQUIT need Accessibility permissions?
Accessibility permissions are required to:
- Monitor running applications
- Send termination signals to processes
- Provide safe restart functionality

## Usage

### How do I force quit an application?
1. Launch ForceQUIT
2. Select the application from the process list
3. Click "Force Quit" or use the keyboard shortcut
4. Confirm the action when prompted

### What's the difference between "Force Quit" and "Safe Restart"?
- **Force Quit**: Immediately terminates the application without saving
- **Safe Restart**: Attempts to save application state before restarting

### Can ForceQUIT terminate system processes?
No. ForceQUIT automatically filters and protects system-critical processes to maintain system stability.

## Troubleshooting

### ForceQUIT can't terminate a specific application
1. Check if the application has higher privileges
2. Verify ForceQUIT has Accessibility permissions
3. Try restarting ForceQUIT with administrator privileges

### The process list is empty
1. Check Accessibility permissions in System Preferences
2. Restart ForceQUIT
3. Restart your Mac if the issue persists

### ForceQUIT crashes on launch
1. Check if you're running a supported macOS version
2. Verify the app signature isn't corrupted
3. Reinstall ForceQUIT if necessary

## Security & Privacy

### Does ForceQUIT collect data?
No. ForceQUIT operates entirely locally and doesn't collect or transmit any user data.

### Is ForceQUIT notarized?
Yes. ForceQUIT is signed and notarized by Apple for secure distribution.

## Development

### How can I contribute to ForceQUIT?
See the [Contributing Guide](CONTRIBUTING.md) for information on contributing to the project.

### Where can I report bugs?
Report bugs through GitHub Issues using the provided bug report template.

### Can I build ForceQUIT from source?
Yes. See the [Development Guide](DEVELOPMENT.md) for build instructions.

## Licensing

### What license does ForceQUIT use?
ForceQUIT is released under the MIT License. See the LICENSE file for details.

### Can I use ForceQUIT in commercial projects?
Yes. The MIT License permits commercial use with proper attribution.

---

Still have questions? Check our [Documentation Index](DOCUMENTATION_INDEX.md) or open an issue on GitHub.