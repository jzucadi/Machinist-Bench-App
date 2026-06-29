import SwiftUI

struct ReamingView: View {
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.imperial.rawValue
    private var system: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .imperial }

    @State private var materialID = "lowc"
    @State private var tool: Tool = .hss
    @State private var diameter = 0.25   // imperial base: inches
    @State private var sfm = 0.0         // seeded on appear
    @State private var feed = 0.0        // seeded on appear (material.reamFeed)
    @State private var didSeed = false

    private var material: Material { Materials.byID(materialID) ?? Materials.all[0] }
    private var sfmRange: ClosedRange<Int> {
        tool == .carbide ? material.reamCarbideSFM : material.reamSFM
    }
    private var result: ReamingResult? {
        reaming(diameterIn: diameter, sfm: sfm, feedIPR: feed)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Panel(title: "Reaming", accent: .teal,
                      subtitle: "RPM · feed · pre-drill · tolerance") {
                    inputs
                }
                if let r = result {
                    Panel(title: "Results", accent: .teal) { readouts(r) }
                }
            }
            .padding(16)
        }
        .background(Catppuccin.base)
        .unitToolbar()
        .onAppear { seedValues() }
        .onChange(of: materialID) { reseedSFM(); feed = material.reamFeed }
        .onChange(of: tool)       { reseedSFM() }
    }

    @ViewBuilder private var inputs: some View {
        Field(label: "Reamer Ø", hint: system == .metric ? "mm" : "in") {
            NumberInput(value: metricLengthBinding($diameter, system: system),
                        step: system == .metric ? 0.5 : 0.0625, accent: .teal)
        }
        Field(label: "Material", hint: material.hardness) {
            Picker("", selection: $materialID) {
                ForEach(Materials.all) { Text($0.name).tag($0.id) }
            }.pickerStyle(.menu).tint(Catppuccin.teal)
        }
        Field(label: "Tool") {
            Segmented(selection: $tool,
                      options: [(.hss, "HSS"), (.carbide, "Carbide")],
                      accent: .teal)
        }
        Field(label: "Surface Speed", hint: system == .metric ? "m/min" : "SFM") {
            SpeedInput(sfm: $sfm, system: system, accent: .teal)
        }
        Field(label: "Feed", hint: system == .metric ? "mm/rev" : "in/rev") {
            NumberInput(value: metricLengthBinding($feed, system: system),
                        step: system == .metric ? 0.01 : 0.001, accent: .teal)
        }
    }

    @ViewBuilder private func readouts(_ r: ReamingResult) -> some View {
        Readout(label: "Spindle Speed", value: "\(Int(r.rpm.rounded()))", unit: "RPM",
                sub: "\(Int(sfm.rounded())) SFM · \(Int(Convert.mPerMin(fromSFM: sfm).rounded())) m/min",
                accent: .teal, big: true)
        Readout(label: "Feed Rate",
                value: system == .metric ? "\(Int((r.ipm * 25.4).rounded()))" : String(format: "%.2f", r.ipm),
                unit: system == .metric ? "mm/min" : "IPM",
                accent: .teal, big: true)
        Readout(label: "Pre-Drill Size",
                value: Drills.nearestInch(r.preDrill).name,
                unit: system == .metric
                    ? String(format: "%.3f mm", r.preDrill * 25.4)
                    : String(format: "%.4f in", r.preDrill),
                accent: .teal)
        Readout(label: "Stock to Leave",
                value: system == .metric ? String(format: "%.3f", r.stock * 25.4) : String(format: "%.4f", r.stock),
                unit: system == .metric ? "mm" : "in",
                accent: .teal)
        Readout(label: "Hole Low Limit",
                value: system == .metric ? String(format: "%.4f", r.lowLimit * 25.4) : String(format: "%.4f", r.lowLimit),
                unit: system == .metric ? "mm" : "in",
                accent: .green)
        Readout(label: "Hole High Limit",
                value: system == .metric ? String(format: "%.4f", r.highLimit * 25.4) : String(format: "%.4f", r.highLimit),
                unit: system == .metric ? "mm" : "in",
                accent: .green)
    }

    private func seedValues() {
        guard !didSeed else { return }
        didSeed = true
        reseedSFM()
        feed = material.reamFeed
    }

    private func reseedSFM() {
        sfm = Double((sfmRange.lowerBound + sfmRange.upperBound) / 2)
    }
}

#Preview {
    NavigationStack { ReamingView() }
}
