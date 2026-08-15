import APNS
import APNSCore
import Testing
import Vapor
import VaporAPNS
import VaporTesting

private struct Payload: Codable {}

@Test("Application")
func testApplication() async throws {
    try await withApp { app in
        let apnsConfig = APNSClientConfiguration(
            authenticationMethod: .jwt(
                privateKey: try .init(pemRepresentation: appleECP8PrivateKey),
                keyIdentifier: "9UC9ZLQ8YW",
                teamIdentifier: "ABBM6U9RM5"
            ),
            environment: .development
        )

        await app.apns.containers.use(
            apnsConfig,
            eventLoopGroupProvider: .shared(MultiThreadedEventLoopGroup.singleton),
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

        try await app.testing().test(.GET, "test-push") { response async in
            #expect(response.status == .internalServerError)
        }
    }
}

@Test("Containers")
func testContainers() async throws {
    try await withApp { app in
        app.logger.logLevel = .trace
        let authConfig: APNSClientConfiguration.AuthenticationMethod = .jwt(
            privateKey: try .init(pemRepresentation: appleECP8PrivateKey),
            keyIdentifier: "9UC9ZLQ8YW",
            teamIdentifier: "ABBM6U9RM5"
        )

        let apnsConfig = APNSClientConfiguration(
            authenticationMethod: authConfig,
            environment: .development
        )

        await app.apns.containers.use(
            apnsConfig,
            eventLoopGroupProvider: .shared(MultiThreadedEventLoopGroup.singleton),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .default
        )

        let defaultContainer = await app.apns.containers.container()

        #expect(defaultContainer != nil)

        let defaultMethodContainer = await app.apns.containers.container(for: .default)!

        let defaultComputedContainer = await app.apns.containers.container!

        #expect(defaultContainer === defaultMethodContainer)
        #expect(defaultContainer === defaultComputedContainer)

        app.get("test-push") { req -> HTTPStatus in
            let client = await req.apns.client
            #expect(client === defaultContainer?.client)

            return .ok
        }

        try await app.testing().test(.GET, "test-push") { response async in
            #expect(response.status == .ok)
        }

        let customConfig: APNSClientConfiguration = .init(
            authenticationMethod: authConfig,
            environment: .custom(url: "http://apple.com")
        )

        await app.apns.containers.use(
            customConfig,
            eventLoopGroupProvider: .shared(MultiThreadedEventLoopGroup.singleton),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .custom
        )

        let containerPostCustom = await app.apns.containers.container()

        #expect(containerPostCustom != nil)

        app.get("test-push2") { req -> HTTPStatus in
            let client = await req.apns.client
            #expect(client === containerPostCustom?.client)
            return .ok
        }

        try await app.testing().test(.GET, "test-push2") { response async in
            #expect(response.status == .ok)
        }
    }
}

@Test("Custom Containers")
func testCustomContainers() async throws {
    try await withApp { app in
        let authConfig: APNSClientConfiguration.AuthenticationMethod = .jwt(
            privateKey: try .init(pemRepresentation: appleECP8PrivateKey),
            keyIdentifier: "9UC9ZLQ8YW",
            teamIdentifier: "ABBM6U9RM5"
        )

        let apnsConfig = APNSClientConfiguration(
            authenticationMethod: authConfig,
            environment: .development
        )

        await app.apns.containers.use(
            apnsConfig,
            eventLoopGroupProvider: .shared(MultiThreadedEventLoopGroup.singleton),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .default,
            isDefault: true
        )

        let customConfig: APNSClientConfiguration = .init(
            authenticationMethod: authConfig,
            environment: .custom(url: "http://apple.com")
        )

        await app.apns.containers.use(
            customConfig,
            eventLoopGroupProvider: .shared(MultiThreadedEventLoopGroup.singleton),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .custom,
            isDefault: true
        )

        let containerPostCustom = await app.apns.containers.container()

        #expect(containerPostCustom != nil)

        app.get("test-push2") { req -> HTTPStatus in
            let client = await req.apns.client
            #expect(client === containerPostCustom?.client)

            return .ok
        }

        try await app.testing().test(.GET, "test-push2") { response async in
            #expect(response.status == .ok)
        }
    }
}

@Test("Non-Default Containers")
func testNonDefaultContainers() async throws {
    try await withApp { app in
        let authConfig: APNSClientConfiguration.AuthenticationMethod = .jwt(
            privateKey: try .init(pemRepresentation: appleECP8PrivateKey),
            keyIdentifier: "9UC9ZLQ8YW",
            teamIdentifier: "ABBM6U9RM5"
        )

        let apnsConfig = APNSClientConfiguration(
            authenticationMethod: authConfig,
            environment: .development
        )

        await app.apns.containers.use(
            apnsConfig,
            eventLoopGroupProvider: .shared(MultiThreadedEventLoopGroup.singleton),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .default,
            isDefault: true
        )

        let customConfig: APNSClientConfiguration = .init(
            authenticationMethod: authConfig,
            environment: .custom(url: "http://apple.com")
        )

        await app.apns.containers.use(
            customConfig,
            eventLoopGroupProvider: .shared(MultiThreadedEventLoopGroup.singleton),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .custom
        )

        let containerPostCustom = await app.apns.containers.container()

        let containerNonDefaultCustom = await app.apns.containers.container(for: .custom)

        let customContainer = await app.apns.containers.container(for: .custom)

        #expect(customContainer !== containerPostCustom)
        #expect(containerPostCustom != nil)

        app.get("test-push2") { req -> HTTPStatus in
            let customClient = await req.apns.client(.custom)
            #expect(customClient !== containerPostCustom?.client)
            #expect(customClient === containerNonDefaultCustom?.client)
            return .ok
        }

        try await app.testing().test(.GET, "test-push2") { response async in
            #expect(response.status == .ok)
        }
    }
}

extension APNSContainers.ID {
    static var custom: APNSContainers.ID {
        return .init(string: "custom")
    }
}
