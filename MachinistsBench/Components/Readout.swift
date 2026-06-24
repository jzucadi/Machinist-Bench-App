import SwiftUI

struct Readout: View {
    let label: String
    let value: String
    let unit: String
    var sub: String? = nil
    let accent: Accent
    var big: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased()).font(AppFont.mono(10)).foregroundStyle(Catppuccin.subtext0)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(AppFont.display(big ? 30 : 20)).foregroundStyle(accent.color)
                Text(unit).font(AppFont.mono(12)).foregroundStyle(Catppuccin.subtext0)
            }
            if let sub {
                Text(sub).font(AppFont.mono(10)).foregroundStyle(Catppuccin.overlay0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Catppuccin.surface0, in: RoundedRectangle(cornerRadius: 10))
    }
}
