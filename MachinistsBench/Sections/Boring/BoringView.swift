import SwiftUI

struct BoringView: View {
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.imperial.rawValue
    private var system: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .imperial }

    @State private var materialID = "lowc"
    @State private var tool: Tool = .carbide
    @State private var lube: Lube = .flood
    @State private var diameter = 1.0      // imperial base: inches
    @State private var operation: BoreOp = .rough
    @State private var doc = 0.025         // imperial base: inches
    @State private var sfm = 0.0          // seeded on appear
    @State private var feed = 0.004       // seeded on appear
    @State private var didSeed = false

    private var material: Material { Materials.byID(materialID) ?? Materials.all[0] }
    private var result: BoringResult? {
        boring(diameterIn: diameter, sfm: sfm, feedIPR: feed, docIn: doc)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Panel(title: "Boring — Bar", accent: .peach,
                      subtitle: "RPM · feed · metal-removal") {
                    inputs
                }
                if let r = result {
                    Panel(title: "Results", accent: .peach) { readouts(r) }
                }
            }
            .padding(16)
        }
        .background(Catppuccin.base)
        .unitToolbar()
        .onAppear { seedValues() }
        .onChange(of: materialID) { reseed() }
        .onChange(of: tool)       { reseed() }
        .onChange(of: lube)       { reseed() }
        .onChange(of: operation)  { reseed() }
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
        Field(label: "Bore Ø", hint: system == .metric ? "mm" : "in") {
            NumberInput(value: metricLengthBinding($diameter, system: system),
                        step: system == .metric ? 1 : 0.0625, accent: .peach)
        }
        Field(label: "Operation") {
            Segmented(selection: $operation,
                      options: [(.rough, "Rough"), (.finish, "Finish")],
                      accent: .peach)
        }
        Field(label: "Depth of Cut", hint: system == .metric ? "mm" : "in") {
            NumberInput(value: metricLengthBinding($doc, system: system),
                        step: system == .metric ? 0.1 : 0.005, accent: .peach)
        }
        Field(label: "Surface Speed", hint: system == .metric ? "m/min" : "SFM") {
            SpeedInput(sfm: $sfm, system: system, accent: .peach)
        }
        Field(label: "Feed", hint: system == .metric ? "mm/rev" : "in/rev") {
            NumberInput(value: metricLengthBinding($feed, system: system),
                        step: system == .metric ? 0.01 : 0.001, accent: .peach)
        }
        Field(label: "Cutting Fluid") {
            Segmented(selection: $lube,
                      options: [(.flood, "Flood"), (.oil, "Brushed oil"), (.dry, "Dry")],
                      accent: .peach)
        }
    }

    @ViewBuilder private func readouts(_ r: BoringResult) -> some View {
        Readout(label: "Spindle Speed", value: "\(Int(r.rpm.rounded()))", unit: "RPM",
                sub: "\(Int(sfm.rounded())) SFM · \(Int(Convert.mPerMin(fromSFM: sfm).rounded())) m/min",
                accent: .peach, big: true)
        Readout(label: "Feed Rate",
                value: system == .metric ? "\(Int((r.ipm * 25.4).rounded()))" : String(format: "%.2f", r.ipm),
                unit: system == .metric ? "mm/min" : "IPM",
                accent: .peach, big: true)
        Readout(label: "Metal Removal",
                value: system == .metric ? String(format: "%.1f", Convert.cm3(fromCubicInchPerMin: r.mrr)) : String(format: "%.3f", r.mrr),
                unit: system == .metric ? "cm³/min" : "in³/min",
                accent: .green, big: true)
    }

    private func seedValues() {
        guard !didSeed else { return }
        didSeed = true
        reseed()
    }

    private func reseed() {
        let s = boringSeed(material: material, tool: tool, lube: lube,
                           finish: operation == .finish)
        sfm = Double(s.sfm)
        feed = s.feedIPR
    }
}

enum BoreOp: String, CaseIterable {
    case rough, finish
}

#Preview {
    NavigationStack { BoringView() }
}
