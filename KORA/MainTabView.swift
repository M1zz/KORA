import SwiftUI

struct MainTabView: View {
    @AppStorage("kora.display_language") private var languagePref: String = ""

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
        TabView {
            SaveView()
                .tabItem {
                    Label(savedLabel, systemImage: "bookmark.fill")
                }
            SubwayView()
                .tabItem {
                    Label(subwayLabel, systemImage: "tram.fill")
                }
        }
        .tint(KORATheme.accent)
    }
}

#Preview {
    MainTabView()
}
