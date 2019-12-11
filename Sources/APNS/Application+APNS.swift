import Vapor

extension Application {
    public var apns: APNS {
        .init(application: self)
    }

    public struct APNS {
        struct ConfigurationKey: StorageKey {
            typealias Value = APNSwiftConfiguration
        }

        public var configuration: APNSwiftConfiguration? {
            get {
                self.application.storage[ConfigurationKey.self]
            }
            nonmutating set {
                self.application.storage[ConfigurationKey.self] = newValue
            }
        }


        struct PoolKey: StorageKey, LockKey {
            typealias Value = EventLoopGroupConnectionPool<APNSConnectionSource>
        }

        internal var pool: EventLoopGroupConnectionPool<APNSConnectionSource> {
            if let existing = self.application.storage[PoolKey.self] {
                return existing
            } else {
                let lock = self.application.locks.lock(for: PoolKey.self)
                lock.lock()
                defer { lock.unlock() }
                guard let configuration = self.configuration else {
                    fatalError("APNS not configured. Use app.apns.configuration = ...")
                }
                let new = EventLoopGroupConnectionPool(
                    source: APNSConnectionSource(configuration: configuration),
                    maxConnectionsPerEventLoop: 1,
                    logger: self.application.logger,
                    on: self.application.eventLoopGroup
                )
                self.application.storage.set(PoolKey.self, to: new) {
                    $0.shutdown()
                }
                return new
            }
        }

        let application: Application
    }
}
