import Vapor

public class APNSConfigurations {
    
    private var configurations: [Application.APNS.ConfigID: APNSwiftConfiguration]
    private var defaultID: Application.APNS.ConfigID?
    
    private var pools: [Application.APNS.ConfigID: EventLoopGroupConnectionPool<APNSConnectionSource>]
    
    private var lock: Lock
    
    init() {
        self.configurations = [:]
        self.pools = [:]
        self.lock = .init()
    }
}

extension APNSConfigurations {
    
    private func _requireConfiguration(for id: Application.APNS.ConfigID) -> APNSwiftConfiguration {
        guard let configuration = self.configurations[id] else {
            fatalError("No APNS configuration registered for \(id).")
        }
        return configuration
    }
    
    private func _requireDefaultID() -> Application.APNS.ConfigID {
        guard let id = self.defaultID else {
            fatalError("No default APNS configured.")
        }
        return id
    }
}

extension APNSConfigurations {
    
    public func use(
        _ config: APNSwiftConfiguration,
        as id: Application.APNS.ConfigID,
        isDefault: Bool? = nil
    ) {
        self.lock.lock()
        defer { self.lock.unlock() }
        
        self.configurations[id] = config
        
        if isDefault == true || (self.defaultID == nil && isDefault != false) {
            self.defaultID = id
        }
    }
    
    public func `default`(to id: Application.APNS.ConfigID) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.defaultID = id
    }
    
    public func configuration(for id: Application.APNS.ConfigID? = nil) -> APNSwiftConfiguration? {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.configurations[id ?? self._requireDefaultID()]
    }
}

extension APNSConfigurations {
    
    public func pool(
        for configID: Application.APNS.ConfigID? = nil,
        logger: Logger,
        on eventLoopGroup: EventLoopGroup
    ) -> EventLoopGroupConnectionPool<APNSConnectionSource> {
        
        self.lock.lock()
        defer { self.lock.unlock() }
        
        let configID = configID ?? self._requireDefaultID()
        let configuration = self._requireConfiguration(for: configID)
        
        var logger = logger
        logger[metadataKey: "config-id"] = .string(configID.string)
        
        if let existing = self.pools[configID] {
            return existing
        }
        
        let pool = EventLoopGroupConnectionPool(
            source: APNSConnectionSource(configuration: configuration),
            maxConnectionsPerEventLoop: 1,
            logger: logger,
            on: eventLoopGroup
        )
        self.pools[configID] = pool
        
        return pool
    }
}

extension APNSConfigurations {
    
    public func shutdown() {
        self.lock.lock()
        defer { self.lock.unlock() }
        for pool in self.pools.values {
            pool.shutdown()
        }
        self.pools = [:]
    }
}
