import SwiftUI

struct Field<Content: View>: View {
    let label: String
    var hint: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(AppFont.mono(11)).foregroundStyle(Catppuccin.subtext0)
                Spacer()
                if let hint {
                    Text(hint).font(AppFont.mono(10)).foregroundStyle(Catppuccin.overlay0)
                }
            }
            content
        }
    }
}
