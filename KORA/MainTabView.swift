import SwiftUI

struct MainTabView: View {
    @AppStorage("kora.display_language") private var languagePref: String = ""
    @State private var selectedTab: Int = 0
    @State private var coordinator = NavigationCoordinator.shared

    private enum Tab: Int { case saved = 0, subway = 1 }

    private var lang: StationLanguage {
        guard !languagePref.isEmpty, let e = StationLanguage(rawValue: languagePref)
        else { return StationLanguage.resolveFromSystemLocale() }
        return e
    }

    private var subwayLabel: String {
        switch lang {
        case .korean:   return "전철"
        case .japanese: return "電車"
        case .english:  return "Subway"
        case .chinese:  return "地铁"
        }
    }

    private var savedLabel: String {
        switch lang {
        case .korean:   return "가고 싶은"
        case .japanese: return "行きたい"
        case .english:  return "Saved"
        case .chinese:  return "想去的"
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            SaveView()
                .tabItem {
                    Label(savedLabel, systemImage: "bookmark.fill")
                }
                .tag(Tab.saved.rawValue)
            SubwayView()
                .tabItem {
                    Label(subwayLabel, systemImage: "tram.fill")
                }
                .tag(Tab.subway.rawValue)
        }
        .tint(KORATheme.accent)
        .onChange(of: coordinator.routeRequestNonce) { _, _ in
            if coordinator.pendingDestination != nil {
                selectedTab = Tab.subway.rawValue
            }
        }
    }
}

#Preview {
    MainTabView()
}
