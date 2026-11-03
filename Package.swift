// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PhotoTool",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "PhotoCore",
            path: "Sources/PhotoCore"
        ),
        .executableTarget(
            name: "PhotoTool",
            dependencies: ["PhotoCore"],
            path: "Sources/PhotoTool",
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "PhotoCoreTests",
            dependencies: ["PhotoCore"],
            path: "Tests/PhotoCoreTests"
        ),
    ]
)
