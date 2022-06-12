import Vapor
import APNSwift

public class APNSContainers {
    public struct ID: Hashable, Codable {
        public let string: String
        public init(string: String) {
            self.string = string
        }
    }

    public final class Container {
        public let configuration: APNSConfiguration
        public let client: APNSClient
        
        init(configuration: APNSConfiguration, client: APNSClient) {
            self.configuration = configuration
            self.client = client
        }
    }

    private var containers: [ID: Container]
    private var defaultID: ID?
    private var lock: Lock

    init() {
        self.containers = [:]
        self.lock = .init()
    }
}

extension APNSContainers {

    public func use(
        _ config: APNSConfiguration,
        as id: ID,
        isDefault: Bool? = nil
    ) {
        self.lock.lock()
        defer { self.lock.unlock() }

        self.containers[id] = Container(
            configuration: config,
            client: APNSClient(configuration: config)
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
        print("Loading \(id)")
        return self.containers[id]
    }

    public var container: APNSContainers.Container? {
        container()
    }
}

extension APNSContainers {

    public func shutdown() {
        self.lock.lock()
        let group = DispatchGroup()
        defer { self.lock.unlock() }
        for container in self.containers.values {
            group.enter()
            Task {
                try await container.client.shutdown()
                group.leave()
            }
        }
        group.wait()
    }
}
