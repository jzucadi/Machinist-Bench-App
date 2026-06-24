import SwiftUI

enum NoteTone { case info, warn, bad, good }

struct NoteView: View {
    var tone: NoteTone = .info
    let text: String

    private var color: Color {
        switch tone {
        case .info: return Catppuccin.blue
        case .warn: return Catppuccin.peach
        case .bad:  return Catppuccin.red
        case .good: return Catppuccin.green
        }
    }

    var body: some View {
        Text(text)
            .font(AppFont.body(13))
            .foregroundStyle(Catppuccin.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(color.opacity(0.4)))
    }
}
