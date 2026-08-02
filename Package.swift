// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FinderExplorer",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "FinderExplorer",
            path: "Sources/FinderExplorer",
            resources: [
                .copy("../../AppIcon.icns")
            ]
        )
    ]
)
