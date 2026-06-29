import SwiftUI
import UIKit

struct HomeView: View {
    init() {
        // Color the navigation titles lavender (no native SwiftUI modifier for this yet).
        // Must set all three appearances; the large title at scroll-top uses scrollEdgeAppearance.
        let lavender = UIColor(Catppuccin.lavender)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.largeTitleTextAttributes = [.foregroundColor: lavender]
        appearance.titleTextAttributes = [.foregroundColor: lavender]
        let bar = UINavigationBar.appearance()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(SectionCatalog.groups, id: \.0) { groupName, items in
                    Section {
                        ForEach(items) { item in row(item) }
                    } header: {
                        Text(groupName)
                            .font(AppFont.display(13))
                            .foregroundStyle(Catppuccin.lavender)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Catppuccin.base)
            .navigationTitle("Machinist's Bench")
        }
        .tint(Catppuccin.blue)
    }

    @ViewBuilder private func row(_ item: SectionItem) -> some View {
        if item.available {
            NavigationLink {
                destination(for: item.id).navigationTitle(item.name)
            } label: { label(item) }
        } else {
            label(item).foregroundStyle(Catppuccin.overlay0)
        }
    }

    @ViewBuilder private func destination(for id: String) -> some View {
        switch id {
        case "turn": TurningView()
        case "drill": DrillingView()
        case "mill": MillingView()
        case "tap": TappingView()
        case "thread": ThreadingView()
        case "bore": BoringView()
        case "ream": ReamingView()
        case "saw": BandSawView()
        default: EmptyView()
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
