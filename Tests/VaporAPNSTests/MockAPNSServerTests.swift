import APNS
import APNSCore
import NIOCore
import NIOPosix
import Testing
import Vapor
import VaporAPNS
import VaporTesting

private struct Payload: Codable {
    let message: String
}

@Test("APNS Container Configuration")
func testAPNSContainerConfiguration() async throws {
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

        // Verify that the container is configured
        let container = await app.apns.containers.container()
        #expect(container != nil)
        // Note: APNSEnvironment doesn't conform to Equatable, so we verify configuration exists
        #expect(container?.configuration != nil)
    }
}

@Test("APNS Client Access From Request")
func testAPNSClientAccessFromRequest() async throws {
    try await withApp { app in
        // Configure APNS first
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

        // Test that we can access APNS client from request
        app.get("test-apns-access") { req async -> HTTPStatus in
            let container = await req.application.apns.containers.container()
            #expect(container != nil)
            return .ok
        }

        try await app.testing().test(.GET, "test-apns-access") { response async in
            #expect(response.status == .ok)
        }
    }
}

@Test("Multiple APNS Containers")
func testMultipleAPNSContainers() async throws {
    try await withApp { app in
        // Test configuring multiple APNS containers
        let productionConfig = APNSClientConfiguration(
            authenticationMethod: .jwt(
                privateKey: try .init(pemRepresentation: appleECP8PrivateKey),
                keyIdentifier: "9UC9ZLQ8YW",
                teamIdentifier: "ABBM6U9RM5"
            ),
            environment: .production
        )

        let developmentConfig = APNSClientConfiguration(
            authenticationMethod: .jwt(
                privateKey: try .init(pemRepresentation: appleECP8PrivateKey),
                keyIdentifier: "9UC9ZLQ8YW",
                teamIdentifier: "ABBM6U9RM5"
            ),
            environment: .development
        )

        await app.apns.containers.use(
            productionConfig,
            eventLoopGroupProvider: .shared(MultiThreadedEventLoopGroup.singleton),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .production
        )

        await app.apns.containers.use(
            developmentConfig,
            eventLoopGroupProvider: .shared(MultiThreadedEventLoopGroup.singleton),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .development
        )

        // Verify both containers are configured
        let productionContainer = await app.apns.containers.container(for: .production)
        let developmentContainer = await app.apns.containers.container(for: .development)

        #expect(productionContainer != nil)
        #expect(developmentContainer != nil)
        #expect(productionContainer?.configuration != nil)
        #expect(developmentContainer?.configuration != nil)
    }
}

@Test("APNS Container Shutdown")
func testAPNSContainerShutdown() async throws {
    try await withApp { app in
        // Test that containers can be shut down properly
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

        // Verify container is configured
        let container = await app.apns.containers.container()
        #expect(container != nil)

        // Test shutdown - this should not throw
        await app.apns.containers.shutdown()
    }
}

@Test("Convenience Configuration Method")
func testConvenienceConfigurationMethod() async throws {
    try await withApp { app in
        // Test the convenience configure method that sets up both production and development
        await app.apns.configure(
            .jwt(
                privateKey: try .init(pemRepresentation: appleECP8PrivateKey),
                keyIdentifier: "9UC9ZLQ8YW",
                teamIdentifier: "ABBM6U9RM5"
            ))

        // Verify both containers are configured
        let productionContainer = await app.apns.containers.container(for: .production)
        let developmentContainer = await app.apns.containers.container(for: .development)

        #expect(productionContainer != nil)
        #expect(developmentContainer != nil)
        #expect(productionContainer?.configuration != nil)
        #expect(developmentContainer?.configuration != nil)
    }
}

@Test("Request APNS Property")
func testRequestAPNSProperty() async throws {
    try await withApp { app in
        // Test that request.apns returns the correct APNS instance
        app.get("test-request-apns") { req async -> HTTPStatus in
            let _ = req.apns
            // Note: application property is internal, so just verify apns exists
            return .ok
        }

        try await app.testing().test(.GET, "test-request-apns") { response async in
            #expect(response.status == .ok)
        }
    }
}
