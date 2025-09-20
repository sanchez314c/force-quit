import SwiftUI
import AppKit

@main
struct ForceQUITApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Window("Claude ForceQUIT", id: "main") {
            ContentView()
                .frame(width: 500, height: 250)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        NSApp.setActivationPolicy(.accessory)
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = createTrayIcon()
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "ForceQuit", action: #selector(forceQuitAll), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Exit ForceQuit", action: #selector(quitApp), keyEquivalent: ""))
        
        statusItem?.menu = menu
    }
    
    func createTrayIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        
        let path = NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 14, height: 14))
        NSColor.red.setStroke()
        path.lineWidth = 2
        path.stroke()
        
        // Draw X
        NSColor.red.setStroke()
        let xPath1 = NSBezierPath()
        xPath1.move(to: NSPoint(x: 6, y: 6))
        xPath1.line(to: NSPoint(x: 12, y: 12))
        xPath1.lineWidth = 2
        xPath1.stroke()
        
        let xPath2 = NSBezierPath()
        xPath2.move(to: NSPoint(x: 12, y: 6))
        xPath2.line(to: NSPoint(x: 6, y: 12))
        xPath2.lineWidth = 2
        xPath2.stroke()
        
        image.unlockFocus()
        return image
    }
    
    @objc func togglePopover() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        showMainWindow()
    }
    
    @objc func forceQuitAll() {
        ForceQuitManager.shared.forceQuitAllNonEssential()
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    func showMainWindow() {
        for window in NSApp.windows {
            if window.identifier?.rawValue == "main" {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
    }
}

struct ContentView: View {
    @State private var isQuitting = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: "power.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                
                Text("Claude ForceQUIT")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Force quit all non-essential applications and processes")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Main Button
            Button(action: {
                forceQuitAllApplications()
            }) {
                HStack {
                    if isQuitting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "power")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Text(isQuitting ? "Force Quitting..." : "Force Quit All Non-Essential Applications & Processes")
                        .font(.system(size: 14, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isQuitting ? Color.gray : Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isQuitting)
            
            // OK Button
            HStack {
                Spacer()
                Button("OK") {
                    hideWindow()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
        .padding(40)
        .background(Color.black.opacity(0.9))
        .alert("Force Quit Complete", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    func forceQuitAllApplications() {
        isQuitting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = ForceQuitManager.shared.forceQuitAllNonEssential()
            
            DispatchQueue.main.async {
                isQuitting = false
                alertMessage = result.message
                showingAlert = true
            }
        }
    }
    
    func hideWindow() {
        NSApp.keyWindow?.close()
        NSApp.setActivationPolicy(.accessory)
    }
}

class ForceQuitManager {
    static let shared = ForceQuitManager()
    
    private let essentialProcesses: Set<String> = [
        "kernel_task", "launchd", "UserEventAgent", "systemuiserver", 
        "Dock", "Finder", "WindowServer", "loginwindow", "cfprefsd",
        "distnoted", "coreaudiod", "bluetoothd", "WiFiAgent", "airportd",
        "networkd", "configd", "mDNSResponder", "syslogd", "Claude Code",
        "Terminal", "iTerm2", "Activity Monitor", "Console", "ForceQUIT",
        "Claude ForceQUIT"
    ]
    
    private let essentialBundleIdentifiers: Set<String> = [
        "com.apple.dock", "com.apple.finder", "com.apple.systemuiserver",
        "com.apple.loginwindow", "com.apple.WindowServer", "com.apple.audio.coreaudiod",
        "com.apple.bluetoothd", "com.apple.configd", "com.apple.mDNSResponder",
        "com.anthropic.claudecode", "com.apple.Terminal", "com.googlecode.iterm2",
        "com.apple.ActivityMonitor", "com.apple.Console"
    ]
    
    struct ForceQuitResult {
        let success: Bool
        let quitCount: Int
        let preservedCount: Int
        let message: String
    }
    
    func forceQuitAllNonEssential() -> ForceQuitResult {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications.filter { 
            !$0.isTerminated && $0.activationPolicy == .regular 
        }
        
        var quitCount = 0
        var preservedCount = 0
        
        for app in runningApps {
            if isEssentialProcess(app) {
                preservedCount += 1
                continue
            }
            
            // Try graceful quit first
            if app.terminate() {
                quitCount += 1
            } else {
                // Force quit if graceful fails
                if app.forceTerminate() {
                    quitCount += 1
                }
            }
            
            // Small delay between quits
            usleep(100000) // 0.1 seconds
        }
        
        return ForceQuitResult(
            success: true,
            quitCount: quitCount,
            preservedCount: preservedCount,
            message: "Force quit completed!\n\nApplications quit: \(quitCount)\nEssential apps preserved: \(preservedCount)"
        )
    }
    
    private func isEssentialProcess(_ app: NSRunningApplication) -> Bool {
        // Check app name
        if let appName = app.localizedName {
            if essentialProcesses.contains(appName) {
                return true
            }
            
            // Check if it's our own app
            if appName.contains("ForceQUIT") || appName.contains("Claude") {
                return true
            }
        }
        
        // Check bundle identifier
        if let bundleId = app.bundleIdentifier {
            if essentialBundleIdentifiers.contains(bundleId) {
                return true
            }
            
            // System processes
            if bundleId.hasPrefix("com.apple.") && (
                bundleId.contains("system") || 
                bundleId.contains("kernel") ||
                bundleId.contains("audio") ||
                bundleId.contains("bluetooth") ||
                bundleId.contains("network") ||
                bundleId.contains("security")
            ) {
                return true
            }
        }
        
        return false
    }
}