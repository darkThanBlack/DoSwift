// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DoSwift",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "DoSwift",
            targets: ["DoSwift"]
        )
    ],
    targets: [
        // Sources live in Code/, resources in Resources/ — siblings at the package root.
        // SwiftPM only accepts resources below `path`, so the target is the root and
        // `sources` / `resources` narrow it; `exclude` only silences the unhandled-files warning.
        .target(
            name: "DoSwift",
            path: ".",
            exclude: [
                ".build",
                ".claude",
                ".swiftpm",
                "Example",
                "Scripts",
                "Tests",
                "Package.swift",
                "DoSwift.podspec",
                "LICENSE",
                "README.md",
                "CLAUDE.md",
                "DEVELOPMENT.md",
                "LLM_CODE_STANDARDS.md"
            ],
            sources: ["Code"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "DoSwiftTests",
            dependencies: ["DoSwift"],
            path: "Tests"
        )
    ]
)
