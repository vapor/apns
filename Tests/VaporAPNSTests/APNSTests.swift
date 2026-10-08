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
    try await withContainers { apns in
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

@Test("Containers")
func testContainers() async throws {
    try await withContainers { apns in
        await apns.use(
            try testConfiguration(),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .default
        )

        let defaultContainer = await apns.container()
        #expect(defaultContainer != nil)

        let defaultMethodContainer = await apns.container(for: .default)
        let defaultComputedContainer = await apns.container
        #expect(defaultContainer === defaultMethodContainer)
        #expect(defaultContainer === defaultComputedContainer)

        let client = await apns.client
        #expect(client === defaultContainer?.client)

        await apns.use(
            try testConfiguration(environment: .custom(url: "http://apple.com")),
            responseDecoder: JSONDecoder(),
            requestEncoder: JSONEncoder(),
            as: .custom
        )

        // The first container registered stays the default.
        let containerPostCustom = await apns.container()
        #expect(containerPostCustom === defaultContainer)
        let clientPostCustom = await apns.client
        #expect(clientPostCustom === defaultContainer?.client)
    }
}

@Test("Custom Containers")
func testCustomContainers() async throws {
    try await withContainers { apns in
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

        // The last container registered as default wins.
        let containerPostCustom = await apns.container()
        let customContainer = await apns.container(for: .custom)
        #expect(containerPostCustom != nil)
        #expect(containerPostCustom === customContainer)

        let client = await apns.client
        #expect(client === customContainer?.client)
    }
}

@Test("Non-Default Containers")
func testNonDefaultContainers() async throws {
    try await withContainers { apns in
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

        let defaultContainer = await apns.container()
        let customContainer = await apns.container(for: .custom)
        #expect(defaultContainer != nil)
        #expect(customContainer !== defaultContainer)

        let customClient = await apns.client(.custom)
        #expect(customClient === customContainer?.client)
        #expect(customClient !== defaultContainer?.client)
    }
}

@Test("Switching the default")
func testSwitchingDefault() async throws {
    try await withContainers { apns in
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

        let defaultContainer = await apns.container()
        let customContainer = await apns.container(for: .custom)
        #expect(defaultContainer === customContainer)
    }
}
