//
//  main.swift  
//  ForceQUIT - Elegant macOS Force Quit Utility
//
//  A sleek, dark-mode force quit application for macOS
//  with safe restart capabilities and avant-garde design
//

import Foundation
import AppKit
import SwiftUI

// MARK: - ForceQUITApp

@main
struct ForceQUITApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// MARK: - Main Content View

struct ContentView: View {
    @State private var runningApps: [NSRunningApplication] = []
    @State private var isRefreshing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.95),
                    Color.gray.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Text("⚡ ForceQUIT")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Elegant Force Quit Utility")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                // Control Panel
                HStack(spacing: 15) {
                    Button(action: refreshApps) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(isRefreshing)
                    
                    Button(action: forceQuitAll) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Force Quit All")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(runningApps.isEmpty)
                }
                
                // Running Applications List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(runningApps, id: \.processIdentifier) { app in
                            AppRow(app: app) {
                                forceQuitApp(app)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(minHeight: 200, maxHeight: 400)
                
                if runningApps.isEmpty {
                    Text("No applications found")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                        .padding()
                }
                
                Spacer()
                
                // Footer
                Text("Force quit applications with caution")
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.7))
                    .padding(.bottom, 10)
            }
            .padding()
        }
        .frame(width: 450, height: 600)
        .onAppear {
            refreshApps()
        }
        .alert("ForceQUIT", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func refreshApps() {
        isRefreshing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            runningApps = NSWorkspace.shared.runningApplications
                .filter { app in
                    return app.activationPolicy == .regular &&
                           app.bundleIdentifier != Bundle.main.bundleIdentifier &&
                           !app.isHidden
                }
                .sorted { $0.localizedName ?? "" < $1.localizedName ?? "" }
            isRefreshing = false
        }
    }
    
    private func forceQuitApp(_ app: NSRunningApplication) {
        let appName = app.localizedName ?? "Unknown App"
        let success = app.forceTerminate()
        
        if success {
            alertMessage = "\(appName) was force quit successfully"
            refreshApps()
        } else {
            alertMessage = "Failed to force quit \(appName)"
        }
        showingAlert = true
    }
    
    private func forceQuitAll() {
        var quitCount = 0
        var failCount = 0
        
        for app in runningApps {
            if app.forceTerminate() {
                quitCount += 1
            } else {
                failCount += 1
            }
        }
        
        alertMessage = "Force quit \(quitCount) applications"
        if failCount > 0 {
            alertMessage += ", failed to quit \(failCount)"
        }
        
        showingAlert = true
        refreshApps()
    }
}

// MARK: - App Row Component

struct AppRow: View {
    let app: NSRunningApplication
    let onForceQuit: () -> Void
    
    var body: some View {
        HStack {
            // App icon
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .cornerRadius(6)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "app")
                            .foregroundColor(.white)
                    )
            }
            
            // App info
            VStack(alignment: .leading, spacing: 2) {
                Text(app.localizedName ?? "Unknown App")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                if let bundleID = app.bundleIdentifier {
                    Text(bundleID)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Force quit button
            Button(action: onForceQuit) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 18))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .help("Force quit this application")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
    }
}