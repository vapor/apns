import Vapor

extension Application {
    public var apns: APNS {
        .init(application: self)
    }

    public struct APNS {
        final class Storage {
            var pool: EventLoopGroupConnectionPool<APNSConnectionSource>?
            init() { }
        }

        struct Key: StorageKey {
            typealias Value = Storage
        }

        struct Lifecycle: LifecycleHandler {
            func shutdown(_ application: Application) {
                if let pool = application.apns.storage.pool {
                    pool.shutdown()
                }
            }
        }

        var storage: Storage {
            if self.application.storage[Key.self] == nil {
                self.initialize()
            }
            return self.application.storage[Key.self]!
        }

        let application: Application

        public func configure(_ configuration: APNSwiftConfiguration) {
            assert(self.storage.pool == nil, "APNS can only be configured once")
            self.storage.pool = .init(
                source: .init(configuration: configuration),
                maxConnectionsPerEventLoop: 1,
                logger: self.application.logger,
                on: self.application.eventLoopGroup
            )
        }

        func initialize() {
            self.application.storage[Key.self] = .init()
            self.application.lifecycle.use(Lifecycle())
        }
    }
}

private struct BasicNotification: APNSwiftNotification {
    let aps: APNSwiftPayload
    init(aps: APNSwiftPayload) {
        self.aps = aps
    }
}

extension Request {
    public var apns: APNS {
        .init(request: self)
    }

    public struct APNS {
        let request: Request

        public func send(
            _ alert: APNSwiftPayload.APNSwiftAlert,
            pushType: APNSwiftConnection.PushType = .alert,
            to deviceToken: String,
            with encoder: JSONEncoder = JSONEncoder(),
            expiration: Date? = nil,
            priority: Int? = nil,
            collapseIdentifier: String? = nil,
            topic: String? = nil
        ) -> EventLoopFuture<Void> {
            self.send(APNSwiftPayload(alert: alert), pushType: pushType, to: deviceToken, with: encoder, expiration: expiration, priority: priority, collapseIdentifier: collapseIdentifier, topic: topic)
        }

        public func send(
            _ payload: APNSwiftPayload,
            pushType: APNSwiftConnection.PushType = .alert,
            to deviceToken: String,
            with encoder: JSONEncoder = JSONEncoder(),
            expiration: Date? = nil,
            priority: Int? = nil,
            collapseIdentifier: String? = nil,
            topic: String? = nil
        ) -> EventLoopFuture<Void> {
            self.send(BasicNotification(aps: payload), pushType: pushType, to: deviceToken, with: encoder, expiration: expiration, priority: priority, collapseIdentifier: collapseIdentifier, topic: topic)
        }

        public func send<Notification>(
            _ notification: Notification,
            pushType: APNSwiftConnection.PushType = .alert,
            to deviceToken: String,
            with encoder: JSONEncoder = JSONEncoder(),
            expiration: Date? = nil,
            priority: Int? = nil,
            collapseIdentifier: String? = nil,
            topic: String? = nil
        ) -> EventLoopFuture<Void>
            where Notification: APNSwiftNotification
        {
            guard let pool = self.request.application.apns.storage.pool else {
                fatalError("APNS not configured. Configure with app.apns.configure(...)")
            }
            return pool.withConnection(
                logger: self.request.logger,
                on: self.request.eventLoop
            ) {
                $0.send(
                    notification,
                    pushType: pushType,
                    to: deviceToken,
                    with: encoder,
                    expiration: expiration,
                    priority: priority,
                    collapseIdentifier: collapseIdentifier,
                    topic: topic
                )
            }
        }
    }
}

public final class APNSConnectionSource: ConnectionPoolSource {
    private let configuration: APNSwiftConfiguration

    public init(configuration: APNSwiftConfiguration) {
        self.configuration = configuration
    }
    public func makeConnection(
        logger: Logger,
        on eventLoop: EventLoop
    ) -> EventLoopFuture<APNSwiftConnection> {
        APNSwiftConnection.connect(configuration: self.configuration, on: eventLoop)
    }
}

extension APNSwiftConnection: ConnectionPoolItem {
    public var eventLoop: EventLoop {
        self.channel.eventLoop
    }

    public var isClosed: Bool {
        self.channel.isActive
    }
}
