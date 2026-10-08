import APNS
import APNSCore
import HTTPTypes
import RoutingKit
import ServiceLifecycle
import Testing
import Vapor
import VaporAPNS
import VaporTesting

#if canImport(FoundationEssentials)
    import FoundationEssentials
#else
    import Foundation
#endif

@Test("APNS Container Configuration")
func testAPNSContainerConfiguration() async throws {
    try await withContainers { apns in
        await apns.use(
            try testConfiguration(),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .default
        )

        let container = await apns.container()
        #expect(container != nil)
        // Note: APNSEnvironment doesn't conform to Equatable, so we verify configuration exists
        #expect(container?.configuration != nil)
    }
}

@Test("Multiple APNS Containers")
func testMultipleAPNSContainers() async throws {
    try await withContainers { apns in
        await apns.use(
            try testConfiguration(environment: .production),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .production
        )

        await apns.use(
            try testConfiguration(environment: .development),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .development
        )

        let productionContainer = await apns.container(for: .production)
        let developmentContainer = await apns.container(for: .development)
        #expect(productionContainer != nil)
        #expect(developmentContainer != nil)
        #expect(productionContainer !== developmentContainer)
    }
}

@Test("APNS Container Shutdown")
func testAPNSContainerShutdown() async throws {
    let apns = APNSContainers()
    await apns.use(
        try testConfiguration(),
        responseDecoder: JSONDecoder(),
        requestEncoder: JSONEncoder(),
        as: .default
    )
    #expect(await apns.container() != nil)

    await apns.shutdown()

    #expect(await apns.container() == nil)
    // Shutting down twice is harmless.
    await apns.shutdown()
}

@Test("Shuts down with the service group")
func testServiceShutdown() async throws {
    let apns = APNSContainers()
    await apns.use(
        try testConfiguration(),
        responseDecoder: JSONDecoder(),
        requestEncoder: JSONEncoder(),
        as: .default
    )

    await withTaskGroup(of: Void.self) { group in
        group.addTask {
            try? await apns.run()
        }
        group.addTask {
            // Give the service a moment to start waiting, then cancel it.
            try? await Task.sleep(for: .milliseconds(50))
        }
        await group.next()
        group.cancelAll()
        await group.waitForAll()
    }

    #expect(await apns.container() == nil)
}

@Test("Convenience Configuration Method")
func testConvenienceConfigurationMethod() async throws {
    try await withContainers { apns in
        await apns.configure(try testAuthenticationMethod())

        let productionContainer = await apns.container(for: .production)
        let developmentContainer = await apns.container(for: .development)
        #expect(productionContainer != nil)
        #expect(developmentContainer != nil)
        #expect(productionContainer !== developmentContainer)

        // Production is registered first, so it is the default.
        let defaultContainer = await apns.container()
        #expect(defaultContainer === productionContainer)
    }
}

@Test("Registers as an application service")
func testAddService() async throws {
    try await withApp { app in
        let apns = APNSContainers()
        await apns.configure(try testAuthenticationMethod())
        app.addService(apns)

        app.get("has-apns") { _ -> HTTPResponse.Status in
            await apns.container(for: .development) != nil ? .ok : .internalServerError
        }

        try await app.testing { client in
            let response = try await client.get("has-apns")
            #expect(response.status == .ok)
        }

        await apns.shutdown()
    }
}
