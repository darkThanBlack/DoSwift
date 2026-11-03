// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DoSwift",
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
        // 源码在 Code/，资源在 Resources/，两者是平级的顶层目录。
        // SwiftPM 只认包根目录之下的资源，所以 target 声明为包根，再用 sources/resources 收窄。
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
