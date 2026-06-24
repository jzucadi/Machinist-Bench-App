// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MachinistsCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    targets: [
        .target(name: "MachinistsCore", path: "MachinistsBench/Core"),
        .testTarget(
            name: "MachinistsCoreTests",
            dependencies: ["MachinistsCore"],
            path: "Tests/MachinistsCoreTests"
        ),
    ]
)
