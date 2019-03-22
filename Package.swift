// swift-tools-version:5.0
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
