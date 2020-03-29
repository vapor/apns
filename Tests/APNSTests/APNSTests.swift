import APNS
import XCTVapor

class APNSTests: XCTestCase {
    func testApplication() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.apns.configuration = try .init(
            authenticationMethod: .jwt(
                key: .private(filePath: "/Users/kylebrowning/Desktop/AuthKey_9UC9ZLQ8YW.p8"),
                keyIdentifier: "9UC9ZLQ8YW",
                teamIdentifier: "ABBM6U9RM5"
            ),
            topic: "com.grasscove.Fern",
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
