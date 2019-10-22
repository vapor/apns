public final class APNSConnectionSource: ConnectionPoolSource {
    public let eventLoop: EventLoop
    private let configuration: APNSwiftConfiguration

    public init(configuration: APNSwiftConfiguration, on eventLoop: EventLoop) {
        self.eventLoop = eventLoop
        self.configuration = configuration
    }
    public func makeConnection() -> EventLoopFuture<APNSwiftConnection> {
        return APNSwiftConnection.connect(configuration: self.configuration, on: self.eventLoop)
    }
}
extension APNSwiftConnection: ConnectionPoolItem {
    public var isClosed: Bool {
        // TODO: implement this.
        return false
    }
}
