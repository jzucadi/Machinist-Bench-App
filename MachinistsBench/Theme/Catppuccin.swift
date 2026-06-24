import SwiftUI

enum Catppuccin {
    static func hex(_ v: UInt32) -> Color {
        Color(red: Double((v >> 16) & 0xFF) / 255,
              green: Double((v >> 8) & 0xFF) / 255,
              blue: Double(v & 0xFF) / 255)
    }
    // Mocha
    static let base     = hex(0x1e1e2e)
    static let mantle   = hex(0x181825)
    static let surface0 = hex(0x313244)
    static let surface1 = hex(0x45475a)
    static let text     = hex(0xcdd6f4)
    static let subtext0 = hex(0xa6adc8)
    static let overlay0 = hex(0x6c7086)
    static let blue     = hex(0x89b4fa)
    static let teal     = hex(0x94e2d5)
    static let green    = hex(0xa6e3a1)
    static let peach    = hex(0xfab387)
    static let mauve    = hex(0xcba6f7)
    static let red      = hex(0xf38ba8)
}

enum Accent: String, CaseIterable {
    case blue, teal, peach, mauve, green, red
    var color: Color {
        switch self {
        case .blue: return Catppuccin.blue
        case .teal: return Catppuccin.teal
        case .peach: return Catppuccin.peach
        case .mauve: return Catppuccin.mauve
        case .green: return Catppuccin.green
        case .red: return Catppuccin.red
        }
    }
}
