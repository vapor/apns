// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "vapor-apns",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .library(name: "VaporAPNS", targets: ["VaporAPNS"])
    ],
    dependencies: [
        .package(url: "https://github.com/kylebrowning/APNSwift.git", from: "7.0.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.110.1"),
    ],
    targets: [
        .target(
            name: "VaporAPNS",
            dependencies: [
                .product(name: "APNS", package: "apnswift"),
                .product(name: "APNSCore", package: "apnswift"),
                .product(name: "Vapor", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaporAPNSTests",
            dependencies: [
                .target(name: "VaporAPNS"),
                .product(name: "APNSCore", package: "apnswift"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] {
    [
        .treatAllWarnings(as: .error),
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("ImmutableWeakCaptures"),
        .enableExperimentalFeature("SuppressedAssociatedTypesWithDefaults"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]
}
