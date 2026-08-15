public import APNS
import APNSCore
import Foundation
public import Vapor

extension Application {
    public var apns: APNS {
        return .init(application: self)
    }

    public struct APNS: Sendable {
        struct ContainersKey: StorageKey, LockKey {
            typealias Value = APNSContainers
        }

        public var containers: APNSContainers {
            get async {
                if let existingContainers = self.application.storage[ContainersKey.self] {
                    return existingContainers
                } else {
                    let lock = self.application.locks.lock(for: ContainersKey.self)
                    lock.lock()
                    defer { lock.unlock() }
                    let new = APNSContainers()
                    await self.application.storage.setWithAsyncShutdown(ContainersKey.self, to: new) { key in
                        await key.shutdown()
                    }
                    return new
                }
            }
        }

        public var client: APNSGenericClient {
            get async {
                guard let container = await containers.container() else {
                    fatalError("No default APNS container configured.")
                }
                return container.client
            }
        }

        public func client(_ id: APNSContainers.ID = .default) async -> APNSGenericClient {
            guard let container = await containers.container(for: id) else {
                fatalError("No APNS container for \(id).")
            }
            return container.client
        }

        let application: Application

        public init(application: Application) {
            self.application = application
        }
    }
}

extension Application.APNS {
    /// Configure both a production and development APNs environment.
    ///
    /// This convenience method creates two clients available via ``client(_:)`` with ``APNSContainers/ID/production`` and ``APNSContainers/ID/development`` that make it easy to support both development builds (ie. run from Xcode) and release builds (ie. TestFlight/App Store):
    ///
    /// ```swift
    /// /// The .p8 file as a string.
    /// guard let apnsKey = Environment.get("APNS_KEY_P8")
    /// else { throw Abort(.serviceUnavailable) }
    ///
    /// app.apns.configure(.jwt(
    ///     privateKey: try .init(pemRepresentation: apnsKey),
    ///     /// The identifier of the key in the developer portal.
    ///     keyIdentifier: Environment.get("APNS_KEY_ID"),
    ///     /// The team identifier of the app in the developer portal.
    ///     teamIdentifier: Environment.get("APNS_TEAM_ID")
    /// ))
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
    /// For more control over configuration, including sample code to determine the environment an APFs device token belongs to, see ``APNSContainers/use(_:eventLoopGroupProvider:responseDecoder:requestEncoder:byteBufferAllocator:as:isDefault:)``.
    ///
    /// - Note: The same key can be used for both the development and production environments.
    ///
    /// - Important: Make sure not to store your APNs key within your code or repo directly, and opt to store it via a secure store specific to your deployment, such as in a .env supplied at deploy time.
    ///
    /// - Parameter authenticationMethod: An APNs authentication method to use when connecting to Apple's production and development servers.
    public func configure(_ authenticationMethod: APNSClientConfiguration.AuthenticationMethod) async {
        await containers.use(
            APNSClientConfiguration(
                authenticationMethod: authenticationMethod,
                environment: .production
            ),
            eventLoopGroupProvider: .shared(application.eventLoopGroup),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .production
        )

        await containers.use(
            APNSClientConfiguration(
                authenticationMethod: authenticationMethod,
                environment: .development
            ),
            eventLoopGroupProvider: .shared(application.eventLoopGroup),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .development
        )
    }
}
