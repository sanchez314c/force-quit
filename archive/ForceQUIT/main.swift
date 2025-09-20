import SwiftUI

// SWARM 2.0 ForceQUIT - Main Entry Point
// Phase 5: Core Implementation
// Session: FLIPPED-POLES

// @main - DISABLED: Conflicting with primary entry point in Sources/ForceQUIT/main.swift
struct ForceQUITApp_Legacy: App {
    @StateObject private var processMonitor = ProcessMonitorViewModel()
    @StateObject private var processManager = ProcessManager()
    @StateObject private var windowManager = WindowManager()
    @StateObject private var appSettings = AppSettingsViewModel()
    @StateObject private var animationController = AnimationControllerViewModel()
    @StateObject private var privilegeManager = PrivilegeManager()
    @StateObject private var securityFramework = SecurityValidationFramework.shared
    @StateObject private var authManager = AuthorizationManager.shared
    @StateObject private var sipValidator = SIPComplianceValidator.shared
    @StateObject private var performanceOptimizer = PerformanceOptimizer.shared
    
    var body: some Scene {
        WindowGroup {
            MainForceQuitView()
                .environmentObject(processMonitor)
                .environmentObject(processManager)
                .environmentObject(windowManager)
                .environmentObject(appSettings) 
                .environmentObject(animationController)
                .environmentObject(privilegeManager)
                .environmentObject(securityFramework)
                .environmentObject(authManager)
                .environmentObject(sipValidator)
                .environmentObject(performanceOptimizer)
                .preferredColorScheme(.dark)  // Enforce dark mode aesthetic
                .frame(minWidth: 800, maxWidth: 1200, minHeight: 600, maxHeight: 900)
                .onAppear {
                    setupWindowManager()
                    startProcessManager()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        
        // Menu bar functionality for quick access
        MenuBarExtra("ForceQUIT", systemImage: "xmark.app") {
            MenuBarView()
                .environmentObject(processMonitor)
                .environmentObject(processManager)
                .environmentObject(appSettings)
                .environmentObject(performanceOptimizer)
        }
    }
    
    // MARK: - Lifecycle Management
    
    private func setupWindowManager() {
        // Configure window manager when the app appears
        Task { @MainActor in
            if let window = NSApplication.shared.windows.first {
                windowManager.configureMainWindow(window)
            }
        }
    }
    
    private func startProcessManager() {
        // Start process monitoring when the app appears
        Task { @MainActor in
            processManager.startMonitoring()
        }
    }
}