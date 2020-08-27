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

        app.apns.configuration = try .init(
            authenticationMethod: .jwt(
                key: .private(pem: appleECP8PrivateKey),
                keyIdentifier: "MY_KEY_ID",
                teamIdentifier: "MY_TEAM_ID"
            ),
            topic: "MY_TOPIC",
            environment: .sandbox
        )

        app.get("test-push") { req -> EventLoopFuture<HTTPStatus> in
            req.apns.send(
                .init(title: "Hello", subtitle: "This is a test from vapor/apns"),
                to: "98AAD4A2398DDC58595F02FA307DF9A15C18B6111D1B806949549085A8E6A55D"
            ).map { .ok }
        }

        try app.test(.GET, "test-push") { res in
            XCTAssertEqual(res.status, .internalServerError)
        }
    }
}

