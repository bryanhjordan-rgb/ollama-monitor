// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OllamaMonitor",
    platforms: [.macOS(.v26)],
    targets: [
        // API client and formatting with no SwiftUI, so tests run without the app.
        .target(name: "OllamaKit"),
        .executableTarget(
            name: "OllamaMonitor",
            dependencies: ["OllamaKit"],
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(name: "OllamaKitTests", dependencies: ["OllamaKit"]),
    ]
)
