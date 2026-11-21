// swift-tools-version: 5.8
import PackageDescription

let package = Package(name: "F19Layer", platforms: [.macOS(.v13)], targets: [
    .executableTarget(name: "F19Layer"),
    .testTarget(name: "F19LayerTests", dependencies: ["F19Layer"])
])
