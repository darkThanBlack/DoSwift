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
        .target(
            name: "DoSwift",
            path: "Sources"
        ),
        .testTarget(
            name: "DoSwiftTests",
            dependencies: ["DoSwift"],
            path: "Tests"
        )
    ]
)