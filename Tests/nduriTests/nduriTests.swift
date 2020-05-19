import XCTest
@testable import nduri

final class nduriTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(nduri().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
