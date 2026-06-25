import SwiftUI

// Imperial/Metric segmented toggle, backed by the shared @AppStorage unit setting.
// Apply `.unitToolbar()` to any screen so the toggle appears in its navigation bar.
struct UnitToolbar: ViewModifier {
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.imperial.rawValue

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("Units", selection: $unitRaw) {
                    Text("Imperial").tag(UnitSystem.imperial.rawValue)
                    Text("Metric").tag(UnitSystem.metric.rawValue)
                }
                .pickerStyle(.segmented)
            }
        }
    }
}

extension View {
    func unitToolbar() -> some View { modifier(UnitToolbar()) }
}
