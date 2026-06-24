import XCTest
@testable import MachinistsCore

final class MaterialsTests: XCTestCase {
    func testCount() { XCTAssertEqual(Materials.all.count, 19) }

    func testOrderFirstAndLast() {
        XCTAssertEqual(Materials.all.first?.id, "alum")
        XCTAssertEqual(Materials.all.last?.id, "plastic")
    }

    func testLowCarbon() {
        let m = Materials.byID("lowc")!
        XCTAssertEqual(m.name, "Low-Carbon Steel (1018)")
        XCTAssertEqual(m.carbideSFM, 350...550)
        XCTAssertEqual(m.feedIPR, 0.012, accuracy: 1e-9)
        XCTAssertEqual(m.kp, 1.0, accuracy: 1e-9)
    }

    func testTitanium() {
        let m = Materials.byID("ti")!
        XCTAssertEqual(m.hssSFM, 30...50)
        XCTAssertEqual(m.kp, 1.2, accuracy: 1e-9)
    }

    func testInconel() {
        XCTAssertEqual(Materials.byID("inconel")!.kp, 2.2, accuracy: 1e-9)
    }
}
