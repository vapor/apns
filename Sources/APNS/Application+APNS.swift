import Vapor

extension Application {
    public var apns: APNS {
        .init(application: self)
    }

    public struct APNS {
        public var connection: APNSwiftConnection {
            guard let configuration = configuration else {
                fatalError("APNS not configured. Use app.apns.configuration = ...")
            }
            return APNSwiftConnection(configuration: configuration, logger: logger)
        }

        struct ConfigurationKey: StorageKey {
            typealias Value = APNSwiftConfiguration
        }

        public var configuration: APNSwiftConfiguration? {
            get {
                self.application.storage[ConfigurationKey.self]
            }
            nonmutating set {
                self.application.storage[ConfigurationKey.self] = newValue
            }
        }

        let application: Application
    }
}

extension Application.APNS: APNSwiftClient {
    public func batchSend(
        rawBytes payload: ByteBuffer,
        pushType: APNSwiftConnection.PushType,
        to deviceToken: String...,
        on environment: APNSwift.APNSwiftConfiguration.Environment?,
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
        try await connection.send(
            rawBytes: payload,
            pushType: pushType,
            to: deviceToken,
            on: environment,
            expiration: expiration,
            priority: priority,
            collapseIdentifier: collapseIdentifier,
            topic: topic,
            logger: logger,
            apnsID: apnsID
        )
    }

    public var logger: Logger? {
        self.application.logger
    }
}
