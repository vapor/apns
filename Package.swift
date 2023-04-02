// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "vapor-apns",
    platforms: [
       .macOS(.v12),
       .iOS(.v15)
    ],
    products: [
        .library(name: "VaporAPNS", targets: ["VaporAPNS"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server-community/APNSwift.git", from: "5.0.0-beta.3"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "VaporAPNS", dependencies: [
            .product(name: "APNS", package: "apnswift"),
            .product(name: "Vapor", package: "vapor"),
        ]),
        .testTarget(name: "VaporAPNSTests", dependencies: [
            .target(name: "VaporAPNS"),
            .product(name: "XCTVapor", package: "vapor"),
        ]),
    ]
)
