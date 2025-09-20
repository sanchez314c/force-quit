// swift-tools-version: 5.9
// ForceQUIT - Sleek macOS Force Quit Utility

import PackageDescription

let package = Package(
    name: "ForceQUIT",
    platforms: [
        .macOS(.v12)  // macOS 12.0+ for SwiftUI 3.0+ and async/await support
    ],
    products: [
        // Main executable product - the ForceQUIT app
        .executable(
            name: "ForceQUIT",
            targets: ["ForceQUIT"]
        )
    ],
    dependencies: [
        // No external dependencies - uses native macOS frameworks only
    ],
    targets: [
        // Main executable target
        .executableTarget(
            name: "ForceQUIT",
            dependencies: [],
            path: "Sources",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ForwardTrailingClosures"), 
                .enableUpcomingFeature("ImportObjcForwardDeclarations"),
                .define("SWIFTUI_FORCE_QUIT"),
                .define("DARK_MODE_OPTIMIZED")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Foundation")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)