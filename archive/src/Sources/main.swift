import SwiftUI

// @main - DISABLED: Conflicting with primary entry point in Sources/ForceQUIT/main.swift
@available(macOS 13.0, *)
struct ForceQUITApp_Simple: App {
    var body: some Scene {
        WindowGroup {
            VStack {
                Text("ForceQUIT")
                    .font(.largeTitle)
                    .padding()
                Text("Master Force Quit Utility")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Button("Test Button") {
                    print("ForceQUIT Test")
                }
                .padding()
            }
            .frame(minWidth: 400, minHeight: 300)
        }
        .windowStyle(.hiddenTitleBar)
    }
}