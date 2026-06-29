import SwiftUI

struct TappingView: View {
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.imperial.rawValue
    private var system: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .imperial }

    // Standard selection: "unc" | "unf" | "metric"
    @State private var std = "unc"
    @State private var uncIndex    = 8   // default 1/4-20 UNC
    @State private var unfIndex    = 9   // default 1/4-28 UNF
    @State private var metricIndex = 6   // default M6 × 1.0

    @State private var materialID  = "lowc"
    @State private var coated      = false   // false = HSS, true = Coated
    @State private var pct: Double = 75
    @State private var sfm         = 0.0     // seeded on appear
    @State private var didSeed     = false

    // MARK: - Derived

    private var material: Material { Materials.byID(materialID) ?? Materials.all[0] }

    private var threadIndex: Int {
        switch std {
        case "unf":    return unfIndex
        case "metric": return metricIndex
        default:       return uncIndex
        }
    }

    /// Major diameter and pitch, always in inches (imperial base)
    private var majorIn: Double {
        switch std {
        case "metric":
            return Threads.metric[metricIndex].major / 25.4
        case "unf":
            return Threads.unf[unfIndex].major
        default:
            return Threads.unc[uncIndex].major
        }
    }

    private var pitchIn: Double {
        switch std {
        case "metric":
            return Threads.metric[metricIndex].pitch / 25.4
        case "unf":
            return 1.0 / Threads.unf[unfIndex].tpi
        default:
            return 1.0 / Threads.unc[uncIndex].tpi
        }
    }

    private var sfmRange: ClosedRange<Int> {
        coated ? material.tapCoatedSFM : material.tapSFM
    }

    private var tapResult: TapSpeed? {
        tapping(majorIn: majorIn, pitchIn: pitchIn, sfm: sfm)
    }

    private var tapDrill: Drill {
        let ideal = tapDrillIdeal(majorIn: majorIn, pitchIn: pitchIn, pct: pct)
        return Drills.nearestInch(ideal)
    }

    private var tapDrillMM: Double {
        Drills.nearestMetricMM(tapDrill.dia * 25.4)
    }

    private var actualPct: Double {
        tapActualPct(majorIn: majorIn, drillDia: tapDrill.dia, pitchIn: pitchIn)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Panel(title: "Tapping", accent: .mauve,
                      subtitle: "tap drill · RPM · synchronous feed") {
                    inputs
                }
                if let r = tapResult {
                    Panel(title: "Results", accent: .mauve) { readouts(r) }
                }
            }
            .padding(16)
        }
        .background(Catppuccin.base)
        .unitToolbar()
        .onAppear { seedSFM() }
        .onChange(of: materialID) { reseed() }
        .onChange(of: coated)     { reseed() }
        .onChange(of: std)        { reseed() }
    }

    // MARK: - Inputs

    @ViewBuilder private var inputs: some View {
        Field(label: "Standard") {
            Segmented(selection: $std,
                      options: [("unc", "UNC"), ("unf", "UNF"), ("metric", "Metric")],
                      accent: .mauve)
        }

        Field(label: "Thread") {
            threadPicker
        }

        Field(label: "Material", hint: material.hardness) {
            Picker("", selection: $materialID) {
                ForEach(Materials.all) { Text($0.name).tag($0.id) }
            }.pickerStyle(.menu).tint(Catppuccin.mauve)
        }

        Field(label: "Tool") {
            Segmented(selection: $coated,
                      options: [(false, "HSS"), (true, "Coated")],
                      accent: .mauve)
        }

        Field(label: "Thread %", hint: "recommended: 75") {
            NumberInput(value: $pct, step: 5, accent: .mauve)
        }

        Field(label: "Surface Speed",
              hint: system == .metric
                ? "rec \(Int(Convert.mPerMin(fromSFM: Double(sfmRange.lowerBound)).rounded()))–\(Int(Convert.mPerMin(fromSFM: Double(sfmRange.upperBound)).rounded())) m/min"
                : "rec \(sfmRange.lowerBound)–\(sfmRange.upperBound) SFM") {
            SpeedInput(sfm: $sfm, system: system, accent: .mauve)
        }
    }

    @ViewBuilder private var threadPicker: some View {
        switch std {
        case "unf":
            Picker("", selection: $unfIndex) {
                ForEach(Threads.unf.indices, id: \.self) { i in
                    Text(Threads.unf[i].name).tag(i)
                }
            }.pickerStyle(.menu).tint(Catppuccin.mauve)
        case "metric":
            Picker("", selection: $metricIndex) {
                ForEach(Threads.metric.indices, id: \.self) { i in
                    Text(Threads.metric[i].name).tag(i)
                }
            }.pickerStyle(.menu).tint(Catppuccin.mauve)
        default:
            Picker("", selection: $uncIndex) {
                ForEach(Threads.unc.indices, id: \.self) { i in
                    Text(Threads.unc[i].name).tag(i)
                }
            }.pickerStyle(.menu).tint(Catppuccin.mauve)
        }
    }

    // MARK: - Readouts

    @ViewBuilder private func readouts(_ r: TapSpeed) -> some View {
        // Tap Drill
        let drillSizeLabel = system == .metric
            ? String(format: "%.2f mm", tapDrillMM)
            : String(format: "%.4f\"", tapDrill.dia)

        Readout(label: "Recommended Tap Drill",
                value: tapDrill.name,
                unit: drillSizeLabel,
                sub: "ideal hole Ø",
                accent: .mauve, big: true)

        Readout(label: "Actual % Thread",
                value: String(format: "%.0f%%", actualPct),
                unit: "",
                accent: .mauve)

        Readout(label: "Spindle Speed",
                value: "\(Int(r.rpm.rounded()))",
                unit: "RPM",
                sub: "\(Int(sfm.rounded())) SFM · \(Int(Convert.mPerMin(fromSFM: sfm).rounded())) m/min",
                accent: .mauve, big: true)

        Readout(label: "Synchronous Feed",
                value: system == .metric
                    ? String(format: "%.2f", r.syncFeedIPM * 25.4)
                    : String(format: "%.4f", r.syncFeedIPM),
                unit: system == .metric ? "mm/min" : "IPM",
                sub: "= 1 pitch per rev",
                accent: .teal, big: true)
    }

    // MARK: - SFM seeding

    private func seedSFM() {
        guard !didSeed else { return }
        didSeed = true
        reseed()
    }

    private func reseed() {
        sfm = Double((sfmRange.lowerBound + sfmRange.upperBound) / 2)
    }
}

#Preview {
    NavigationStack { TappingView() }
}
