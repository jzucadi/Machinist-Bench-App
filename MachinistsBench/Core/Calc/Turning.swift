import Foundation

public enum Tool: String, CaseIterable, Sendable { case hss, carbide }
public enum Coating: String, CaseIterable, Sendable { case none, tin, ticn, tialn, alcrn }
public enum Lube: String, CaseIterable, Sendable { case flood, oil, dry }

private let coatF: [Coating: Double] = [.none: 1, .tin: 1.2, .ticn: 1.3, .tialn: 1.5, .alcrn: 1.6]

public func coatFactor(tool: Tool, coating: Coating) -> Double {
    let cf = coatF[coating] ?? 1
    return tool == .hss ? 1 + (cf - 1) * 0.4 : cf
}

public func lubeFactor(materialID: String, lube: Lube) -> Double {
    if materialID == "castiron" || materialID == "ductile" { return 1 }
    switch lube {
    case .oil: return 0.85
    case .dry: return 0.70
    case .flood: return 1
    }
}

public struct TurningResult: Sendable {
    public let rpm, ipm, mrr, cutHP, motorHP, laf, fProg: Double
}

public func turning(diameterIn d: Double, docIn c: Double, sfm: Double, feedIPR: Double,
                    efficiency: Double, leadDeg: Double, kp: Double) -> TurningResult? {
    let eff = efficiency > 0 ? efficiency : 0.8
    let lead = leadDeg > 0 ? leadDeg : 90
    for v in [d, c, sfm, feedIPR] where v.isNaN || v <= 0 { return nil }
    let laf = (lead > 0 && lead < 90) ? 1 / sin(lead * .pi / 180) : 1
    let fProg = feedIPR * laf
    let rpm = sfm * 12 / (.pi * d)
    let ipm = rpm * fProg
    let mrr = 12 * sfm * fProg * c
    let cutHP = kp * mrr
    return TurningResult(rpm: rpm, ipm: ipm, mrr: mrr, cutHP: cutHP,
                         motorHP: cutHP / eff, laf: laf, fProg: fProg)
}

public func recommendedSFM(material: Material, tool: Tool, coating: Coating, lube: Lube) -> ClosedRange<Int> {
    let range = tool == .hss ? material.hssSFM : material.carbideSFM
    let lf = lubeFactor(materialID: material.id, lube: lube)
    let cf = coatFactor(tool: tool, coating: coating)
    let lo = Int((Double(range.lowerBound) * lf * cf).rounded())
    let hi = Int((Double(range.upperBound) * lf * cf).rounded())
    return lo...hi
}
