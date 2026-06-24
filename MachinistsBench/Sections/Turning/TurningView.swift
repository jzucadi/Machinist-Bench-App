import SwiftUI

struct TurningView: View {
    let system: UnitSystem

    @State private var materialID = "lowc"
    @State private var tool: Tool = .carbide
    @State private var coating: Coating = .none
    @State private var lube: Lube = .oil
    @State private var diameter = 1.5
    @State private var doc = 0.05
    @State private var sfm = 0.0 // seeded on appear via seedSFM()
    @State private var feed = 0.012
    @State private var lead = 90.0
    @State private var eff = 0.80
    @State private var didSeed = false

    private var material: Material { Materials.byID(materialID) ?? Materials.all[0] }
    private var recRange: ClosedRange<Int> {
        recommendedSFM(material: material, tool: tool, coating: coating, lube: lube)
    }
    private var result: TurningResult? {
        turning(diameterIn: diameter, docIn: doc, sfm: sfm, feedIPR: feed,
                efficiency: eff, leadDeg: lead, kp: material.kp)
    }
    private var inRange: Bool {
        Int(sfm) >= recRange.lowerBound && Int(sfm) <= recRange.upperBound
    }

    // mm for display (×25.4) when metric; stores the imperial base
    private func metricLengthBinding(_ base: Binding<Double>) -> Binding<Double> {
        Binding(get: { system == .metric ? Convert.mm(fromInch: base.wrappedValue) : base.wrappedValue },
                set: { base.wrappedValue = system == .metric ? Convert.inch(fromMM: $0) : $0 })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Panel(title: "Turning — Lathe", accent: .blue,
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
        .onAppear { seedSFM() }
        .onChange(of: materialID) { reseed(); feed = material.feedIPR }
        .onChange(of: tool) { reseed() }
        .onChange(of: coating) { reseed() }
        .onChange(of: lube) { reseed() }
    }

    @ViewBuilder private var inputs: some View {
        Field(label: "Material", hint: material.hardness) {
            Picker("", selection: $materialID) {
                ForEach(Materials.all) { Text($0.name).tag($0.id) }
            }.pickerStyle(.menu).tint(Catppuccin.blue)
        }
        Field(label: "Tool") {
            Segmented(selection: $tool, options: [(.hss, "HSS"), (.carbide, "Carbide")], accent: .blue)
        }
        Field(label: "Coating", hint: String(format: "×%.2f SFM", coatFactor(tool: tool, coating: coating))) {
            Picker("", selection: $coating) {
                Text("None").tag(Coating.none); Text("TiN").tag(Coating.tin)
                Text("TiCN").tag(Coating.ticn); Text("TiAlN").tag(Coating.tialn)
                Text("AlCrN").tag(Coating.alcrn)
            }.pickerStyle(.menu).tint(Catppuccin.blue)
        }
        Field(label: "Stock Ø", hint: system == .metric ? "mm" : "in") {
            NumberInput(value: metricLengthBinding($diameter), step: system == .metric ? 1 : 0.0625, accent: .blue)
        }
        Field(label: "Depth of Cut", hint: system == .metric ? "mm" : "in") {
            NumberInput(value: metricLengthBinding($doc), step: system == .metric ? 0.1 : 0.005, accent: .blue)
        }
        Field(label: "Surface Speed", hint: system == .metric
              ? "rec \(Int(Convert.mPerMin(fromSFM: Double(recRange.lowerBound)).rounded()))–\(Int(Convert.mPerMin(fromSFM: Double(recRange.upperBound)).rounded())) m/min"
              : "rec \(recRange.lowerBound)–\(recRange.upperBound) SFM") {
            SpeedInput(sfm: $sfm, system: system, accent: .blue)
        }
        Field(label: "Feed", hint: system == .metric ? "mm/rev" : "in/rev") {
            NumberInput(value: metricLengthBinding($feed), step: system == .metric ? 0.01 : 0.001, accent: .blue)
        }
        Field(label: "Lead Angle", hint: "90° = square edge") {
            NumberInput(value: $lead, step: 5, accent: .blue)
        }
        Field(label: "Spindle Efficiency", hint: "0–1") {
            NumberInput(value: $eff, step: 0.05, accent: .blue)
        }
        Field(label: "Cutting Fluid") {
            Segmented(selection: $lube, options: [(.flood, "Flood"), (.oil, "Brushed oil"), (.dry, "Dry")], accent: .blue)
        }
    }

    @ViewBuilder private func readouts(_ r: TurningResult) -> some View {
        Readout(label: "Spindle Speed", value: "\(Int(r.rpm.rounded()))", unit: "RPM",
                sub: "\(Int(sfm.rounded())) SFM · \(Int(Convert.mPerMin(fromSFM: sfm).rounded())) m/min",
                accent: .blue, big: true)
        Readout(label: "Feed Rate",
                value: system == .metric ? "\(Int((r.ipm * 25.4).rounded()))" : String(format: "%.2f", r.ipm),
                unit: system == .metric ? "mm/min" : "IPM", accent: .teal, big: true)
        Readout(label: "Metal Removal",
                value: system == .metric ? String(format: "%.1f", Convert.cm3(fromCubicInchPerMin: r.mrr)) : String(format: "%.2f", r.mrr),
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
        return "⚠ \(dir) the recommended \(recRange.lowerBound)–\(recRange.upperBound) SFM — \(why)"
    }

    private func seedSFM() {
        guard !didSeed else { return }
        didSeed = true
        reseed()
        feed = material.feedIPR
    }
    private func reseed() {
        sfm = Double((recRange.lowerBound + recRange.upperBound) / 2)
    }
}

#Preview {
    TurningView(system: .imperial)
}
