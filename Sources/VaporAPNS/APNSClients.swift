public import APNS
import APNSCore
import Logging
public import NIOCore
public import NIOPosix
public import ServiceLifecycle

#if canImport(FoundationEssentials)
    public import FoundationEssentials
#else
    public import Foundation
#endif

public typealias APNSGenericClient = APNSClient<JSONDecoder, JSONEncoder>

/// Holds the configured APNs clients for an application.
///
/// Create one while configuring your application, register the clients you need, then hand it
/// to the application so the clients are shut down with it:
///
/// ```swift
/// let apns = APNSClients()
/// try await apns.configure(.jwt(
///     privateKey: try .init(pemRepresentation: apnsKey),
///     keyIdentifier: keyIdentifier,
///     teamIdentifier: teamIdentifier
/// ))
/// app.addService(apns)
/// ```
///
/// Pass the clients to whatever needs to send notifications, such as your route collections.
public final actor APNSClients: Service {
    public struct ID: Sendable, Hashable, Codable {
        public let string: String
        public init(string: String) {
            self.string = string
        }
    }

    public final class Entry: Sendable {
        public let configuration: APNSClientConfiguration
        public let client: APNSGenericClient

        internal init(configuration: APNSClientConfiguration, client: APNSGenericClient) {
            self.configuration = configuration
            self.client = client
        }
    }

    private var entries: [ID: Entry]
    private var defaultID: ID?
    private let logger: Logger

    public init() {
        self.entries = [:]
        self.defaultID = nil
        self.logger = Logger(label: "codes.vapor.apns")
    }

    /// Keeps the clients alive until the application shuts down, then shuts them down.
    public func run() async throws {
        try? await gracefulShutdown()
        await self.shutdown()
    }

    public func shutdown() async {
        for entry in self.entries.values {
            do {
                try await entry.client.shutdown()
            } catch {
                // Log the error but continue shutting down the other clients
                logger.warning("Failed to shut down APNs client", metadata: ["error": "\(error)"])
            }
        }
        self.entries.removeAll()
    }
}

extension APNSClients {
    /// Configure APNs for a given client ID.
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
    ///         privateKey: try .init(pemRepresentation: apnsKey),
    ///         keyIdentifier: keyIdentifier,
    ///         teamIdentifier: teamIdentifier
    ///     ),
    ///     environment: .production
    /// )
    ///
    /// let apns = APNSClients()
    /// await apns.use(
    ///     productionConfig,
    ///     responseDecoder: JSONDecoder(),
    ///     requestEncoder: JSONEncoder(),
    ///     as: .production
    /// )
    ///
    /// var developmentConfig = productionConfig
    /// developmentConfig.environment = .development
    ///
    /// await apns.use(
    ///     developmentConfig,
    ///     responseDecoder: JSONDecoder(),
    ///     requestEncoder: JSONEncoder(),
    ///     as: .development
    /// )
    /// app.addService(apns)
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
    ///   - eventLoopGroupProvider: Specify how the ``NIOCore/EventLoopGroup`` will be created. Defaults to the shared NIO singleton group.
    ///   - responseDecoder: A decoder to use when decoding responses from the APNs server. Example: `JSONDecoder()`
    ///   - requestEncoder: An encoder to use when encoding notifications. Example: `JSONEncoder()`
    ///   - byteBufferAllocator: The allocator to use.
    ///   - id: The client ID to access the configuration under.
    ///   - isDefault: A flag to specify the configuration as the default when ``client`` is called. The first configuration that doesn't specify `false` is automatically configured as the default.
    public func use(
        _ config: APNSClientConfiguration,
        eventLoopGroupProvider: NIOEventLoopGroupProvider = .shared(MultiThreadedEventLoopGroup.singleton),
        responseDecoder: JSONDecoder,
        requestEncoder: JSONEncoder,
        byteBufferAllocator: ByteBufferAllocator = .init(),
        as id: ID,
        isDefault: Bool? = nil
    ) {
        self.entries[id] = Entry(
            configuration: config,
            client: APNSGenericClient(
                configuration: config,
                eventLoopGroupProvider: eventLoopGroupProvider,
                responseDecoder: responseDecoder,
                requestEncoder: requestEncoder,
                byteBufferAllocator: byteBufferAllocator
            )
        )

        if isDefault == true || (self.defaultID == nil && isDefault != false) {
            self.defaultID = id
        }
    }

    public func `default`(to id: ID) {
        self.defaultID = id
    }

    public func entry(for id: ID? = nil) -> APNSClients.Entry? {
        guard let id = id ?? self.defaultID else {
            return nil
        }
        return self.entries[id]
    }

    public var entry: APNSClients.Entry? {
        entry()
    }

    /// The default client.
    ///
    /// - Precondition: A default client has been configured.
    public var client: APNSGenericClient {
        guard let entry = self.entry() else {
            fatalError("No default APNs client configured.")
        }
        return entry.client
    }

    /// The client for the given ID.
    ///
    /// - Precondition: A client has been configured under `id`.
    public func client(_ id: ID) -> APNSGenericClient {
        guard let entry = self.entry(for: id) else {
            fatalError("No APNs client for \(id).")
        }
        return entry.client
    }
}

extension APNSClients {
    /// Configure both a production and development APNs environment.
    ///
    /// This convenience method creates two clients available via ``client(_:)`` with ``ID/production`` and ``ID/development`` that make it easy to support both development builds (ie. run from Xcode) and release builds (ie. TestFlight/App Store):
    ///
    /// ```swift
    /// /// The .p8 file as a string.
    /// guard let apnsKey = Environment.get("APNS_KEY_P8")
    /// else { throw Abort(.serviceUnavailable) }
    ///
    /// let apns = APNSClients()
    /// await apns.configure(.jwt(
    ///     privateKey: try .init(pemRepresentation: apnsKey),
    ///     /// The identifier of the key in the developer portal.
    ///     keyIdentifier: Environment.get("APNS_KEY_ID"),
    ///     /// The team identifier of the app in the developer portal.
    ///     teamIdentifier: Environment.get("APNS_TEAM_ID")
    /// ))
    /// app.addService(apns)
    ///
    /// // ...
    ///
    /// let response = switch deviceToken.environment {
    /// case .production:
    ///     try await apns.client(.production)
    ///         .sendAlertNotification(notification, deviceToken: deviceToken.hexadecimalToken)
    /// case .development:
    ///     try await apns.client(.development)
    ///         .sendAlertNotification(notification, deviceToken: deviceToken.hexadecimalToken)
    /// }
    /// ```
    ///
    /// For more control over configuration, including sample code to determine the environment an APNs device token belongs to, see ``use(_:eventLoopGroupProvider:responseDecoder:requestEncoder:byteBufferAllocator:as:isDefault:)``.
    ///
    /// - Note: The same key can be used for both the development and production environments.
    ///
    /// - Important: Make sure not to store your APNs key within your code or repo directly, and opt to store it via a secure store specific to your deployment, such as in a .env supplied at deploy time.
    ///
    /// - Parameter authenticationMethod: An APNs authentication method to use when connecting to Apple's production and development servers.
    public func configure(_ authenticationMethod: APNSClientConfiguration.AuthenticationMethod) {
        self.use(
            APNSClientConfiguration(
                authenticationMethod: authenticationMethod,
                environment: .production
            ),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .production
        )

        self.use(
            APNSClientConfiguration(
                authenticationMethod: authenticationMethod,
                environment: .development
            ),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .development
        )
    }
}
