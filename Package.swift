// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Nebula",
    products: [
        .library(
            name: "Nebula",
            targets: ["Nebula"]),
        ],
    dependencies: [
        .package(url: "https://github.com/vrisch/Orbit.git", .branch("develop")),
        ],
    targets: [
        .target(
            name: "Nebula",
            dependencies: ["Orbit"]),
        ]
)
