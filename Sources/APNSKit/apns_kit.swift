public final class APNSConnectionSource: ConnectionPoolSource {
    public let eventLoop: EventLoop
    private let configuration: APNSConfiguration

    public init(configuration: APNSConfiguration, on eventLoop: EventLoop) {
        self.eventLoop = eventLoop
        self.configuration = configuration
    }
    public func makeConnection() -> EventLoopFuture<APNSConnection> {
        return APNSConnection.connect(configuration: self.configuration, on: self.eventLoop)
    }
}
extension APNSConnection: ConnectionPoolItem {
    public var isClosed: Bool {
        // TODO: implement this.
        return false
    }
}
