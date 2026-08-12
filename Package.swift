// swift-tools-version:6.0
import PackageDescription

let package = Package(
  name: "vapor-apns",
  platforms: [
    .macOS(.v13),
    .iOS(.v16),
  ],
  products: [
    .library(name: "VaporAPNS", targets: ["VaporAPNS"])
  ],
  dependencies: [
    .package(url: "https://github.com/swift-server-community/APNSwift.git", from: "7.0.0"),
    .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1"),
  ],
  targets: [
    .target(
      name: "VaporAPNS",
      dependencies: [
        .product(name: "APNS", package: "apnswift"),
        .product(name: "Vapor", package: "vapor"),
      ]),
    .testTarget(
      name: "VaporAPNSTests",
      dependencies: [
        .target(name: "VaporAPNS"),
        .product(name: "VaporTesting", package: "vapor"),
      ]),
  ]
)
