// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TensioCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "TensioCore",
            targets: ["TensioCore"]
        )
    ],
    targets: [
        .target(
            name: "TensioCore"
        ),
        .testTarget(
            name: "TensioCoreTests",
            dependencies: ["TensioCore"]
        )
    ]
)
