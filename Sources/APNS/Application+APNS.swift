import Vapor

extension Application.APNS {
    
    public struct ConfigID: Hashable, Codable {
        
        public let string: String
        
        public init(string: String) {
            self.string = string
        }
    }
}
extension Application.APNS.ConfigID: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(string: value)
    }
}

extension Application {
    
    public var apns: APNS {
        .init(application: self)
    }

    public struct APNS {
        
        struct ConfigurationsKey: StorageKey, LockKey {
            typealias Value = APNSConfigurations
        }

        public var configurations: APNSConfigurations {
            if let existing = self.application.storage[ConfigurationsKey.self] {
                return existing
            } else {
                let lock = self.application.locks.lock(for: ConfigurationsKey.self)
                lock.lock()
                defer { lock.unlock() }
                let new = APNSConfigurations()
                self.application.storage.set(ConfigurationsKey.self, to: new) {
                    $0.shutdown()
                }
                return new
            }
        }

        public var configuration: APNSwiftConfiguration? {
            get {
                self.configurations.configuration()
            }
            nonmutating set {
                if let config = newValue {
                    self.configurations.use(config, as: "default", isDefault: true)
                }
            }
        }

        struct PoolKey: StorageKey, LockKey {
            typealias Value = EventLoopGroupConnectionPool<APNSConnectionSource>
        }

        public func pool(for configID: Application.APNS.ConfigID? = nil) -> EventLoopGroupConnectionPool<APNSConnectionSource> {
            return self.configurations.pool(
                for: configID,
                logger: self.application.logger,
                on: self.application.eventLoopGroup)
        }

        let application: Application
    }
}

extension Application.APNS: APNSwiftClient {
    public var logger: Logger? {
        self.application.logger
    }

    public var eventLoop: EventLoop {
        self.application.eventLoopGroup.next()
    }

    public func batchSend(
        rawBytes payload: ByteBuffer,
        pushType: APNSwiftConnection.PushType,
        to deviceToken: String...,
        expiration: Date?,
        priority: Int?,
        collapseIdentifier: String?,
        topic: String?,
        logger: Logger?,
        apnsID: UUID? = nil,
        for configID: Application.APNS.ConfigID? = nil
    ) -> EventLoopFuture<Void> {
        batchSend(rawBytes: payload,
                  pushType: pushType,
                  to: deviceToken,
                  expiration: expiration,
                  priority: priority,
                  collapseIdentifier: collapseIdentifier,
                  topic: topic,
                  logger: logger,
                  apnsID: apnsID,
                  for: configID)
    }

    public func batchSend(
        rawBytes payload: ByteBuffer,
        pushType: APNSwiftConnection.PushType,
        to deviceToken: [String],
        expiration: Date?,
        priority: Int?,
        collapseIdentifier: String?,
        topic: String?,
        logger: Logger?,
        apnsID: UUID? = nil,
        for configID: Application.APNS.ConfigID? = nil
    ) -> EventLoopFuture<Void> {
        deviceToken.map {
            send(rawBytes: payload,
                 pushType: pushType,
                 to: $0,
                 expiration: expiration,
                 priority: priority,
                 collapseIdentifier: collapseIdentifier,
                 topic: topic,
                 logger: logger,
                 apnsID: apnsID,
                 for: configID)
        }.flatten(on: self.eventLoop)
    }

    public func send(
        rawBytes payload: ByteBuffer,
        pushType: APNSwiftConnection.PushType,
        to deviceToken: String,
        expiration: Date?,
        priority: Int?,
        collapseIdentifier: String?,
        topic: String?,
        logger: Logger?,
        apnsID: UUID? = nil,
        for configID: Application.APNS.ConfigID? = nil
    ) -> EventLoopFuture<Void> {
        self.application.apns.pool(for: configID).withConnection(
            logger: logger,
            on: self.eventLoop
        ) {
            $0.send(
                rawBytes: payload,
                pushType: pushType,
                to: deviceToken,
                expiration: expiration,
                priority: priority,
                collapseIdentifier: collapseIdentifier,
                topic: topic,
                logger: logger,
                apnsID: apnsID
            )
        }
    }
}
