// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "apns",
    platforms: [
       .macOS(.v10_14)
    ],
    products: [
        .library(name: "APNS", targets: ["APNS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kylebrowning/APNSwift.git", .branch("master")),
        .package(url: "https://github.com/vapor/vapor.git", .branch("master")),
    ],
    targets: [
        .target(name: "APNS", dependencies: ["APNSwift", "Vapor"]),
        .testTarget(name: "APNSTests", dependencies: ["APNS", "XCTVapor"]),
    ]
)
