// swift-tools-version:5.7
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
            name: "FeaturevisorSwiftTestRunner",
            targets: ["FeaturevisorTestRunner"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/daisuke-t-jp/MurmurHash-Swift.git", from: "1.1.1"),
        .package(url: "https://github.com/JohnSundell/Files", from: "4.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.6"),
        .package(url: "https://github.com/qiuzhifei/swift-commands", from: "0.6.0"),
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
                "FeaturevisorSDK",
                "FeaturevisorTypes",
                "Files",
                "Yams",
                .product(name: "Commands", package: "swift-commands"),
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
