#!/usr/bin/env swift

//
//  SimpleForceQUIT.swift
//  ForceQUIT - Simplified Working Version
//
//  A clean, working implementation that force quits all non-essential macOS applications
//  Dark mode, sleek design with visual feedback
//

import SwiftUI
import AppKit

@main
struct SimpleForceQUITApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Window("ForceQUIT", id: "main") {
            ContentView()
                .frame(width: 480, height: 320)
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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        NSApp.setActivationPolicy(.accessory)
    }
    
    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = createTrayIcon()
            button.action = #selector(showMainWindow)
            button.target = self
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show ForceQUIT", action: #selector(showMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quick ForceQuit All", action: #selector(quickForceQuit), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit ForceQUIT", action: #selector(quitApp), keyEquivalent: ""))
        
        statusItem?.menu = menu
    }
    
    func createTrayIcon() -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18))
        image.lockFocus()
        
        // Modern circular icon with power symbol
        let outerPath = NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: 16, height: 16))
        NSColor.systemRed.setFill()
        outerPath.fill()
        
        // Power symbol
        NSColor.white.setStroke()
        let powerPath = NSBezierPath()
        powerPath.move(to: NSPoint(x: 9, y: 5))
        powerPath.line(to: NSPoint(x: 9, y: 11))
        powerPath.lineWidth = 1.5
        powerPath.stroke()
        
        let arcPath = NSBezierPath()
        arcPath.appendArc(withCenter: NSPoint(x: 9, y: 9), radius: 3.5, startAngle: 45, endAngle: 315)
        arcPath.lineWidth = 1.5
        arcPath.stroke()
        
        image.unlockFocus()
        return image
    }
    
    @objc func showMainWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        for window in NSApp.windows {
            if window.identifier?.rawValue == "main" {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
    }
    
    @objc func quickForceQuit() {
        let _ = ForceQuitEngine.shared.executeForceQuit()
    }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

struct ContentView: View {
    @StateObject private var engine = ForceQuitEngine.shared
    @State private var showingResults = false
    
    var body: some View {
        ZStack {
            // Dark space background with subtle animation
            RadialGradient(
                colors: [Color.black.opacity(0.9), Color.black],
                center: .center,
                startRadius: 50,
                endRadius: 300
            )
            .overlay(
                // Subtle animated particles
                ForEach(0..<20, id: \.self) { _ in
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 2, height: 2)
                        .position(
                            x: CGFloat.random(in: 0...480),
                            y: CGFloat.random(in: 0...320)
                        )
                        .animation(
                            .easeInOut(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: true),
                            value: engine.isProcessing
                        )
                }
            )
            
            VStack(spacing: 40) {
                // Header with icon and title
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "power.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                            .scaleEffect(engine.isProcessing ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: engine.isProcessing)
                    }
                    
                    Text("ForceQUIT")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Elegantly close all non-essential applications")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                // Status display
                VStack(spacing: 12) {
                    HStack {
                        Circle()
                            .fill(engine.isProcessing ? Color.orange : Color.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(engine.isProcessing ? 1.3 : 1.0)
                            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: engine.isProcessing)
                        
                        Text(engine.statusMessage)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    if engine.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .red))
                    }
                }
                
                // Main action button
                Button(action: {
                    if !engine.isProcessing {
                        executeForceQuit()
                    }
                }) {
                    HStack {
                        Image(systemName: engine.isProcessing ? "stop.circle" : "power")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(engine.isProcessing ? "Processing..." : "Force Quit All Non-Essential Apps")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        engine.isProcessing ? 
                        Color.gray.opacity(0.6) : 
                        LinearGradient(colors: [Color.red, Color.red.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: engine.isProcessing ? .clear : .red.opacity(0.3), radius: 8)
                }
                .disabled(engine.isProcessing)
                .padding(.horizontal, 20)
                
                // Action buttons
                HStack(spacing: 20) {
                    Button("Hide") {
                        hideWindow()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    
                    Spacer()
                    
                    if engine.lastResult != nil {
                        Button("Show Results") {
                            showingResults = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(30)
        }
        .alert("Force Quit Complete", isPresented: $showingResults) {
            Button("OK") { showingResults = false }
        } message: {
            if let result = engine.lastResult {
                Text("\(result.message)\n\nApps closed: \(result.quitCount)\nEssential apps preserved: \(result.preservedCount)")
            }
        }
    }
    
    func executeForceQuit() {
        Task {
            let result = await engine.executeForceQuit()
            await MainActor.run {
                showingResults = true
            }
        }
    }
    
    func hideWindow() {
        NSApp.keyWindow?.close()
        NSApp.setActivationPolicy(.accessory)
    }
}

@MainActor
class ForceQuitEngine: ObservableObject {
    static let shared = ForceQuitEngine()
    
    @Published var isProcessing = false
    @Published var statusMessage = "Ready to force quit applications"
    @Published var lastResult: ForceQuitResult?
    
    private init() {}
    
    // Essential processes that should never be terminated
    private let essentialProcesses: Set<String> = [
        "kernel_task", "launchd", "UserEventAgent", "systemuiserver", 
        "Dock", "Finder", "WindowServer", "loginwindow", "cfprefsd",
        "distnoted", "coreaudiod", "bluetoothd", "WiFiAgent", "airportd",
        "networkd", "configd", "mDNSResponder", "syslogd", "Activity Monitor",
        "Console", "Terminal", "iTerm2", "Claude Code", "ForceQUIT",
        "SimpleForceQUIT"
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
        let details: [String]
    }
    
    func executeForceQuit() async -> ForceQuitResult {
        isProcessing = true
        statusMessage = "Scanning applications..."
        
        // Small delay for UI feedback
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications.filter { 
            !$0.isTerminated && $0.activationPolicy == .regular 
        }
        
        var quitCount = 0
        var preservedCount = 0
        var details: [String] = []
        var processedApps: [String] = []
        
        statusMessage = "Processing \(runningApps.count) applications..."
        
        for (index, app) in runningApps.enumerated() {
            let appName = app.localizedName ?? "Unknown App"
            
            // Update progress
            statusMessage = "Processing \(appName)... (\(index + 1)/\(runningApps.count))"
            
            if isEssentialProcess(app) {
                preservedCount += 1
                details.append("✅ Preserved: \(appName) (essential)")
                processedApps.append("✅ \(appName)")
            } else {
                // Try graceful quit first
                var success = false
                if app.terminate() {
                    success = true
                    quitCount += 1
                    details.append("🔄 Gracefully quit: \(appName)")
                    processedApps.append("🔄 \(appName)")
                } else {
                    // Force quit if graceful fails
                    if app.forceTerminate() {
                        success = true
                        quitCount += 1
                        details.append("⚡ Force quit: \(appName)")
                        processedApps.append("⚡ \(appName)")
                    } else {
                        details.append("❌ Failed to quit: \(appName)")
                        processedApps.append("❌ \(appName)")
                    }
                }
                
                // Small delay between operations for stability
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }
        
        statusMessage = "Force quit completed!"
        
        let result = ForceQuitResult(
            success: true,
            quitCount: quitCount,
            preservedCount: preservedCount,
            message: "✅ Operation completed successfully!",
            details: details
        )
        
        lastResult = result
        
        // Reset status after a delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        isProcessing = false
        statusMessage = "Ready to force quit applications"
        
        return result
    }
    
    private func isEssentialProcess(_ app: NSRunningApplication) -> Bool {
        // Check app name
        if let appName = app.localizedName {
            if essentialProcesses.contains(appName) {
                return true
            }
            
            // Check if it's our own app or development tools
            if appName.contains("ForceQUIT") || 
               appName.contains("Claude") ||
               appName.contains("Xcode") ||
               appName.contains("Terminal") {
                return true
            }
        }
        
        // Check bundle identifier
        if let bundleId = app.bundleIdentifier {
            if essentialBundleIdentifiers.contains(bundleId) {
                return true
            }
            
            // System processes (more comprehensive check)
            if bundleId.hasPrefix("com.apple.") && (
                bundleId.contains("system") || 
                bundleId.contains("kernel") ||
                bundleId.contains("audio") ||
                bundleId.contains("bluetooth") ||
                bundleId.contains("network") ||
                bundleId.contains("security") ||
                bundleId.contains("core") ||
                bundleId.contains("framework")
            ) {
                return true
            }
        }
        
        return false
    }
}