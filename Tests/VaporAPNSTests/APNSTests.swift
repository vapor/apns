import APNS
import APNSCore
import HTTPTypes
import RoutingKit
import Testing
import Vapor
import VaporAPNS
import VaporTesting

#if canImport(FoundationEssentials)
    import FoundationEssentials
#else
    import Foundation
#endif

private struct Payload: Codable {}

@Test("Sending through a route")
func testApplication() async throws {
    try await withClients { apns in
        await apns.use(
            try testConfiguration(),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .default
        )

        try await withApp { app in
            app.get("test-push") { _ -> HTTPResponse.Status in
                try await apns.client.sendAlertNotification(
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

            try await app.testing { client in
                let response = try await client.get("test-push")
                #expect(response.status == .internalServerError)
            }
        }
    }
}

@Test("Clients")
func testClients() async throws {
    try await withClients { apns in
        await apns.use(
            try testConfiguration(),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .default
        )

        let defaultEntry = await apns.entry()
        #expect(defaultEntry != nil)

        let defaultMethodEntry = await apns.entry(for: .default)
        let defaultComputedEntry = await apns.entry
        #expect(defaultEntry === defaultMethodEntry)
        #expect(defaultEntry === defaultComputedEntry)

        let client = await apns.client
        #expect(client === defaultEntry?.client)

        await apns.use(
            try testConfiguration(environment: .custom(url: "http://apple.com")),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .custom
        )

        // The first client registered stays the default.
        let entryPostCustom = await apns.entry()
        #expect(entryPostCustom === defaultEntry)
        let clientPostCustom = await apns.client
        #expect(clientPostCustom === defaultEntry?.client)
    }
}

@Test("Custom Clients")
func testCustomClients() async throws {
    try await withClients { apns in
        await apns.use(
            try testConfiguration(),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .default,
            isDefault: true
        )

        await apns.use(
            try testConfiguration(environment: .custom(url: "http://apple.com")),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .custom,
            isDefault: true
        )

        // The last client registered as default wins.
        let entryPostCustom = await apns.entry()
        let customEntry = await apns.entry(for: .custom)
        #expect(entryPostCustom != nil)
        #expect(entryPostCustom === customEntry)

        let client = await apns.client
        #expect(client === customEntry?.client)
    }
}

@Test("Non-Default Clients")
func testNonDefaultClients() async throws {
    try await withClients { apns in
        await apns.use(
            try testConfiguration(),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .default,
            isDefault: true
        )

        await apns.use(
            try testConfiguration(environment: .custom(url: "http://apple.com")),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .custom
        )

        let defaultEntry = await apns.entry()
        let customEntry = await apns.entry(for: .custom)
        #expect(defaultEntry != nil)
        #expect(customEntry !== defaultEntry)

        let customClient = await apns.client(.custom)
        #expect(customClient === customEntry?.client)
        #expect(customClient !== defaultEntry?.client)
    }
}

@Test("Switching the default")
func testSwitchingDefault() async throws {
    try await withClients { apns in
        await apns.use(
            try testConfiguration(),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .default
        )
        await apns.use(
            try testConfiguration(environment: .custom(url: "http://apple.com")),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .custom
        )

        await apns.default(to: .custom)

        let defaultEntry = await apns.entry()
        let customEntry = await apns.entry(for: .custom)
        #expect(defaultEntry === customEntry)
    }
}
