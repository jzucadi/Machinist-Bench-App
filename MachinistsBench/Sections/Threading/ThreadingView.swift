import SwiftUI

struct ThreadingView: View {
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.imperial.rawValue
    private var system: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .imperial }

    // Standard selection: "unc" | "unf" | "metric"
    @State private var std = "unc"
    @State private var uncIndex    = 8   // default 1/4-20 UNC
    @State private var unfIndex    = 9   // default 1/4-28 UNF
    @State private var metricIndex = 6   // default M6 × 1.0

    @State private var materialID = "lowc"
    @State private var tool: Tool = .carbide
    @State private var dia: Double = 0.5     // workpiece OD, imperial base (inches)
    @State private var passes: Double = 6    // stored as Double for NumberInput binding
    @State private var sfm: Double = 0.0    // seeded on appear
    @State private var didSeed = false

    // MARK: - Derived

    private var material: Material { Materials.byID(materialID) ?? Materials.all[0] }

    /// Major diameter in inches (imperial base)
    private var majorIn: Double {
        switch std {
        case "metric": return Threads.metric[metricIndex].major / 25.4
        case "unf":    return Threads.unf[unfIndex].major
        default:       return Threads.unc[uncIndex].major
        }
    }

    /// Pitch in inches (imperial base)
    private var pitchIn: Double {
        switch std {
        case "metric": return Threads.metric[metricIndex].pitch / 25.4
        case "unf":    return 1.0 / Threads.unf[unfIndex].tpi
        default:       return 1.0 / Threads.unc[uncIndex].tpi
        }
    }

    private var rpm: Double? { threadingRPM(sfm: sfm, workpieceODIn: dia) }

    private var geometry: ThreadGeometry { threadGeometry(majorIn: majorIn, pitchIn: pitchIn) }

    private var passCount: Int { max(1, Int(passes.rounded())) }

    private var infeeds: [Double] { threadingInfeeds(heightExt: geometry.heightExt, passes: passCount) }

    private var infeedRows: [[String]] {
        var cumulative = 0.0
        return infeeds.enumerated().map { i, infeed in
            cumulative += infeed
            let infeedStr = formatLength(infeed)
            let cumStr    = formatLength(cumulative)
            return ["\(i + 1)", infeedStr, cumStr]
        }
    }

    private var recSFM: Int { recommendedThreadSFM(material: material, tool: tool) }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Panel(title: "Threading — Lathe", accent: .green,
                      subtitle: "single-point thread cutting · infeed schedule") {
                    inputs
                }
                if let r = rpm {
                    Panel(title: "Results", accent: .green) { readouts(rpm: r) }
                    Panel(title: "Infeed Schedule", accent: .green,
                          subtitle: "constant-area · 29.5° compound") {
                        DataTable(
                            columns: ["Pass", "Infeed", "Cum. Depth"],
                            rows: infeedRows,
                            accent: .green
                        )
                    }
                }
            }
            .padding(16)
        }
        .background(Catppuccin.base)
        .unitToolbar()
        .onAppear { seedSFM() }
        .onChange(of: materialID) { reseed() }
        .onChange(of: tool) { reseed() }
        .onChange(of: std) { reseed() }
    }

    // MARK: - Inputs

    @ViewBuilder private var inputs: some View {
        Field(label: "Standard") {
            Segmented(selection: $std,
                      options: [("unc", "UNC"), ("unf", "UNF"), ("metric", "Metric")],
                      accent: .green)
        }

        Field(label: "Thread") {
            threadPicker
        }

        Field(label: "Material", hint: material.hardness) {
            Picker("", selection: $materialID) {
                ForEach(Materials.all) { Text($0.name).tag($0.id) }
            }.pickerStyle(.menu).tint(Catppuccin.green)
        }

        Field(label: "Tool") {
            Segmented(selection: $tool,
                      options: [(.hss, "HSS"), (.carbide, "Carbide")],
                      accent: .green)
        }

        Field(label: "Workpiece Ø", hint: system == .metric ? "mm" : "in") {
            NumberInput(
                value: metricLengthBinding($dia, system: system),
                step: system == .metric ? 1 : 0.0625,
                accent: .green
            )
        }

        Field(label: "Passes", hint: "number of spring passes") {
            NumberInput(value: $passes, step: 1, accent: .green)
        }

        Field(label: "Surface Speed",
              hint: system == .metric
                ? "rec \(Int(Convert.mPerMin(fromSFM: Double(recSFM)).rounded())) m/min"
                : "rec \(recSFM) SFM") {
            SpeedInput(sfm: $sfm, system: system, accent: .green)
        }
    }

    @ViewBuilder private var threadPicker: some View {
        switch std {
        case "unf":
            Picker("", selection: $unfIndex) {
                ForEach(Threads.unf.indices, id: \.self) { i in
                    Text(Threads.unf[i].name).tag(i)
                }
            }.pickerStyle(.menu).tint(Catppuccin.green)
        case "metric":
            Picker("", selection: $metricIndex) {
                ForEach(Threads.metric.indices, id: \.self) { i in
                    Text(Threads.metric[i].name).tag(i)
                }
            }.pickerStyle(.menu).tint(Catppuccin.green)
        default:
            Picker("", selection: $uncIndex) {
                ForEach(Threads.unc.indices, id: \.self) { i in
                    Text(Threads.unc[i].name).tag(i)
                }
            }.pickerStyle(.menu).tint(Catppuccin.green)
        }
    }

    // MARK: - Readouts

    @ViewBuilder private func readouts(rpm: Double) -> some View {
        let g = geometry

        // Spindle Speed
        Readout(label: "Spindle Speed",
                value: "\(Int(rpm.rounded()))",
                unit: "RPM",
                sub: "\(Int(sfm.rounded())) SFM · \(Int(Convert.mPerMin(fromSFM: sfm).rounded())) m/min",
                accent: .green, big: true)

        // Lead / Feed = 1 pitch per rev
        Readout(label: "Lead / Feed",
                value: system == .metric
                    ? String(format: "%.3f", pitchIn * 25.4)
                    : String(format: "%.4f", pitchIn),
                unit: system == .metric ? "mm/rev" : "in/rev",
                sub: "1 pitch per revolution",
                accent: .teal)

        // Thread Height
        Readout(label: "Thread Height",
                value: formatLength(g.heightExt),
                unit: system == .metric ? "mm" : "in",
                sub: "60° unified standard",
                accent: .green)

        // Compound @29.5°
        Readout(label: "Compound @29.5°",
                value: formatLength(g.compound),
                unit: system == .metric ? "mm" : "in",
                sub: "total compound travel",
                accent: .green)

        // Pitch Ø
        Readout(label: "Pitch Ø",
                value: formatLength(g.pitchDia),
                unit: system == .metric ? "mm" : "in",
                accent: .teal)

        // Minor Ø
        Readout(label: "Minor Ø",
                value: formatLength(g.minorExt),
                unit: system == .metric ? "mm" : "in",
                accent: .teal)

        // Major Ø
        Readout(label: "Major Ø",
                value: formatLength(majorIn),
                unit: system == .metric ? "mm" : "in",
                accent: .teal)
    }

    // MARK: - Helpers

    /// Format a length value (stored as inches) for display per unit system.
    private func formatLength(_ valueIn: Double) -> String {
        if system == .metric {
            return String(format: "%.3f", valueIn * 25.4)
        } else {
            return String(format: "%.4f", valueIn)
        }
    }

    // MARK: - SFM Seeding

    private func seedSFM() {
        guard !didSeed else { return }
        didSeed = true
        reseed()
    }

    private func reseed() {
        sfm = Double(recSFM)
    }
}

#Preview {
    NavigationStack { ThreadingView() }
}
