import Vapor
import APNS
#if canImport(Darwin)
import Foundation
#else
// JSONEncoder / JSONDecoder is not Sendable in scf, but is in Darwin...
// Import as `@preconcurrency` to fix warnings.
@preconcurrency import Foundation
#endif
import NIO
import NIOConcurrencyHelpers

public typealias APNSGenericClient = APNSClient<JSONDecoder, JSONEncoder>

public final class APNSContainers: Sendable {
    public struct ID: Sendable, Hashable, Codable {
        public let string: String
        public init(string: String) {
            self.string = string
        }
    }

    public final class Container: Sendable {
        public let configuration: APNSClientConfiguration
        public let client: APNSGenericClient
        
        internal init(configuration: APNSClientConfiguration, client: APNSGenericClient) {
            self.configuration = configuration
            self.client = client
        }
    }

    private let storage: NIOLockedValueBox<(containers: [ID: Container], defaultID: ID?)>

    init() {
        storage = .init((containers: [:], defaultID: nil))
    }

    public func syncShutdown() {
        storage.withLockedValue {
            do {
                try $0.containers.values.forEach { container in
                    try container.client.syncShutdown()
                }
            } catch {
                fatalError("Could not shutdown APNS Containers")
            }
        }
    }
}

extension APNSContainers {
    /// Configure APNs for a given container ID.
    ///
    /// You must configure at lease one client in order to send notifications to devices. If you plan on supporting both development builds (ie. run from Xcode) and release builds (ie. TestFlight/App Store), you must configure at least two configurations:
    ///
    /// ```swift
    /// /// The .p8 file as a string.
    /// let apnsKey = Environment.get("APNS_KEY_P8")
    /// /// The identifier of the key in the developer portal.
    /// let keyIdentifier = Environment.get("APNS_KEY_ID")
    /// /// The team identifier of the app in the developer portal.
    /// let teamIdentifier = Environment.get("APNS_TEAM_ID")
    ///
    /// let productionConfig = APNSClientConfiguration(
    ///     authenticationMethod: .jwt(
    ///         privateKey: try .loadFrom(string: apnsKey),
    ///         keyIdentifier: keyIdentifier,
    ///         teamIdentifier: teamIdentifier
    ///     ),
    ///     environment: .production
    /// )
    ///
    /// app.apns.containers.use(
    ///     productionConfig,
    ///     eventLoopGroupProvider: .shared(app.eventLoopGroup),
    ///     responseDecoder: JSONDecoder(),
    ///     requestEncoder: JSONEncoder(),
    ///     as: .production
    /// )
    ///
    /// var developmentConfig = productionConfig
    /// developmentConfig.environment = .sandbox
    ///
    /// app.apns.containers.use(
    ///     developmentConfig,
    ///     eventLoopGroupProvider: .shared(app.eventLoopGroup),
    ///     responseDecoder: JSONDecoder(),
    ///     requestEncoder: JSONEncoder(),
    ///     as: .development
    /// )
    /// ```
    ///
    /// As shown above, the same key can be used for both the development and production environments.
    ///
    /// - Important: Make sure not to store your APNs key within your code or repo directly, and opt to store it via a secure store specific to your deployment, such as in a .env supplied at deploy time.
    ///
    /// You can determine which environment is being used in your app by checking its entitlements, and including the information along with the device token when sending it to your server:
    /// ```swift
    /// enum APNSDeviceTokenEnvironment: String {
    ///     case production
    ///     case development
    /// }
    ///
    /// /// Get the APNs environment from the embedded 
    /// /// provisioning profile, or nil if it can't
    /// /// be determined.
    /// ///
    /// /// Note that both TestFlight and the App Store
    /// /// don't have provisioning profiles, and always
    /// /// run in the production environment.
    /// var pushEnvironment: APNSDeviceTokenEnvironment? {
    ///     #if canImport(AppKit)
    ///     let provisioningProfileURL = Bundle.main.bundleURL
    ///         .appending(path: "Contents", directoryHint: .isDirectory)
    ///         .appending(path: "embedded.provisionprofile", directoryHint: .notDirectory)
    ///     guard let data = try? Data(contentsOf: provisioningProfileURL)
    ///     else { return nil }
    ///     #else
    ///     guard
    ///         let provisioningProfileURL = Bundle.main
    ///             .url(forResource: "embedded", withExtension: "mobileprovision"),
    ///         let data = try? Data(contentsOf: provisioningProfileURL)
    ///     else {
    ///         #if targetEnvironment(simulator)
    ///         return .development
    ///         #else
    ///         return nil
    ///         #endif
    ///     }
    ///     #endif
    ///
    ///     let string = String(decoding: data, as: UTF8.self)
    ///
    ///     guard
    ///         let start = string.firstRange(of: "<plist"),
    ///         let end = string.firstRange(of: "</plist>")
    ///     else { return nil }
    ///
    ///     let propertylist = string[start.lowerBound..<end.upperBound]
    ///
    ///     guard
    ///         let provisioningProfile = try? PropertyListSerialization
    ///             .propertyList(from: Data(propertylist.utf8), format: nil) as? [String : Any],
    ///         let entitlements = provisioningProfile["Entitlements"] as? [String: Any],
    ///         let environment = (
    ///             entitlements["aps-environment"]
    ///             ?? entitlements["com.apple.developer.aps-environment"]
    ///         ) as? String
    ///     else { return nil }
    ///
    ///     return APNSDeviceTokenEnvironment(rawValue: environment)
    /// }
    /// ```
    /// Note that the simulator doesn't have a provisioning profile, and will always register under the development environment.
    ///
    /// - Parameters:
    ///   - config: The APNs configuration.
    ///   - eventLoopGroupProvider: Specify how the ``NIOCore/EventLoopGroup`` will be created. Example: `.shared(app.eventLoopGroup)`
    ///   - responseDecoder: A decoder to use when decoding responses from the APNs server. Example: `JSONDecoder()`
    ///   - requestEncoder: An encoder to use when encoding notifications. Example: `JSONEncoder()`
    ///   - byteBufferAllocator: The allocator to use.
    ///   - id: The container ID to access the configuration under.
    ///   - isDefault: A flag to specify the configuration as the default when ``Vapor/Application/APNS/client`` is called. The first configuration that doesn't specify `false` is automatically configured as the default.
    public func use(
        _ config: APNSClientConfiguration,
        eventLoopGroupProvider: NIOEventLoopGroupProvider,
        responseDecoder: JSONDecoder,
        requestEncoder: JSONEncoder,
        byteBufferAllocator: ByteBufferAllocator = .init(),
        as id: ID,
        isDefault: Bool? = nil
    ) {
        storage.withLockedValue {
            $0.containers[id] = Container(
                configuration: config,
                client: APNSGenericClient(
                    configuration: config,
                    eventLoopGroupProvider: eventLoopGroupProvider,
                    responseDecoder: responseDecoder,
                    requestEncoder: requestEncoder,
                    byteBufferAllocator: byteBufferAllocator
                )
            )

            if isDefault == true || ($0.defaultID == nil && isDefault != false) {
                $0.defaultID = id
            }
        }
    }

    public func `default`(to id: ID) {
        storage.withLockedValue {
            $0.defaultID = id
        }
    }

    public func container(for id: ID? = nil) -> APNSContainers.Container? {
        storage.withLockedValue {
            guard let id = id ?? $0.defaultID else {
                return nil
            }
            return $0.containers[id]
        }
    }

    public var container: APNSContainers.Container? {
        container()
    }
}
