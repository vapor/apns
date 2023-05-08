import APNS
import VaporAPNS
import XCTVapor

class APNSTests: XCTestCase {
    struct Payload: Codable {}
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
        let apnsConfig = APNSClientConfiguration(
            authenticationMethod: .jwt(
                privateKey: try .init(pemRepresentation: appleECP8PrivateKey),
                keyIdentifier: "9UC9ZLQ8YW",
                teamIdentifier: "ABBM6U9RM5"
            ),
            environment: .sandbox
        )

        app.apns.containers.use(
            apnsConfig,
            eventLoopGroupProvider: .createNew,
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .default
        )

        app.get("test-push") { req -> HTTPStatus in
            try await req.apns.client.sendAlertNotification(
                .init(
                    alert: .init(
                        title: .raw("Hello"),
                        subtitle: .raw("This is a test from vapor/apns")
                    ),
                    expiration: .immediately,
                    priority: .immediately,
                    topic: "MY_TOPC",
                    payload: Payload()
                ),
                deviceToken: "98AAD4A2398DDC58595F02FA307DF9A15C18B6111D1B806949549085A8E6A55D"
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
        app.logger.logLevel = .trace
        let authConfig: APNSClientConfiguration.AuthenticationMethod = .jwt(
            privateKey: try .init(pemRepresentation: appleECP8PrivateKey),
            keyIdentifier: "9UC9ZLQ8YW",
            teamIdentifier: "ABBM6U9RM5"
        )

        let apnsConfig = APNSClientConfiguration(
            authenticationMethod: authConfig,
            environment: .sandbox
        )

        app.apns.containers.use(
            apnsConfig,
            eventLoopGroupProvider: .createNew,
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .default
        )

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

        let customConfig: APNSClientConfiguration = .init(
            authenticationMethod: authConfig,
            environment: .custom(url: "http://apple.com")
        )

        app.apns.containers.use(
            customConfig,
            eventLoopGroupProvider: .createNew,
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .custom
        )

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

        let authConfig: APNSClientConfiguration.AuthenticationMethod = .jwt(
            privateKey: try .init(pemRepresentation: appleECP8PrivateKey),
            keyIdentifier: "9UC9ZLQ8YW",
            teamIdentifier: "ABBM6U9RM5"
        )

        let apnsConfig = APNSClientConfiguration(
            authenticationMethod: authConfig,
            environment: .sandbox
        )

        app.apns.containers.use(
            apnsConfig,
            eventLoopGroupProvider: .createNew,
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .default,
            isDefault: true
        )

        let customConfig: APNSClientConfiguration = .init(
            authenticationMethod: authConfig,
            environment: .custom(url: "http://apple.com")
        )

        app.apns.containers.use(
            customConfig,
            eventLoopGroupProvider: .createNew,
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .custom,
            isDefault: true
        )

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

        let authConfig: APNSClientConfiguration.AuthenticationMethod = .jwt(
            privateKey: try .init(pemRepresentation: appleECP8PrivateKey),
            keyIdentifier: "9UC9ZLQ8YW",
            teamIdentifier: "ABBM6U9RM5"
        )

        let apnsConfig = APNSClientConfiguration(
            authenticationMethod: authConfig,
            environment: .sandbox
        )

        app.apns.containers.use(
            apnsConfig,
            eventLoopGroupProvider: .createNew,
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .default,
            isDefault: true
        )

        let customConfig: APNSClientConfiguration = .init(
            authenticationMethod: authConfig,
            environment: .custom(url: "http://apple.com")
        )

        app.apns.containers.use(
            customConfig,
            eventLoopGroupProvider: .createNew,
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .custom
        )

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
