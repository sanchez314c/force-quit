import Foundation
import AppKit
import OSLog

// SWARM 2.0 ForceQUIT - Safe Restart Engine
// Intelligent restart capabilities with state preservation

@MainActor
class SafeRestartEngine: ObservableObject {
    // MARK: - Published Properties
    @Published var isRestarting: Bool = false
    @Published var restartProgress: Double = 0.0
    @Published var currentOperation: String = ""
    @Published var restartHistory: [RestartRecord] = []
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.forceQUIT.app", category: "SafeRestart")
    private let workspace = NSWorkspace.shared
    private var activeRestartTasks: [ProcessInfo.ID: Task<Void, Never>] = [:]
    
    // Apps known to support state restoration
    private let stateRestorationSupportedApps: Set<String> = [
        "com.apple.Safari",
        "com.apple.TextEdit",
        "com.apple.Preview",
        "com.apple.Terminal",
        "com.microsoft.VSCode",
        "com.google.Chrome",
        "com.brave.Browser",
        "com.apple.dt.Xcode",
        "com.apple.Notes",
        "com.apple.Mail",
        "com.apple.Finder"
    ]
    
    // Apps with custom restart methods
    private let customRestartHandlers: [String: (ProcessInfo) async -> RestartResult] = [:]
    
    init() {
        loadRestartHistory()
    }
    
    // MARK: - Public Interface
    
    /// Check if an application can be safely restarted
    func canSafelyRestart(_ process: ProcessInfo) -> Bool {
        guard let bundleId = process.bundleIdentifier else { return false }
        
        // Check if app supports state restoration
        if stateRestorationSupportedApps.contains(bundleId) {
            return true
        }
        
        // Check if we have a custom restart handler
        if customRestartHandlers.keys.contains(bundleId) {
            return true
        }
        
        // Check if app is a document-based app
        if isDocumentBasedApp(bundleId) {
            return true
        }
        
        return false
    }
    
    /// Perform safe restart of a single application
    func safeRestart(_ process: ProcessInfo) async -> RestartResult {
        guard canSafelyRestart(process) else {
            logger.warning("Application \\(process.name) does not support safe restart")
            return .notSupported
        }
        
        logger.info("Starting safe restart for \\(process.name)")
        
        // Check if already restarting
        if activeRestartTasks[process.id] != nil {
            return .alreadyInProgress
        }
        
        let task = Task {
            await performRestart(process)
        }
        
        activeRestartTasks[process.id] = task
        await task.value
        activeRestartTasks.removeValue(forKey: process.id)
        
        return .success
    }
    
    /// Perform batch safe restart of multiple applications
    func batchSafeRestart(_ processes: [ProcessInfo]) async -> [ProcessInfo.ID: RestartResult] {
        isRestarting = true
        restartProgress = 0.0
        currentOperation = "Preparing restart operations..."
        
        var results: [ProcessInfo.ID: RestartResult] = [:]
        let supportedProcesses = processes.filter { canSafelyRestart($0) }
        
        logger.info("Starting batch restart for \\(supportedProcesses.count) applications")
        
        for (index, process) in supportedProcesses.enumerated() {
            currentOperation = "Restarting \\(process.name)..."
            restartProgress = Double(index) / Double(supportedProcesses.count)
            
            let result = await safeRestart(process)
            results[process.id] = result
            
            // Small delay between restarts to avoid system overload
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        currentOperation = "Restart complete"
        restartProgress = 1.0
        
        // Reset state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isRestarting = false
            self.restartProgress = 0.0
            self.currentOperation = ""
        }
        
        return results
    }
    
    // MARK: - Private Implementation
    
