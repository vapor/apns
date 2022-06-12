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

        app.apns.configuration = .init(
            authenticationConfig: authenticationConfig,
            topic: "MY_TOPIC",
            environment: .sandbox,
            eventLoopGroupProvider: .shared(app.eventLoopGroup),
            logger: app.logger
        )

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
}

