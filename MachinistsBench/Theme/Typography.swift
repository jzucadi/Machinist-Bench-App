import SwiftUI

// Native SF only. The web's terminal/monospace font is intentionally dropped.
enum AppFont {
    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold) }
    static func body(_ size: CGFloat) -> Font { .system(size: size, weight: .regular) }
    // SF with tabular figures — readable letters, aligned digits (NOT a monospace face).
    static func mono(_ size: CGFloat) -> Font { .system(size: size, weight: .regular).monospacedDigit() }
}
