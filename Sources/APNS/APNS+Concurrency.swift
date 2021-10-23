#if compiler(>=5.5) && canImport(_Concurrency)
import NIOCore
import Vapor

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension Application.APNS {
    public func batchSend(
        rawBytes payload: ByteBuffer,
        pushType: APNSwiftConnection.PushType,
        to deviceToken: String...,
        expiration: Date?,
        priority: Int?,
        collapseIdentifier: String?,
        topic: String?,
        logger: Logger?,
        apnsID: UUID? = nil)
    async throws {
        try await batchSend(
            rawBytes: payload,
            pushType: pushType,
            to: deviceToken,
            expiration: expiration,
            priority: priority,
            collapseIdentifier: collapseIdentifier,
            topic: topic,
            logger: logger,
            apnsID: apnsID)
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
        apnsID: UUID? = nil)
    async throws {
        try await batchSend(
            rawBytes: payload,
            pushType: pushType,
            to: deviceToken,
            expiration: expiration,
            priority: priority,
            collapseIdentifier: collapseIdentifier,
            topic: topic,
            logger: logger,
            apnsID: apnsID).get()
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
        apnsID: UUID? = nil
    ) async throws {
        try await self.send(rawBytes: payload, pushType: pushType, to: deviceToken, expiration: expiration, priority: priority, collapseIdentifier: collapseIdentifier, topic: topic, logger: logger, apnsID: apnsID).get()
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension Request.APNS {
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
    ) async throws {
        try await send(rawBytes: payload, pushType: pushType, to: deviceToken, expiration: expiration, priority: priority, collapseIdentifier: collapseIdentifier, topic: topic, logger: logger, apnsID: apnsID).get()
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension APNSConnectionSource {
    public func makeConnection(
        logger: Logger,
        on eventLoop: EventLoop
    ) async throws -> APNSwiftConnection {
        try await APNSwiftConnection.connect(configuration: self.configuration, on: eventLoop).get()
    }
}

#endif
