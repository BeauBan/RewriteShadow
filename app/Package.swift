// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RewriteShadow",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "RewriteShadow", targets: ["RewriteShadow"])
    ],
    targets: [
        .executableTarget(
            name: "RewriteShadow",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
