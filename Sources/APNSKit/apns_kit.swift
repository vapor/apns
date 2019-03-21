import NIOAPNS
import NIO
import NIOKit

public final class APNSKitConnectionManager: ConnectionPoolSource {
    public let eventLoop: EventLoop
    private let config: APNSConfiguration
    
    deinit {
        // Kill connection
    }
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
        return false
    }
}

// Delete later when tests are in.
struct apns_kit {
    var text = "Hello, World!"
}
