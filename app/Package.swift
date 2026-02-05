// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SynonymBar",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "SynonymBar", targets: ["SynonymBar"])
    ],
    targets: [
        .executableTarget(name: "SynonymBar")
    ]
)
