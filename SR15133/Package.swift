// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SR15133",
    platforms: [ .macOS("12") ],
    dependencies: [
        .package(url: "https://github.com/Cornucopia-Swift/CornucopiaStreams.git", branch: "master")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "SR15133",
            dependencies: ["CornucopiaStreams"]
        ),
        .testTarget(
            name: "SR15133Tests",
            dependencies: ["SR15133"]),
    ]
)
