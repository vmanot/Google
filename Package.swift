// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "Google",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "Google",
            targets: ["Google"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/vmanot/CorePersistence.git", branch: "main"),
        .package(url: "https://github.com/vmanot/NetworkKit.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "Google",
            dependencies: [
                "CorePersistence",
                "NetworkKit"
            ],
            path: "Sources"
        ),
    ]
)
