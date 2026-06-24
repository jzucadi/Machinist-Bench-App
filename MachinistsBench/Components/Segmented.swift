import SwiftUI

struct Segmented<T: Hashable>: View {
    @Binding var selection: T
    let options: [(T, String)]
    let accent: Accent

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.0) { value, label in
                let on = value == selection
                Button { selection = value } label: {
                    Text(label)
                        .font(AppFont.display(13))
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(on ? accent.color : Catppuccin.subtext0)
                        .background(on ? accent.color.opacity(0.15) : .clear,
                                    in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(on ? accent.color : Catppuccin.surface1, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
