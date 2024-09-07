// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Swift Package: ExamplePackage

import PackageDescription;

let package = Package(
    name: "ExamplePackage",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "ExamplePackage",
            targets: ["ExamplePackage"]
        )
    ],
    dependencies: [ ],
    targets: [
        .binaryTarget(name: "RustFramework", path: "./RustFramework.xcframework"),
        .target(
            name: "ExamplePackage",
            dependencies: [
                .target(name: "RustFramework")
            ]
        ),
    ]
)