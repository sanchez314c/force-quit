import Foundation
import AppKit

@main
struct ForceQUITApp: App {
    var body: some Scene {
        WindowGroup {
            Text("ForceQUIT - Coming Soon!")
                .padding()
        }
    }
}

// Fallback if SwiftUI doesn't work
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("ForceQUIT Started!")
    }
}

// Simple fallback main
if ProcessInfo.processInfo.environment["SWIFTUI_AVAILABLE"] == nil {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}