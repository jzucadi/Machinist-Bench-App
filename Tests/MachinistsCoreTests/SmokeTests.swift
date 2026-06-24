import XCTest
@testable import MachinistsCore

final class SmokeTests: XCTestCase {
    func testModuleLoads() {
        XCTAssertEqual(Core.version, "1.0")
    }
}
