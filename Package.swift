// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FeaturevisorSDK",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "FeaturevisorSDK",
            targets: ["FeaturevisorSDK"]
        ),
        .library(
            name: "FeaturevisorTypes",
            targets: ["FeaturevisorTypes"]
        ),
        .executable(
            name: "Featurevisor-swift",
            targets: ["FeaturevisorTestRunner"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/daisuke-t-jp/MurmurHash-Swift.git", from: "1.1.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "FeaturevisorTypes",
            dependencies: []
        ),
        .target(
            name: "FeaturevisorSDK",
            dependencies: [
                "FeaturevisorTypes",
                "MurmurHash-Swift",
            ]
        ),
        .executableTarget(
            name: "FeaturevisorTestRunner",
            dependencies: [

            ],
            path: "Sources/FeaturevisorTestRunner"
        ),
        .testTarget(
            name: "FeaturevisorSDKTests",
            dependencies: [
                "FeaturevisorSDK"
            ]
        ),
        .testTarget(
            name: "FeaturevisorTypesTests",
            dependencies: [
                "FeaturevisorTypes"
            ],
            resources: [
                .process("JSONs")
            ]
        ),
    ]
)
