# Claude ForceQUIT - Simple Version

A simple macOS app that does exactly what you asked for:

## What it does
- **One button**: "Force Quit All Non-Essential Applications & Processes"
- **OK button**: Closes the app window
- **System tray icon**: Red X in circle with right-click menu
- **Smart protection**: Never kills essential system processes or development tools

## How to run

### Quick Launch (Recommended)
```bash
cd /Users/heathen-admin/Desktop/02-ForceQUIT
./quick_launch.sh
```

### Full Build (Uses your SWARM framework)
```bash
cd /Users/heathen-admin/Desktop/02-ForceQUIT
./build_and_run.sh
```

## Features

### Main Window
- Dark theme
- Simple "Force Quit All Non-Essential Applications & Processes" button
- OK button to close window
- Progress indicator while force quitting

### System Tray
- Red X in circle icon
- Right-click menu:
  - **ForceQuit**: Runs force quit operation
  - **Exit ForceQuit**: Completely quits the app

### Smart Protection
The app will NEVER kill:
- System processes (Dock, Finder, WindowServer, etc.)
- Development tools (Claude Code, Terminal, iTerm2)
- Audio/Bluetooth/Network services
- Security and kernel processes
- The ForceQUIT app itself

### Operation
1. Click the button
2. App tries graceful quit first for each non-essential app
3. If graceful quit fails, forces termination
4. Shows summary of how many apps were quit vs preserved

## Technical Details
- **Language**: Swift + SwiftUI
- **Platform**: macOS 12.0+
- **Architecture**: Single file implementation (`main.swift`)
- **Dependencies**: None (uses only built-in macOS frameworks)

This is exactly what you asked for - a simple app with a button that closes all non-essential processes!