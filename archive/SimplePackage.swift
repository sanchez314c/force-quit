// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SimpleForceQUIT",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "SimpleForceQUIT",
            targets: ["SimpleForceQUIT"]
        )
    ],
    targets: [
        .executableTarget(
            name: "SimpleForceQUIT",
            path: "SimpleSources/SimpleForceQUIT",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)