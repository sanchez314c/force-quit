// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ForceQUIT",
    platforms: [
        .macOS(.v14)  // macOS 14.0+ for CADisplayLink and latest SwiftUI features
    ],
    products: [
        .executable(
            name: "ForceQUIT",
            targets: ["ForceQUIT"]
        )
    ],
    dependencies: [
        // No external dependencies - using macOS system frameworks only
        // Following SWARM principle: minimal dependencies for maximum reliability
    ],
    targets: [
        .executableTarget(
            name: "ForceQUIT",
            dependencies: [],
            path: "Sources",
            exclude: [
                "_disabled",
                "Views/MissionControlInterface.swift",
                "main.swift"
            ]
        )
    ]
)