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

    public func batchSend(
        rawBytes payload: ByteBuffer,
        pushType: APNSwiftConnection.PushType,
        to deviceToken: String...,
        on environment: APNSwift.APNSwiftConfiguration.Environment? = nil,
        expiration: Date?,
        priority: Int?,
        collapseIdentifier: String?,
        topic: String?,
        logger: Logger?,
        apnsID: UUID? = nil
    ) async throws {
        for token in deviceToken {
            try await send(
                rawBytes: payload,
                pushType: pushType,
                to: token,
                on: environment,
                expiration: expiration,
                priority: priority,
                collapseIdentifier: collapseIdentifier,
                topic: topic,
                logger: logger ?? self.logger,
                apnsID: apnsID
            )
        }
    }

    public func send(
        rawBytes payload: NIOCore.ByteBuffer,
        pushType: APNSwift.APNSwiftConnection.PushType,
        to deviceToken: String,
        on environment: APNSwift.APNSwiftConfiguration.Environment? = nil,
        expiration: Date?,
        priority: Int?,
        collapseIdentifier: String?,
        topic: String?,
        logger: Logging.Logger?,
        apnsID: UUID?
    ) async throws {
        try await request.application.apns.connection.send(
            rawBytes: payload,
            pushType: pushType,
            to: deviceToken,
            on: environment,
            expiration: expiration,
            priority: priority,
            collapseIdentifier: collapseIdentifier,
            topic: topic,
            logger: logger ?? self.logger,
            apnsID: apnsID
        )
    }
}
