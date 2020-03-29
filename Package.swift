// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "apns",
    platforms: [
       .macOS(.v10_15)
    ],
    products: [
        .library(name: "APNS", targets: ["APNS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kylebrowning/APNSwift.git", from: "2.0.0-rc"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-rc"),
    ],
    targets: [
        .target(name: "APNS", dependencies: [
            .product(name: "APNS", package: "APNSwift"),
            .product(name: "Vapor", package: "vapor"),
        ]),
        .testTarget(name: "APNSTests", dependencies: [
            .target(name: "APNS"),
        ]),
    ]
)
