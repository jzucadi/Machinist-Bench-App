import SwiftUI

struct DrillingView: View {
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.imperial.rawValue
    private var system: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .imperial }

    @State private var materialID = "lowc"
    @State private var tool: Tool = .hss
    @State private var coating: Coating = .none
    @State private var lube: Lube = .flood
    @State private var diameter = 0.25   // imperial base: inches
    @State private var sfm = 0.0         // seeded on appear
    @State private var feed = 0.005      // seeded on appear (material.drillFeed)
    @State private var eff = 0.80
    @State private var didSeed = false

    private var material: Material { Materials.byID(materialID) ?? Materials.all[0] }
    private var recRange: ClosedRange<Int> {
        recommendedDrillSFM(material: material, tool: tool, coating: coating, lube: lube)
    }
    private var result: DrillingResult? {
        drilling(diameterIn: diameter, sfm: sfm, feedIPR: feed,
                 efficiency: eff, kp: material.kp)
    }
    private var inRange: Bool {
        Int(sfm) >= recRange.lowerBound && Int(sfm) <= recRange.upperBound
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Panel(title: "Drilling", accent: .teal,
                      subtitle: "RPM · feed · metal-removal · spindle power") {
                    inputs
                }
                if let r = result {
                    Panel(title: "Results", accent: .teal) { readouts(r) }
                    NoteView(tone: inRange ? .good : .warn, text: rangeNote)
                }
            }
            .padding(16)
        }
        .background(Catppuccin.base)
        .unitToolbar()
        .onAppear { seedSFM() }
        .onChange(of: materialID) { reseed(); feed = material.drillFeed }
        .onChange(of: tool)     { reseed() }
        .onChange(of: coating)  { reseed() }
        .onChange(of: lube)     { reseed() }
    }

    @ViewBuilder private var inputs: some View {
        Field(label: "Material", hint: material.hardness) {
            Picker("", selection: $materialID) {
                ForEach(Materials.all) { Text($0.name).tag($0.id) }
            }.pickerStyle(.menu).tint(Catppuccin.teal)
        }
        Field(label: "Tool") {
            Segmented(selection: $tool, options: [(.hss, "HSS"), (.carbide, "Carbide")], accent: .teal)
        }
        Field(label: "Coating", hint: String(format: "×%.2f SFM", coatFactor(tool: tool, coating: coating))) {
            Picker("", selection: $coating) {
                Text("None").tag(Coating.none); Text("TiN").tag(Coating.tin)
                Text("TiCN").tag(Coating.ticn); Text("TiAlN").tag(Coating.tialn)
                Text("AlCrN").tag(Coating.alcrn)
            }.pickerStyle(.menu).tint(Catppuccin.teal)
        }
        Field(label: "Drill Ø", hint: system == .metric ? "mm" : "in") {
            NumberInput(value: metricLengthBinding($diameter, system: system),
                        step: system == .metric ? 0.5 : 0.0625, accent: .teal)
        }
        Field(label: "Surface Speed", hint: system == .metric
              ? "rec \(Int(Convert.mPerMin(fromSFM: Double(recRange.lowerBound)).rounded()))–\(Int(Convert.mPerMin(fromSFM: Double(recRange.upperBound)).rounded())) m/min"
              : "rec \(recRange.lowerBound)–\(recRange.upperBound) SFM") {
            SpeedInput(sfm: $sfm, system: system, accent: .teal)
        }
        Field(label: "Feed", hint: system == .metric ? "mm/rev" : "in/rev") {
            NumberInput(value: metricLengthBinding($feed, system: system),
                        step: system == .metric ? 0.01 : 0.001, accent: .teal)
        }
        Field(label: "Spindle Efficiency", hint: "0–1") {
            NumberInput(value: $eff, step: 0.05, accent: .teal)
        }
        Field(label: "Cutting Fluid") {
            Segmented(selection: $lube, options: [(.flood, "Flood"), (.oil, "Brushed oil"), (.dry, "Dry")], accent: .teal)
        }
    }

    @ViewBuilder private func readouts(_ r: DrillingResult) -> some View {
        Readout(label: "Spindle Speed", value: "\(Int(r.rpm.rounded()))", unit: "RPM",
                sub: "\(Int(sfm.rounded())) SFM · \(Int(Convert.mPerMin(fromSFM: sfm).rounded())) m/min",
                accent: .teal, big: true)
        Readout(label: "Feed Rate",
                value: system == .metric ? "\(Int((r.ipm * 25.4).rounded()))" : String(format: "%.2f", r.ipm),
                unit: system == .metric ? "mm/min" : "IPM", accent: .teal, big: true)
        Readout(label: "Metal Removal",
                value: system == .metric ? String(format: "%.1f", Convert.cm3(fromCubicInchPerMin: r.mrr)) : String(format: "%.3f", r.mrr),
                unit: system == .metric ? "cm³/min" : "in³/min", accent: .green, big: true)
        Readout(label: "Cutting Power",
                value: system == .metric ? String(format: "%.2f", Convert.kW(fromHP: r.cutHP)) : String(format: "%.2f", r.cutHP),
                unit: system == .metric ? "kW" : "hp",
                sub: "Kp=\(material.kp)", accent: .peach)
        Readout(label: "Motor Power (est)",
                value: system == .metric ? String(format: "%.2f", Convert.kW(fromHP: r.motorHP)) : String(format: "%.2f", r.motorHP),
                unit: system == .metric ? "kW" : "hp",
                sub: "η=\(String(format: "%.2f", eff))", accent: .peach)
    }

    private var rangeNote: String {
        if inRange {
            return "✔ Surface speed is within the recommended range for this material, tool, and fluid."
        }
        let dir = Int(sfm) < recRange.lowerBound ? "Below" : "Above"
        let why = Int(sfm) < recRange.lowerBound
            ? "risk of built-up edge and poor finish." : "expect accelerated tool wear."
        if system == .metric {
            let lo = Int(Convert.mPerMin(fromSFM: Double(recRange.lowerBound)).rounded())
            let hi = Int(Convert.mPerMin(fromSFM: Double(recRange.upperBound)).rounded())
            return "⚠ \(dir) the recommended \(lo)–\(hi) m/min — \(why)"
        }
        return "⚠ \(dir) the recommended \(recRange.lowerBound)–\(recRange.upperBound) SFM — \(why)"
    }

    private func seedSFM() {
        guard !didSeed else { return }
        didSeed = true
        reseed()
        feed = material.drillFeed
    }
    private func reseed() {
        sfm = Double((recRange.lowerBound + recRange.upperBound) / 2)
    }
}

#Preview {
    NavigationStack { DrillingView() }
}
