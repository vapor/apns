public final class APNSConnectionSource: ConnectionPoolSource {
    public let eventLoop: EventLoop
    private let config: APNSConfiguration
    
    public init(config: APNSConfiguration, on eventLoop: EventLoop) {
        self.eventLoop = eventLoop
        self.config = config
    }
    public func makeConnection() -> EventLoopFuture<APNSConnection> {
        return APNSConnection.connect(configuration: self.config, on: self.eventLoop)
    }
}
extension APNSConnection: ConnectionPoolItem {
    public var isClosed: Bool {
        // TODO: implement this.
        return false
    }
}

// Delete later when tests are in.
struct apns_kit {
    var text = "Hello, World!"
}
