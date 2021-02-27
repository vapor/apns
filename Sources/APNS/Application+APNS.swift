import Vapor

extension Application {
    public var apns: APNS {
        .init(application: self,
              eventLoop: eventLoopGroup.next(),
              logger: logger)
    }

    private struct ConfigurationKey: StorageKey {
        typealias Value = APNSwiftConfiguration
    }

    public var apnsConfiguration: APNSwiftConfiguration? {
        get {
            storage[ConfigurationKey.self]
        }
        set {
            storage[ConfigurationKey.self] = newValue
        }
    }

    private struct PoolKey: StorageKey, LockKey {
        typealias Value = EventLoopGroupConnectionPool<APNSConnectionSource>
    }

    public var apnsPool: EventLoopGroupConnectionPool<APNSConnectionSource> {
        if let existing = storage[PoolKey.self] {
            return existing
        } else {
            let lock = locks.lock(for: PoolKey.self)
            lock.lock()
            defer { lock.unlock() }
            guard let configuration = apnsConfiguration else {
                fatalError("APNS not configured. Use app.apnsConfiguration = ...")
            }
            let new = EventLoopGroupConnectionPool(
                source: APNSConnectionSource(configuration: configuration),
                maxConnectionsPerEventLoop: 1,
                logger: logger,
                on: eventLoopGroup
            )
            storage.set(PoolKey.self, to: new) {
                $0.shutdown()
            }
            return new
        }
    }
}
