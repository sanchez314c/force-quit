import SwiftUI

@main
struct ForceQUITApp: App {
    @StateObject private var safeRestartEngine = SafeRestartEngine()
    @State private var isProcessing = false

    var body: some Scene {
        MenuBarExtra("ForceQUIT", systemImage: "xmark.app") {
            Button(action: forceQuitAllNonEssential) {
                if isProcessing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.5)
                        Text("Force Quitting...")
                    }
                } else {
                    Text("Force Quit All Non-Essential Apps")
                }
            }
            .disabled(isProcessing)

            Divider()

            Button("About ForceQUIT") {
                showAbout()
            }

            Button("Quit ForceQUIT") {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    private func forceQuitAllNonEssential() {
        isProcessing = true

        Task {
            // Get all running applications
            let workspace = NSWorkspace.shared
            let runningApps = workspace.runningApplications

            // Filter out essential system processes
            let essentialBundleIds = [
                "com.apple.loginwindow",
                "com.apple.WindowServer",
                "com.apple.finder",
                "com.apple.dock",
                "com.apple.systemuiserver",
                "com.apple.notificationcenter",
                "com.apple.controlcenter"
            ]

            var appsToQuit: [NSRunningApplication] = []

            for app in runningApps {
                // Skip if it's an essential system process
                if let bundleId = app.bundleIdentifier,
                   essentialBundleIds.contains(bundleId) {
                    continue
                }

                // Skip if it's our own app
                if app.bundleIdentifier == "com.forcequit.app" {
                    continue
                }

                // Skip system processes (those without bundle identifiers are usually system processes)
                if app.bundleIdentifier == nil {
                    continue
                }

                appsToQuit.append(app)
            }

            // Force quit the applications
            for app in appsToQuit {
                print("Force quitting: \(app.localizedName ?? "Unknown")")
                app.terminate()
            }

            // Wait a moment for termination to complete
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            await MainActor.run {
                isProcessing = false
            }
        }
    }

    private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "ForceQUIT"
        alert.informativeText = "Force quit all non-essential applications and services.\n\nVersion 1.0"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}