import Vapor

extension Request {
    public var apns: APNS {
        .init(request: self)
    }

    public struct APNS {
        let request: Request
    }
}

extension Request.APNS: APNSwiftClient {
    public var logger: Logger? {
        self.request.logger
    }

    public var eventLoop: EventLoop {
        self.request.eventLoop
    }

    public func send(
        rawBytes payload: ByteBuffer,
        pushType: APNSwiftConnection.PushType,
        to deviceToken: String,
        expiration: Date?,
        priority: Int?,
        collapseIdentifier: String?,
        topic: String?,
        logger: Logger?
    ) -> EventLoopFuture<Void> {
        self.request.application.apns.pool.withConnection(
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
                logger: logger
            )
        }
    }
}
