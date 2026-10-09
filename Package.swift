// swift-tools-version:6.4
import PackageDescription

let package = Package(
    name: "vapor-apns",
    platforms: [
        .macOS("26.2"),
        .iOS("26.2"),
        .tvOS("26.2"),
        .watchOS("26.2"),
    ],
    products: [
        .library(name: "VaporAPNS", targets: ["VaporAPNS"])
    ],
    dependencies: [
        .package(url: "https://github.com/kylebrowning/APNSwift.git", from: "7.0.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "5.0.0-beta.3"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.14.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.98.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "4.0.0"..<"6.0.0"),
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.6.3"),
    ],
    targets: [
        .target(
            name: "VaporAPNS",
            dependencies: [
                .product(name: "APNS", package: "apnswift"),
                .product(name: "APNSCore", package: "apnswift"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "VaporAPNSTests",
            dependencies: [
                .target(name: "VaporAPNS"),
                .product(name: "APNSCore", package: "apnswift"),
                .product(name: "VaporTesting", package: "vapor"),
                .product(name: "Crypto", package: "swift-crypto"),
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
