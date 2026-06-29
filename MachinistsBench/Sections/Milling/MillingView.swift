import SwiftUI

struct MillingView: View {
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.imperial.rawValue
    private var system: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .imperial }

    @State private var materialID = "lowc"
    @State private var tool: Tool = .carbide
    @State private var coating: Coating = .none
    @State private var lube: Lube = .flood
    @State private var diameter = 0.5       // inches
    @State private var flutes = 4
    @State private var cornerR = 0.0        // inches
    @State private var sfm = 0.0            // seeded on appear
    @State private var chipLoad = 0.003     // inches (seeded from material)
    @State private var adoc = 0.5           // inches axial DOC
    @State private var rdoc = 0.125         // inches radial WOC
    @State private var lead = 90.0          // degrees
    @State private var eff = 0.80
    @State private var didSeed = false

    private var material: Material { Materials.byID(materialID) ?? Materials.all[0] }
    private var recRange: ClosedRange<Int> {
        recommendedMillSFM(material: material, tool: tool, coating: coating, lube: lube)
    }
    private var result: MillingResult? {
        milling(diameterIn: diameter, cornerRIn: cornerR, sfm: sfm,
                chipLoad: chipLoad, flutes: flutes,
                adocIn: adoc, rdocIn: rdoc,
                leadDeg: lead, efficiency: eff, kp: material.kp)
    }
    private var inRange: Bool {
        Int(sfm) >= recRange.lowerBound && Int(sfm) <= recRange.upperBound
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Panel(title: "Milling", accent: .peach,
                      subtitle: "RPM · feed · metal-removal · spindle power") {
                    inputs
                }
                if let r = result {
                    Panel(title: "Results", accent: .peach) { readouts(r) }
                    NoteView(tone: inRange ? .good : .warn, text: rangeNote)
                }
            }
            .padding(16)
        }
        .background(Catppuccin.base)
        .unitToolbar()
        .onAppear { seedSFM() }
        .onChange(of: materialID) { reseed(); chipLoad = material.chipLoad }
        .onChange(of: tool)       { reseed() }
        .onChange(of: coating)    { reseed() }
        .onChange(of: lube)       { reseed() }
    }

    @ViewBuilder private var inputs: some View {
        Field(label: "Material", hint: material.hardness) {
            Picker("", selection: $materialID) {
                ForEach(Materials.all) { Text($0.name).tag($0.id) }
            }.pickerStyle(.menu).tint(Catppuccin.peach)
        }
        Field(label: "Tool") {
            Segmented(selection: $tool,
                      options: [(.hss, "HSS"), (.carbide, "Carbide")],
                      accent: .peach)
        }
        Field(label: "Coating",
              hint: String(format: "×%.2f SFM", coatFactor(tool: tool, coating: coating))) {
            Picker("", selection: $coating) {
                Text("None").tag(Coating.none);   Text("TiN").tag(Coating.tin)
                Text("TiCN").tag(Coating.ticn);   Text("TiAlN").tag(Coating.tialn)
                Text("AlCrN").tag(Coating.alcrn)
            }.pickerStyle(.menu).tint(Catppuccin.peach)
        }
        Field(label: "Cutter Ø", hint: system == .metric ? "mm" : "in") {
            NumberInput(value: metricLengthBinding($diameter, system: system),
                        step: system == .metric ? 1 : 0.0625, accent: .peach)
        }
        Field(label: "Flutes") {
            Segmented(selection: $flutes,
                      options: [(2, "2"), (3, "3"), (4, "4"), (6, "6")],
                      accent: .peach)
        }
        Field(label: "Corner Radius", hint: system == .metric ? "mm" : "in") {
            NumberInput(value: metricLengthBinding($cornerR, system: system),
                        step: system == .metric ? 0.1 : 0.005, accent: .peach)
        }
        Field(label: "Surface Speed", hint: system == .metric
              ? "rec \(Int(Convert.mPerMin(fromSFM: Double(recRange.lowerBound)).rounded()))–\(Int(Convert.mPerMin(fromSFM: Double(recRange.upperBound)).rounded())) m/min"
              : "rec \(recRange.lowerBound)–\(recRange.upperBound) SFM") {
            SpeedInput(sfm: $sfm, system: system, accent: .peach)
        }
        Field(label: "Chip Load", hint: system == .metric ? "mm/tooth" : "in/tooth") {
            NumberInput(value: metricLengthBinding($chipLoad, system: system),
                        step: system == .metric ? 0.01 : 0.0005, accent: .peach)
        }
        Field(label: "Axial DOC", hint: system == .metric ? "mm" : "in") {
            NumberInput(value: metricLengthBinding($adoc, system: system),
                        step: system == .metric ? 0.1 : 0.005, accent: .peach)
        }
        Field(label: "Radial WOC", hint: system == .metric ? "mm" : "in") {
            NumberInput(value: metricLengthBinding($rdoc, system: system),
                        step: system == .metric ? 0.5 : 0.0625, accent: .peach)
        }
        Field(label: "Lead Angle", hint: "90° = square edge") {
            NumberInput(value: $lead, step: 5, accent: .peach)
        }
        Field(label: "Spindle Efficiency", hint: "0–1") {
            NumberInput(value: $eff, step: 0.05, accent: .peach)
        }
        Field(label: "Cutting Fluid") {
            Segmented(selection: $lube,
                      options: [(.flood, "Flood"), (.oil, "Brushed oil"), (.dry, "Dry")],
                      accent: .peach)
        }
    }

    @ViewBuilder private func readouts(_ r: MillingResult) -> some View {
        Readout(label: "Spindle Speed", value: "\(Int(r.rpm.rounded()))", unit: "RPM",
                sub: "\(Int(sfm.rounded())) SFM · \(Int(Convert.mPerMin(fromSFM: sfm).rounded())) m/min",
                accent: .peach, big: true)
        Readout(label: "Table Feed",
                value: system == .metric ? "\(Int((r.ipm * 25.4).rounded()))" : String(format: "%.2f", r.ipm),
                unit: system == .metric ? "mm/min" : "IPM",
                sub: "prog fz \(system == .metric ? String(format: "%.4f", r.fzProg * 25.4) + " mm" : String(format: "%.5f", r.fzProg) + " in")",
                accent: .peach, big: true)
        Readout(label: "Metal Removal",
                value: system == .metric ? String(format: "%.1f", Convert.cm3(fromCubicInchPerMin: r.mrr)) : String(format: "%.3f", r.mrr),
                unit: system == .metric ? "cm³/min" : "in³/min", accent: .green, big: true)
        Readout(label: "Spindle Power",
                value: system == .metric ? String(format: "%.2f", Convert.kW(fromHP: r.motorHP)) : String(format: "%.2f", r.motorHP),
                unit: system == .metric ? "kW" : "hp",
                sub: "Kp=\(material.kp) · η=\(String(format: "%.2f", eff))", accent: .peach)
        if cornerR > 0 {
            Readout(label: "Effective Ø",
                    value: system == .metric ? String(format: "%.3f", r.deff * 25.4) : String(format: "%.4f", r.deff),
                    unit: system == .metric ? "mm" : "in",
                    sub: "bull-nose compensation", accent: .peach)
        }
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
        chipLoad = material.chipLoad
    }
    private func reseed() {
        sfm = Double((recRange.lowerBound + recRange.upperBound) / 2)
    }
}

#Preview {
    NavigationStack { MillingView() }
}
