import Vapor
import APNS
import Foundation
import NIO
import NIOConcurrencyHelpers

public typealias APNSGenericClient = APNSClient<JSONDecoder, JSONEncoder>

public class APNSContainers {
    public struct ID: Hashable, Codable {
        public let string: String
        public init(string: String) {
            self.string = string
        }
    }

    public final class Container {
        public let configuration: APNSClientConfiguration
        public let client: APNSGenericClient
        
         internal init(configuration: APNSClientConfiguration, client: APNSGenericClient) {
            self.configuration = configuration
            self.client = client
        }
    }

    private var containers: [ID: Container]
    private var defaultID: ID?
    private var lock: NIOLock

    init() {
        self.containers = [:]
        self.lock = .init()
    }

    public func syncShutdown() {
        self.lock.lock()
        defer { self.lock.unlock() }
        do {
            try containers.forEach { key, container in
                try container.client.syncShutdown()
            }
        } catch {
            fatalError("Could not shutdown APNS Containers")
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
        self.lock.lock()
        defer { self.lock.unlock() }

        self.containers[id] = Container(
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
        self.lock.lock()
        defer { self.lock.unlock() }
        self.defaultID = id
    }

    public func container(for id: ID? = nil) -> APNSContainers.Container? {
        self.lock.lock()
        defer { self.lock.unlock() }
        guard let id = id ?? self.defaultID else {
            return nil
        }
        return self.containers[id]
    }

    public var container: APNSContainers.Container? {
        container()
    }
}

