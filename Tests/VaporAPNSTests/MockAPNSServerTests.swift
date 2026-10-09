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

@Test("APNs Client Configuration")
func testAPNSClientConfiguration() async throws {
    try await withClients { apns in
        await apns.use(
            try testConfiguration(),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .default
        )

        let entry = await apns.entry()
        #expect(entry != nil)
        // Note: APNSEnvironment doesn't conform to Equatable, so we verify configuration exists
        #expect(entry?.configuration != nil)
    }
}

@Test("Multiple APNs Clients")
func testMultipleAPNSClients() async throws {
    try await withClients { apns in
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

        let productionEntry = await apns.entry(for: .production)
        let developmentEntry = await apns.entry(for: .development)
        #expect(productionEntry != nil)
        #expect(developmentEntry != nil)
        #expect(productionEntry !== developmentEntry)
    }
}

@Test("APNs Client Shutdown")
func testAPNSClientShutdown() async throws {
    let apns = APNSClients()
    await apns.use(
        try testConfiguration(),
        responseDecoder: JSONDecoder(),
        requestEncoder: JSONEncoder(),
        as: .default
    )
    #expect(await apns.entry() != nil)

    await apns.shutdown()

    #expect(await apns.entry() == nil)
    // Shutting down twice is harmless.
    await apns.shutdown()
}

@Test("Shuts down with the service group")
func testServiceShutdown() async throws {
    let apns = APNSClients()
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

    #expect(await apns.entry() == nil)
}

@Test("Convenience Configuration Method")
func testConvenienceConfigurationMethod() async throws {
    try await withClients { apns in
        await apns.configure(try testAuthenticationMethod())

        let productionEntry = await apns.entry(for: .production)
        let developmentEntry = await apns.entry(for: .development)
        #expect(productionEntry != nil)
        #expect(developmentEntry != nil)
        #expect(productionEntry !== developmentEntry)

        // Production is registered first, so it is the default.
        let defaultEntry = await apns.entry()
        #expect(defaultEntry === productionEntry)
    }
}

@Test("Registers as an application service")
func testAddService() async throws {
    try await withApp { app in
        let apns = APNSClients()
        await apns.configure(try testAuthenticationMethod())
        app.addService(apns)

        app.get("has-apns") { _ -> HTTPResponse.Status in
            await apns.entry(for: .development) != nil ? .ok : .internalServerError
        }

        try await app.testing { client in
            let response = try await client.get("has-apns")
            #expect(response.status == .ok)
        }

        await apns.shutdown()
    }
}
