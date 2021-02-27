import Vapor

public struct APNS {
    let application: Application
    public let eventLoop: EventLoop
    public let logger: Logger?
}

extension APNS: APNSwiftClient {

    public func send(
        rawBytes payload: ByteBuffer,
        pushType: APNSwiftConnection.PushType,
        to deviceToken: String,
        expiration: Date?,
        priority: Int?,
        collapseIdentifier: String?,
        topic: String?,
        logger: Logger?,
        apnsID: UUID? = nil
    ) -> EventLoopFuture<Void> {
        self.application.apnsPool.withConnection(
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
