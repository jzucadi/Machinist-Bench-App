import SwiftUI

struct NumberInput: View {
    @Binding var value: Double
    let step: Double
    let accent: Accent

    var body: some View {
        HStack(spacing: 8) {
            TextField("", value: $value, format: .number)
                .keyboardType(.decimalPad)
                .font(AppFont.mono(16))
                .foregroundStyle(Catppuccin.text)
            Stepper("", value: $value, step: step).labelsHidden()
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Catppuccin.surface0, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(accent.color.opacity(0.2)))
    }
}
