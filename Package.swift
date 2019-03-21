// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "apns-kit",
    products: [
        .library(name: "APNSKit", targets: ["APNSKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kylebrowning/swift-nio-http2-apns.git", .branch("master")),
        .package(url: "https://github.com/vapor/nio-kit.git", .branch("master")),
    ],
    targets: [
        .target(name: "APNSKit", dependencies: ["NIOKit", "NIOAPNS"]),
        .testTarget(name: "APNSKitTests", dependencies: ["APNSKit"]),
    ]
)
