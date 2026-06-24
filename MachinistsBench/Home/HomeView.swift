import SwiftUI

struct HomeView: View {
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.imperial.rawValue
    private var system: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .imperial }

    var body: some View {
        NavigationStack {
            List {
                ForEach(SectionCatalog.groups, id: \.0) { groupName, items in
                    Section(groupName) {
                        ForEach(items) { item in row(item) }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Catppuccin.base)
            .navigationTitle("Machinist's Bench")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Units", selection: $unitRaw) {
                        Text("Imperial").tag(UnitSystem.imperial.rawValue)
                        Text("Metric").tag(UnitSystem.metric.rawValue)
                    }.pickerStyle(.segmented)
                }
            }
        }
        .tint(Catppuccin.blue)
    }

    @ViewBuilder private func row(_ item: SectionItem) -> some View {
        if item.available, item.id == "turn" {
            NavigationLink {
                TurningView(system: system).navigationTitle(item.name)
            } label: { label(item) }
        } else {
            label(item).foregroundStyle(Catppuccin.overlay0)
        }
    }

    private func label(_ item: SectionItem) -> some View {
        HStack {
            Circle().fill(item.accent.color).frame(width: 9, height: 9)
            Text(item.name).font(AppFont.display(15))
            Spacer()
            if !item.available {
                Text("soon").font(AppFont.mono(10)).foregroundStyle(Catppuccin.overlay0)
            }
        }
        .listRowBackground(Catppuccin.mantle)
    }
}

#Preview { HomeView() }
