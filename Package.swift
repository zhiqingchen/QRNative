// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "QRNative",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "QRNativeCore", targets: ["QRNativeCore"]),
        .executable(name: "QRNative", targets: ["QRNative"])
    ],
    targets: [
        .target(
            name: "QRNativeCore",
            path: "Sources/QRNativeCore"
        ),
        .executableTarget(
            name: "QRNative",
            dependencies: ["QRNativeCore"],
            path: "Sources/QRNative"
        ),
        .testTarget(
            name: "QRNativeCoreTests",
            dependencies: ["QRNativeCore"],
            path: "Tests/QRNativeCoreTests"
        )
    ]
)
