import XCTest
@testable import MachinistsCore

final class UnitsTests: XCTestCase {
    func testSFMtoMetersPerMin() {
        XCTAssertEqual(Convert.mPerMin(fromSFM: 400), 121.92, accuracy: 1e-9)
    }
    func testCubicInchToCubicCm() {
        XCTAssertEqual(Convert.cm3(fromCubicInchPerMin: 2.88), 47.19474432, accuracy: 1e-6)
    }
    func testInchToMM() {
        XCTAssertEqual(Convert.mm(fromInch: 0.012), 0.3048, accuracy: 1e-9)
    }
    func testUnitSystemCases() {
        XCTAssertEqual(UnitSystem.allCases, [.imperial, .metric])
    }
    func testMMtoInch() { XCTAssertEqual(Convert.inch(fromMM: 38.1), 1.5, accuracy: 1e-9) }
    func testHPtoKW()   { XCTAssertEqual(Convert.kW(fromHP: 2.88), 2.147616, accuracy: 1e-9) }
}
