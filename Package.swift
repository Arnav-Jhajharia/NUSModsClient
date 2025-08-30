// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "NUSModsClient",
    platforms: [
        .iOS("26.0"),
        .macOS("26.0"),
        .watchOS("26.0"),
        .tvOS("26.0")
    ],
    products: [
        .library(
            name: "NUSModsClient",
            targets: ["NUSModsClient"]),
    ],
    targets: [
        .target(
            name: "NUSModsClient",
            dependencies: [])
    ]
)
