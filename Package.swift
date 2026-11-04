// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DoSwiftKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "DoSwiftKit",
            targets: ["DoSwiftKit"]
        )
    ],
    targets: [
        // `exclude` only silences the unhandled-files warning
        .target(
            name: "DoSwiftKit",
            path: ".",
            exclude: [
                "Example",
                "Scripts",
                "Tests",
                "docs",
                "DoSwiftKit.podspec",
                "LICENSE",
                "README.md",
                "README-zh-CN.md",
                "CLAUDE.md"
            ],
            sources: ["Code"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "DoSwiftKitTests",
            dependencies: ["DoSwiftKit"],
            path: "Tests"
        )
    ]
)
