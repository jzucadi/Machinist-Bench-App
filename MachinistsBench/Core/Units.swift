import Foundation

public enum UnitSystem: String, CaseIterable, Sendable {
    case imperial, metric
}

public enum Convert {
    public static func mPerMin(fromSFM sfm: Double) -> Double { sfm * 0.3048 }
    public static func cm3(fromCubicInchPerMin v: Double) -> Double { v * 16.387064 }
    public static func mm(fromInch v: Double) -> Double { v * 25.4 }
    public static func inch(fromMM v: Double) -> Double { v / 25.4 }
    public static func kW(fromHP v: Double) -> Double { v * 0.7457 }
}
