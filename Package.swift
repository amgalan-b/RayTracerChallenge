// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RayTracerChallenge",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .executable(name: "RayTracerChallenge", targets: ["RayTracerChallenge"]),
    ],
    dependencies: [
        .package(name: "Babbage", path: "~/Projects/Babbage"),
        .package(url: "https://github.com/apple/swift-collections", .exact("1.0.2")),
        .package(url: "https://github.com/apple/swift-argument-parser", .exact("1.0.2")),
    ],
    targets: [
        .executableTarget(
            name: "RayTracerChallenge",
            dependencies: ["RayTracerKit", .product(name: "ArgumentParser", package: "swift-argument-parser")]
        ),
        .target(
            name: "RayTracerKit",
            dependencies: ["Babbage", .product(name: "Collections", package: "swift-collections")]
        ),
        .testTarget(
            name: "RayTracerTests",
            dependencies: ["RayTracerKit"],
            swiftSettings: [.define("TEST")]
        ),
    ]
)
