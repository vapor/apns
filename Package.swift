// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "apns-kit",
    products: [
        .library(name: "APNSKit", targets: ["APNSKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kylebrowning/APNSwift.git", from: "1.3.0"),
        .package(url: "https://github.com/vapor/async-kit.git", from: "1.0.0-alpha.1"),
    ],
    targets: [
        .target(name: "APNSKit", dependencies: ["AsyncKit", "APNSwift"]),
        .testTarget(name: "APNSKitTests", dependencies: ["APNSKit"]),
    ]
)
