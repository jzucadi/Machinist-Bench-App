import Foundation

struct SectionItem: Identifiable {
    let id: String
    let name: String
    let accent: Accent
    let available: Bool
}

enum SectionCatalog {
    static let groups: [(String, [SectionItem])] = [
        ("Cutting", [
            SectionItem(id: "turn", name: "Turning", accent: .blue, available: true),
            SectionItem(id: "drill", name: "Drilling", accent: .teal, available: true),
            SectionItem(id: "mill", name: "Milling", accent: .peach, available: true),
            SectionItem(id: "tap", name: "Tapping", accent: .mauve, available: true),
            SectionItem(id: "thread", name: "Threading", accent: .green, available: true),
            SectionItem(id: "bore", name: "Boring", accent: .peach, available: true),
            SectionItem(id: "ream", name: "Reaming", accent: .teal, available: true),
            SectionItem(id: "saw", name: "Band Saw", accent: .mauve, available: true),
        ]),
        ("Calculate & Measure", [
            SectionItem(id: "math", name: "Shop Math", accent: .mauve, available: false),
            SectionItem(id: "conv", name: "Converter", accent: .blue, available: false),
            SectionItem(id: "layout", name: "Layout", accent: .blue, available: false),
            SectionItem(id: "scale", name: "Scale", accent: .mauve, available: false),
        ]),
        ("Reference", [
            SectionItem(id: "threads", name: "Threads", accent: .blue, available: false),
            SectionItem(id: "rose", name: "Rose Engine", accent: .red, available: false),
            SectionItem(id: "ref", name: "Reference", accent: .blue, available: false),
        ]),
    ]
}
