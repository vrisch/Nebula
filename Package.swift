// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Nebula",
    products: [
        .library(
            name: "Nebula",
            targets: ["Nebula"]),
        ],
    targets: [
        .target(
            name: "Nebula")
        ]
)
