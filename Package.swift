// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MonitorSwitcher",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MonitorSwitcher", targets: ["MonitorSwitcher"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MonitorSwitcher",
            dependencies: [],
            path: "Sources/MonitorSwitcher"
        )
    ]
)
