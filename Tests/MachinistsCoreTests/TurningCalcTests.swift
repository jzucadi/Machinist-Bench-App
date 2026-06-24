import XCTest
@testable import MachinistsCore

final class TurningCalcTests: XCTestCase {
    func testCoatFactor() {
        XCTAssertEqual(coatFactor(tool: .carbide, coating: .none), 1.0, accuracy: 1e-9)
        XCTAssertEqual(coatFactor(tool: .carbide, coating: .tialn), 1.5, accuracy: 1e-9)
        XCTAssertEqual(coatFactor(tool: .hss, coating: .tialn), 1.2, accuracy: 1e-9) // 1+(1.5-1)*0.4
    }

    func testLubeFactor() {
        XCTAssertEqual(lubeFactor(materialID: "lowc", lube: .oil), 0.85, accuracy: 1e-9)
        XCTAssertEqual(lubeFactor(materialID: "lowc", lube: .dry), 0.70, accuracy: 1e-9)
        XCTAssertEqual(lubeFactor(materialID: "castiron", lube: .dry), 1.0, accuracy: 1e-9)
        XCTAssertEqual(lubeFactor(materialID: "ductile", lube: .oil), 1.0, accuracy: 1e-9)
    }

    func testTurningSquareEdge() {
        let r = turning(diameterIn: 1.5, docIn: 0.05, sfm: 400, feedIPR: 0.012,
                        efficiency: 0.8, leadDeg: 90, kp: 1.0)!
        XCTAssertEqual(r.rpm, 1018.5916357881301, accuracy: 1e-4)
        XCTAssertEqual(r.ipm, 12.223099629457561, accuracy: 1e-4)
        XCTAssertEqual(r.mrr, 2.88, accuracy: 1e-9)
        XCTAssertEqual(r.cutHP, 2.88, accuracy: 1e-9)
        XCTAssertEqual(r.motorHP, 3.6, accuracy: 1e-9)
        XCTAssertEqual(r.laf, 1.0, accuracy: 1e-9)
    }

    func testTurningLeadAngleThinsChip() {
        let r = turning(diameterIn: 1.5, docIn: 0.05, sfm: 400, feedIPR: 0.012,
                        efficiency: 0.8, leadDeg: 45, kp: 1.0)!
        XCTAssertEqual(r.laf, 1.4142135623730951, accuracy: 1e-9)
        XCTAssertEqual(r.fProg, 0.016970562748477142, accuracy: 1e-9)
        XCTAssertEqual(r.mrr, 4.072935059634514, accuracy: 1e-6)
    }

    func testTurningGuardRejectsBadInput() {
        XCTAssertNil(turning(diameterIn: 0, docIn: 0.05, sfm: 400, feedIPR: 0.012,
                             efficiency: 0.8, leadDeg: 90, kp: 1.0))
    }

    func testRecommendedSFM() {
        let lowc = Materials.byID("lowc")!
        // carbide/none/oil → 350...550 × 0.85 → round(297.5)=298 ... round(467.5)=468
        XCTAssertEqual(recommendedSFM(material: lowc, tool: .carbide, coating: .none, lube: .oil), 298...468)
    }
}
