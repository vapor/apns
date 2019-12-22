// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "apns",
    platforms: [
       .macOS(.v10_14)
    ],
    products: [
        .library(name: "APNs", targets: ["APNs"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kylebrowning/APNSwift.git", from: "1.7.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta.2.1"),
    ],
    targets: [
        .target(name: "APNs", dependencies: ["APNSwift", "Vapor"]),
        .testTarget(name: "APNsTests", dependencies: ["APNs", "XCTVapor"]),
    ]
)
