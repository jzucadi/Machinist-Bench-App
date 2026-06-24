public struct Material: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let hardness: String
    public let hssSFM: ClosedRange<Int>
    public let carbideSFM: ClosedRange<Int>
    public let feedIPR: Double
    public let kp: Double
}

public enum Materials {
    public static let all: [Material] = [
        Material(id: "alum",     name: "Aluminum (wrought)",          hardness: "~95 HB",     hssSFM: 250...400, carbideSFM: 600...1200, feedIPR: 0.012, kp: 0.25),
        Material(id: "al6061",   name: "Aluminum 6061-T6",            hardness: "~95 HB",     hssSFM: 250...400, carbideSFM: 600...1200, feedIPR: 0.012, kp: 0.28),
        Material(id: "brass",    name: "Brass (free-cutting)",        hardness: "~120 HB",    hssSFM: 150...300, carbideSFM: 400...700,  feedIPR: 0.010, kp: 0.55),
        Material(id: "bronze",   name: "Bronze (leaded)",             hardness: "~150 HB",    hssSFM: 90...150,  carbideSFM: 200...400,  feedIPR: 0.010, kp: 0.65),
        Material(id: "castiron", name: "Cast Iron (gray, soft)",      hardness: "120–150 HB", hssSFM: 80...120,  carbideSFM: 250...400,  feedIPR: 0.012, kp: 0.55),
        Material(id: "ductile",  name: "Cast Iron (ductile/nodular)", hardness: "170–200 HB", hssSFM: 60...100,  carbideSFM: 200...350,  feedIPR: 0.011, kp: 0.80),
        Material(id: "s12l14",   name: "12L14 Steel (free-mach.)",    hardness: "~160 HB",    hssSFM: 110...160, carbideSFM: 400...700,  feedIPR: 0.013, kp: 0.90),
        Material(id: "lowc",     name: "Low-Carbon Steel (1018)",     hardness: "~125 HB",    hssSFM: 90...130,  carbideSFM: 350...550,  feedIPR: 0.012, kp: 1.00),
        Material(id: "medc",     name: "Medium-Carbon Steel (1045)",  hardness: "~180 HB",    hssSFM: 70...100,  carbideSFM: 300...450,  feedIPR: 0.011, kp: 1.10),
        Material(id: "alloy",    name: "Alloy Steel (4140)",          hardness: "~200 HB",    hssSFM: 60...90,   carbideSFM: 250...400,  feedIPR: 0.010, kp: 1.40),
        Material(id: "o1",       name: "O-1 Tool Steel (annealed)",   hardness: "~190 HB",    hssSFM: 55...80,   carbideSFM: 220...375,  feedIPR: 0.009, kp: 1.50),
        Material(id: "tool",     name: "Tool Steel (annealed)",       hardness: "~220 HB",    hssSFM: 50...70,   carbideSFM: 200...350,  feedIPR: 0.009, kp: 1.40),
        Material(id: "ss303",    name: "Stainless 303 (free-mach.)",  hardness: "~160 HB",    hssSFM: 70...100,  carbideSFM: 250...400,  feedIPR: 0.009, kp: 1.40),
        Material(id: "ss304",    name: "Stainless 304 (austenitic)",  hardness: "~150 HB",    hssSFM: 50...80,   carbideSFM: 200...350,  feedIPR: 0.008, kp: 1.40),
        Material(id: "ss316",    name: "Stainless 316 (austenitic)",  hardness: "~160 HB",    hssSFM: 40...70,   carbideSFM: 175...300,  feedIPR: 0.007, kp: 1.50),
        Material(id: "ss416",    name: "Stainless 416 (free-mach.)",  hardness: "~180 HB",    hssSFM: 80...120,  carbideSFM: 300...450,  feedIPR: 0.009, kp: 1.30),
        Material(id: "ti",       name: "Titanium (Ti-6Al-4V)",        hardness: "~330 HB",    hssSFM: 30...50,   carbideSFM: 100...200,  feedIPR: 0.007, kp: 1.20),
        Material(id: "inconel",  name: "Inconel / Superalloy",        hardness: "~300 HB",    hssSFM: 15...30,   carbideSFM: 60...120,   feedIPR: 0.006, kp: 2.20),
        Material(id: "plastic",  name: "Plastic / Nylon / Delrin",    hardness: "—",          hssSFM: 200...500, carbideSFM: 400...1000, feedIPR: 0.012, kp: 0.10),
    ]

    public static func byID(_ id: String) -> Material? { all.first { $0.id == id } }
}