    private func performRestart(_ process: ProcessInfo) async {
        var restartRecord = RestartRecord(
            processId: process.id,
            processName: process.name,
            bundleIdentifier: process.bundleIdentifier,
            startTime: Date()
        )
        
        do {
            // Step 1: Capture application state
            currentOperation = "Capturing state for \\(process.name)..."
            let appState = await captureApplicationState(process)
            
            // Step 2: Graceful termination
            currentOperation = "Terminating \\(process.name)..."
            let terminationSuccess = await gracefulTermination(process)
            
            if !terminationSuccess {
                logger.error("Failed to terminate \\(process.name)")
                restartRecord.result = .terminationFailed
                restartRecord.endTime = Date()
                addRestartRecord(restartRecord)
                return
            }
            
            // Step 3: Wait for complete shutdown
            await waitForProcessShutdown(process)
            
            // Step 4: Restart application
            currentOperation = "Restarting \\(process.name)..."
            let launchSuccess = await launchApplication(process)
            
            if !launchSuccess {
                logger.error("Failed to launch \\(process.name)")
                restartRecord.result = .launchFailed
                restartRecord.endTime = Date()
                addRestartRecord(restartRecord)
                return
            }
            
            // Step 5: Restore application state (if supported)
            if let state = appState {
                currentOperation = "Restoring state for \\(process.name)..."
                await restoreApplicationState(process, state: state)
            }
            
            restartRecord.result = .success
            restartRecord.endTime = Date()
            addRestartRecord(restartRecord)
            
            logger.info("Safe restart completed for \\(process.name)")
            
        } catch {
            logger.error("Safe restart failed for \\(process.name): \\(error.localizedDescription)")
            restartRecord.result = .error(error.localizedDescription)
            restartRecord.endTime = Date()
            addRestartRecord(restartRecord)
        }
    }
    
    private func captureApplicationState(_ process: ProcessInfo) async -> ApplicationState? {
        guard let bundleId = process.bundleIdentifier else { return nil }
        
        var state = ApplicationState(bundleIdentifier: bundleId)
        
        // Capture window positions and states
        if let runningApp = workspace.runningApplications.first(where: { $0.processIdentifier == process.pid }) {
            // Use Accessibility API to get window information
            let windows = getWindowsForApplication(runningApp)
            state.windowStates = windows
        }
        
        // Capture document information for document-based apps
        if isDocumentBasedApp(bundleId) {
            state.openDocuments = getOpenDocuments(for: process)
        }
        
        // App-specific state capture
        switch bundleId {
        case "com.apple.Safari":
            state.customData = await captureSafariState(process)
        case "com.apple.Terminal":
            state.customData = await captureTerminalState(process)
        default:
            break
        }
        
        return state
    }
    
    private func gracefulTermination(_ process: ProcessInfo) async -> Bool {
        guard let app = workspace.runningApplications.first(where: { 
            $0.processIdentifier == process.pid 
        }) else {
            return false
        }
        
        // Try Apple Events first for supported apps
        if let bundleId = process.bundleIdentifier,
           supportsAppleEvents(bundleId) {
            let success = await sendQuitAppleEvent(to: app)
            if success {
                return true
            }
        }
        
        // Fall back to standard termination
        return app.terminate()
    }
    
