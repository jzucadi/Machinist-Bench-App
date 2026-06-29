import SwiftUI

// mm for display (×25.4) when metric; stores the imperial base. Identity when imperial.
func metricLengthBinding(_ base: Binding<Double>, system: UnitSystem) -> Binding<Double> {
    Binding(get: { system == .metric ? Convert.mm(fromInch: base.wrappedValue) : base.wrappedValue },
            set: { base.wrappedValue = system == .metric ? Convert.inch(fromMM: $0) : $0 })
}
