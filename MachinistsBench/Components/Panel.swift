import SwiftUI

struct Panel<Content: View>: View {
    let title: String
    let accent: Accent
    var subtitle: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(AppFont.display(18)).foregroundStyle(accent.color)
                if let subtitle {
                    Text(subtitle).font(AppFont.mono(11)).foregroundStyle(Catppuccin.subtext0)
                }
            }
            content
        }
        .padding(16)
        .background(Catppuccin.mantle, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(accent.color.opacity(0.25)))
    }
}
