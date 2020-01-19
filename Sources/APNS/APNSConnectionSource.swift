import AsyncKit
import Logging

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
        !self.channel.isActive
    }
}
