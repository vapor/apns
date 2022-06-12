import APNS
import XCTVapor

class APNSTests: XCTestCase {
    let appleECP8PrivateKey = """
    -----BEGIN PRIVATE KEY-----
    MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg2sD+kukkA8GZUpmm
    jRa4fJ9Xa/JnIG4Hpi7tNO66+OGgCgYIKoZIzj0DAQehRANCAATZp0yt0btpR9kf
    ntp4oUUzTV0+eTELXxJxFvhnqmgwGAm1iVW132XLrdRG/ntlbQ1yzUuJkHtYBNve
    y+77Vzsd
    -----END PRIVATE KEY-----
    """

    func testApplication() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        let authenticationConfig: APNSConfiguration.Authentication = .init(
            privateKey: try .loadFrom(string: appleECP8PrivateKey),
            teamIdentifier: "ABBM6U9RM5",
            keyIdentifier: "9UC9ZLQ8YW"
        )
        let apnsConfig: APNSConfiguration = .init(
            authenticationConfig: authenticationConfig,
            topic: "MY_TOPIC",
            environment: .sandbox,
            eventLoopGroupProvider: .shared(app.eventLoopGroup),
            logger: app.logger
        )
        app.apns.containers.use(apnsConfig, as: .default)

        app.get("test-push") { req -> HTTPStatus in
            try await req.apns.client.send(
                .init(title: "Hello", subtitle: "This is a test from vapor/apns"),
                to: "98AAD4A2398DDC58595F02FA307DF9A15C18B6111D1B806949549085A8E6A55D"
            )
            return .ok
        }
        try app.test(.GET, "test-push") { res in
            XCTAssertEqual(res.status, .internalServerError)
        }
    }

    func testContainers() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        let authenticationConfig: APNSConfiguration.Authentication = .init(
            privateKey: try .loadFrom(string: appleECP8PrivateKey),
            teamIdentifier: "ABBM6U9RM5",
            keyIdentifier: "9UC9ZLQ8YW"
        )

        let apnsConfig: APNSConfiguration = .init(
            authenticationConfig: authenticationConfig,
            topic: "MY_TOPIC",
            environment: .sandbox,
            eventLoopGroupProvider: .shared(app.eventLoopGroup),
            logger: app.logger
        )

        app.apns.containers.use(apnsConfig, as: .default, isDefault: true)

        let defaultContainer = app.apns.containers.container()
        XCTAssertNotNil(defaultContainer)
        let defaultMethodContainer = app.apns.containers.container(for: .default)!
        let defaultComputedContainer = app.apns.containers.container!
        XCTAssert(defaultContainer === defaultMethodContainer)
        XCTAssert(defaultContainer === defaultComputedContainer)

        app.get("test-push") { req -> HTTPStatus in
            XCTAssert(req.apns.client === defaultContainer?.client)

            return .ok
        }
        try app.test(.GET, "test-push") { res in
            XCTAssertEqual(res.status, .ok)
        }

        let customConfig: APNSConfiguration = .init(
            authenticationConfig: authenticationConfig,
            topic: "MY_TOPIC_CUSTOM",
            environment: .production,
            eventLoopGroupProvider: .shared(app.eventLoopGroup),
            logger: app.logger
        )

        app.apns.containers.use(customConfig, as: .custom, isDefault: true)

        let containerPostCustom = app.apns.containers.container()
        XCTAssertNotNil(containerPostCustom)
        app.get("test-push2") { req -> HTTPStatus in
            XCTAssert(req.apns.client === containerPostCustom?.client)

            return .ok
        }
        try app.test(.GET, "test-push2") { res in
            XCTAssertEqual(res.status, .ok)
        }
    }

    func testCustomContainers() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        let authenticationConfig: APNSConfiguration.Authentication = .init(
            privateKey: try .loadFrom(string: appleECP8PrivateKey),
            teamIdentifier: "ABBM6U9RM5",
            keyIdentifier: "9UC9ZLQ8YW"
        )

        let apnsConfig: APNSConfiguration = .init(
            authenticationConfig: authenticationConfig,
            topic: "MY_TOPIC",
            environment: .sandbox,
            eventLoopGroupProvider: .shared(app.eventLoopGroup),
            logger: app.logger
        )

        app.apns.containers.use(apnsConfig, as: .default, isDefault: true)

        let customConfig: APNSConfiguration = .init(
            authenticationConfig: authenticationConfig,
            topic: "MY_TOPIC_CUSTOM",
            environment: .production,
            eventLoopGroupProvider: .shared(app.eventLoopGroup),
            logger: app.logger
        )

        app.apns.containers.use(customConfig, as: .custom, isDefault: true)

        let containerPostCustom = app.apns.containers.container()
        XCTAssertNotNil(containerPostCustom)
        app.get("test-push2") { req -> HTTPStatus in
            XCTAssert(req.apns.client === containerPostCustom?.client)

            return .ok
        }
        try app.test(.GET, "test-push2") { res in
            XCTAssertEqual(res.status, .ok)
        }
    }

    func testNonDefaultContainers() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        let authenticationConfig: APNSConfiguration.Authentication = .init(
            privateKey: try .loadFrom(string: appleECP8PrivateKey),
            teamIdentifier: "ABBM6U9RM5",
            keyIdentifier: "9UC9ZLQ8YW"
        )

        let apnsConfig: APNSConfiguration = .init(
            authenticationConfig: authenticationConfig,
            topic: "MY_TOPIC",
            environment: .sandbox,
            eventLoopGroupProvider: .shared(app.eventLoopGroup),
            logger: app.logger
        )

        app.apns.containers.use(apnsConfig, as: .default, isDefault: true)

        let customConfig: APNSConfiguration = .init(
            authenticationConfig: authenticationConfig,
            topic: "MY_TOPIC_CUSTOM",
            environment: .production,
            eventLoopGroupProvider: .shared(app.eventLoopGroup),
            logger: app.logger
        )

        app.apns.containers.use(customConfig, as: .custom)

        let containerPostCustom = app.apns.containers.container()
        let containerNonDefaultCustom = app.apns.containers.container(for: .custom)
        XCTAssert(app.apns.containers.container(for: .custom) !== containerPostCustom)
        XCTAssertNotNil(containerPostCustom)
        app.get("test-push2") { req -> HTTPStatus in
            XCTAssert(req.apns.client(.custom) !== containerPostCustom?.client)
            XCTAssert(req.apns.client(.custom) === containerNonDefaultCustom?.client)
            return .ok
        }
        try app.test(.GET, "test-push2") { res in
            XCTAssertEqual(res.status, .ok)
        }
    }
}

fileprivate extension APNSContainers.ID {
    static var custom: APNSContainers.ID {
        return .init(string: "custom")
    }
}
