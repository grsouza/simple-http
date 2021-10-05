// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SimpleHTTP",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
    ],
    products: [
        .library(name: "SimpleHTTP", targets: ["SimpleHTTP"]),
        .library(name: "SimpleHTTPLive", targets: ["SimpleHTTPLive"]),
        .library(name: "SimpleHTTPMock", targets: ["SimpleHTTPMock"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.2.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SimpleHTTP",
            dependencies: []),
        .testTarget(
            name: "SimpleHTTPTests",
            dependencies: ["SimpleHTTP"]),
        
            .target(
                name: "SimpleHTTPLive",
                dependencies: ["SimpleHTTP"]),
        .testTarget(
            name: "SimpleHTTPLiveTests",
            dependencies: ["SimpleHTTPLive"]),
        
            .target(
                name: "SimpleHTTPMock",
                dependencies: [
                    "SimpleHTTP",
                    .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
                ]),
    ]
)
