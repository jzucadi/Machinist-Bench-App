import SwiftUI

enum AppFont {
    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold) }
    static func body(_ size: CGFloat) -> Font { .system(size: size, weight: .regular) }
    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular).monospacedDigit()
    }
}
