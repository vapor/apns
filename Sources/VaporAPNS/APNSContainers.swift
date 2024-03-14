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
