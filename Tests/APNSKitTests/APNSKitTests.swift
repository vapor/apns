import XCTest
@testable import APSNKit

final class APNSKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(apns_kit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