    private func waitForProcessShutdown(_ process: ProcessInfo) async {
        let timeout = Date().addingTimeInterval(10.0) // 10 second timeout
        
        while Date() < timeout {
            let isRunning = workspace.runningApplications.contains { 
                $0.processIdentifier == process.pid 
            }
            
            if !isRunning {
                break
            }
            
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    
    private func launchApplication(_ process: ProcessInfo) async -> Bool {
        guard let bundleId = process.bundleIdentifier else { return false }
        
        do {
            guard let url = try await workspace.urlForApplication(withBundleIdentifier: bundleId) else {
                return false
            }
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.createsNewApplicationInstance = false

            _ = try await workspace.openApplication(at: url, configuration: configuration)
            return true
            
        } catch {
            logger.error("Failed to launch application \\(bundleId): \\(error)")
            return false
        }
    }
    
    private func restoreApplicationState(_ process: ProcessInfo, state: ApplicationState) async {
        // Basic window restoration
        if !state.windowStates.isEmpty {
            await restoreWindowPositions(for: process, windows: state.windowStates)
        }
        
        // Document restoration
        if !state.openDocuments.isEmpty {
            await restoreDocuments(for: process, documents: state.openDocuments)
        }
        
        // Custom state restoration
        if let customData = state.customData {
            await restoreCustomState(for: process, data: customData)
        }
    }
    
    // MARK: - Helper Methods
    
    private func isDocumentBasedApp(_ bundleIdentifier: String) -> Bool {
        // Check if app declares document types in its Info.plist
        // This is a simplified check
        let documentBasedApps = [
            "com.apple.TextEdit",
            "com.apple.Preview",
            "com.apple.dt.Xcode",
            "com.microsoft.Word",
            "com.adobe.Photoshop"
        ]
        
        return documentBasedApps.contains(bundleIdentifier)
    }
    
    private func supportsAppleEvents(_ bundleIdentifier: String) -> Bool {
        let appleEventApps = [
            "com.apple.Safari",
            "com.apple.Terminal",
            "com.apple.TextEdit",
            "com.apple.Finder"
        ]
        
        return appleEventApps.contains(bundleIdentifier)
    }
    
    private func getWindowsForApplication(_ app: NSRunningApplication) -> [WindowState] {
        // This would use Accessibility APIs to get window information
        // Simplified implementation
        return []
    }
    
    private func getOpenDocuments(for process: ProcessInfo) -> [DocumentState] {
        // This would use various methods to determine open documents
        // Simplified implementation
        return []
    }
    
    private func sendQuitAppleEvent(to app: NSRunningApplication) async -> Bool {
        // Send quit Apple Event
        // This would use NSAppleEventDescriptor
        // Simplified implementation
        return false
    }
    
    private func captureSafariState(_ process: ProcessInfo) async -> [String: Any] {
        // Capture Safari-specific state (tabs, windows, etc.)
        return [:]
    }
    
    private func captureTerminalState(_ process: ProcessInfo) async -> [String: Any] {
        // Capture Terminal-specific state (tabs, sessions, etc.)
        return [:]
    }
    
    private func restoreWindowPositions(for process: ProcessInfo, windows: [WindowState]) async {
        // Restore window positions using Accessibility APIs
    }
    
    private func restoreDocuments(for process: ProcessInfo, documents: [DocumentState]) async {
        // Reopen documents
    }
    
    private func restoreCustomState(for process: ProcessInfo, data: [String: Any]) async {
        // App-specific state restoration
    }
    
    // MARK: - History Management
    
    private func loadRestartHistory() {
        // Load restart history from UserDefaults or file
        // Simplified implementation
        restartHistory = []
    }
    
    private func addRestartRecord(_ record: RestartRecord) {
        restartHistory.append(record)
        
        // Keep only last 100 records
        if restartHistory.count > 100 {
            restartHistory = Array(restartHistory.suffix(100))
        }
        
        // Save to persistent storage
        saveRestartHistory()
    }
    
    private func saveRestartHistory() {
        // Save restart history to UserDefaults or file
        // Simplified implementation
    }
}

// MARK: - Supporting Types

struct ApplicationState {
    let bundleIdentifier: String
    var windowStates: [WindowState] = []
    var openDocuments: [DocumentState] = []
    var customData: [String: Any]?
}

struct WindowState {
    let windowId: Int
    let frame: CGRect
    let isMinimized: Bool
    let isFullScreen: Bool
}

struct DocumentState {
    let path: String
    let isModified: Bool
}

struct RestartRecord {
    let id = UUID()
    let processId: ProcessInfo.ID
    let processName: String
    let bundleIdentifier: String?
    let startTime: Date
    var endTime: Date?
    var result: RestartResult = .inProgress
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}

enum RestartResult {
    case success
    case notSupported
    case alreadyInProgress
    case terminationFailed
    case launchFailed
    case inProgress
    case error(String)
    
    var description: String {
        switch self {
        case .success: return "Success"
        case .notSupported: return "Not supported"
        case .alreadyInProgress: return "Already in progress"
        case .terminationFailed: return "Termination failed"
        case .launchFailed: return "Launch failed"
        case .inProgress: return "In progress"
        case .error(let message): return "Error: \\(message)"
        }
    }
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}