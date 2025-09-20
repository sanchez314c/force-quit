// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ForceQUIT",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "ForceQUIT",
            targets: ["ForceQUIT"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ForceQUIT",
            path: "Sources/ForceQUIT"
        )
    ]
)