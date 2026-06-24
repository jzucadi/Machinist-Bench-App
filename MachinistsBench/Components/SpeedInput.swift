import SwiftUI

// Stores SFM; displays SFM (imperial) or m/min (metric). 1 SFM = 0.3048 m/min.
struct SpeedInput: View {
    @Binding var sfm: Double
    let system: UnitSystem
    let accent: Accent

    private var displayBinding: Binding<Double> {
        Binding(
            get: { system == .metric ? (sfm * 0.3048) : sfm },
            set: { newValue in sfm = system == .metric ? (newValue / 0.3048) : newValue }
        )
    }

    var body: some View {
        HStack(spacing: 8) {
            TextField("", value: displayBinding, format: .number.precision(.fractionLength(0)))
                .keyboardType(.numberPad)
                .font(AppFont.mono(16))
                .foregroundStyle(Catppuccin.text)
            Text(system == .metric ? "m/min" : "SFM")
                .font(AppFont.mono(11)).foregroundStyle(Catppuccin.subtext0)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Catppuccin.surface0, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(accent.color.opacity(0.2)))
    }
}
