// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Google",
    platforms: [
        .iOS("14.0"),
        .macOS("11.0"),
        .tvOS("14.0"),
        .watchOS("7.0")
    ],
    products: [
        .library(name: "Google", targets: ["Google"])
    ],
    dependencies: [
        .package(url: "https://github.com/vmanot/NetworkKit.git", .branch("master")),
    ],
    targets: [
        .target(
            name: "Google",
            dependencies: [
                "NetworkKit"
            ],
            path: "Sources"
        ),
    ],
    swiftLanguageVersions: [
        .version("5.1")
    ]
)
