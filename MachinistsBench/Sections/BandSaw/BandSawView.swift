import SwiftUI

struct BandSawView: View {
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.imperial.rawValue
    private var system: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .imperial }

    // MARK: – Tab selection
    @State private var tab = "speed"

    // MARK: – Speed tab state
    @State private var speedMaterialKey = "mild"
    @State private var blade = "bi"
    @State private var speedSection = 1.0

    // MARK: – Select tab state
    @State private var materialClass = "steel"
    @State private var shape = "solid"
    @State private var selectSection = 1.0
    @State private var tpiOverride = 0.0   // 0 = use recommendation

    // MARK: – Computed: Speed tab
    private var speedMaterial: SawMaterial {
        SawData.materials.first(where: { $0.key == speedMaterialKey }) ?? SawData.materials[0]
    }
    private var fpm: Int {
        bladeSpeedFPM(material: speedMaterial, blade: blade, sectionIn: speedSection)
    }

    // MARK: – Computed: Select tab
    private var selectSizeIn: Double {
        // For tube, use wall; for solid/rect use section directly
        // (shape drives the hint only — sizeIn is always the relevant cutting dimension)
        selectSection
    }
    private var pitch: (label: String, avg: Double, teeth: Double, minTPI: Double, maxTPI: Double, tone: String) {
        let userTPI: Double? = tpiOverride > 0 ? tpiOverride : nil
        return sawPitch(sizeIn: selectSizeIn, materialClass: materialClass, userTPI: userTPI)
    }
    private var teethTone: NoteTone {
        switch pitch.tone {
        case "good": return .good
        case "warn": return .warn
        case "bad":  return .bad
        default:     return .info
        }
    }

    // MARK: – Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Top-level tab switcher
                Field(label: "View") {
                    Segmented(
                        selection: $tab,
                        options: [("speed", "Speed"), ("select", "Blade Select")],
                        accent: .mauve
                    )
                }

                if tab == "speed" {
                    speedContent
                } else {
                    selectContent
                }
            }
            .padding(16)
        }
        .background(Catppuccin.base)
        .unitToolbar()
    }

    // MARK: – Speed Tab

    @ViewBuilder private var speedContent: some View {
        Panel(title: "Blade Speed", accent: .mauve,
              subtitle: "Surface speed in FPM or m·min⁻¹") {
            Field(label: "Material") {
                Picker("", selection: $speedMaterialKey) {
                    ForEach(SawData.materials, id: \.key) { mat in
                        Text(mat.name).tag(mat.key)
                    }
                }
                .pickerStyle(.menu)
                .tint(Catppuccin.mauve)
            }
            Field(label: "Blade Type") {
                Segmented(
                    selection: $blade,
                    options: [("bi", "Bi-metal"), ("carbon", "Carbon"), ("carbide", "Carbide")],
                    accent: .mauve
                )
            }
            Field(label: "Section Size",
                  hint: system == .metric ? "mm" : "in") {
                NumberInput(
                    value: metricLengthBinding($speedSection, system: system),
                    step: system == .metric ? 1.0 : 0.125,
                    accent: .mauve
                )
            }
        }

        Panel(title: "Results", accent: .mauve) {
            if system == .imperial {
                Readout(
                    label: "Blade Speed",
                    value: "\(fpm)",
                    unit: "FPM",
                    sub: String(format: "%.0f m/min", Double(fpm) * 0.3048),
                    accent: .mauve,
                    big: true
                )
            } else {
                Readout(
                    label: "Blade Speed",
                    value: String(format: "%.0f", Double(fpm) * 0.3048),
                    unit: "m/min",
                    sub: "\(fpm) FPM",
                    accent: .mauve,
                    big: true
                )
            }
        }

        NoteView(tone: .info, text: speedMaterial.note)
    }

    // MARK: – Blade Select Tab

    @ViewBuilder private var selectContent: some View {
        Panel(title: "Blade Select", accent: .mauve,
              subtitle: "Pitch recommendation by section & material") {
            Field(label: "Material Class") {
                Picker("", selection: $materialClass) {
                    Text("Steel / Ferrous").tag("steel")
                    Text("Non-ferrous").tag("nonfer")
                    Text("Plastic").tag("plastic")
                    Text("Wood").tag("wood")
                }
                .pickerStyle(.menu)
                .tint(Catppuccin.mauve)
            }
            Field(label: "Shape") {
                Segmented(
                    selection: $shape,
                    options: [("solid", "Solid"), ("rect", "Rect / Flat"), ("tube", "Tube")],
                    accent: .mauve
                )
            }
            Field(label: shape == "tube" ? "Wall Thickness" : "Section Size",
                  hint: system == .metric ? "mm" : "in") {
                NumberInput(
                    value: metricLengthBinding($selectSection, system: system),
                    step: system == .metric ? 1.0 : 0.125,
                    accent: .mauve
                )
            }
            Field(label: "TPI Override",
                  hint: "0 = use recommendation") {
                NumberInput(value: $tpiOverride, step: 1, accent: .mauve)
            }
        }

        Panel(title: "Results", accent: .mauve) {
            Readout(
                label: "Recommended Pitch",
                value: pitch.label,
                unit: "TPI",
                accent: .mauve,
                big: true
            )
            Readout(
                label: "Coarsest Usable TPI",
                value: String(format: "%.1f", pitch.minTPI),
                unit: "TPI",
                accent: .mauve
            )
            Readout(
                label: "Finest Usable TPI",
                value: String(format: "%.1f", pitch.maxTPI),
                unit: "TPI",
                accent: .mauve
            )
        }

        NoteView(
            tone: teethTone,
            text: String(format: "Teeth in cut: %.1f — %@",
                         pitch.teeth,
                         teethInCutNote(teeth: pitch.teeth))
        )
    }

    // MARK: – Helpers

    private func teethInCutNote(teeth: Double) -> String {
        if teeth < 3 {
            return "Too few teeth; risk of tooth stripping and rough cut. Use a finer pitch or reduce section size interpretation."
        } else if teeth > 24 {
            return "Too many teeth; gullets will pack with chips. Use a coarser pitch."
        } else {
            return "Teeth in cut is within the ideal 3–24 range for clean, efficient cutting."
        }
    }
}

#Preview {
    NavigationStack { BandSawView() }
}
