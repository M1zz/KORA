import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .save

    enum Tab {
        case save, go, subway, now, share
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            SaveView()
                .tabItem {
                    Label("Save", systemImage: "bookmark.fill")
                }
                .tag(Tab.save)

            GoView()
                .tabItem {
                    Label("Go", systemImage: "map.fill")
                }
                .tag(Tab.go)

            SubwayView()
                .tabItem {
                    Label("대중교통", systemImage: "tram.fill")
                }
                .tag(Tab.subway)

            NowView()
                .tabItem {
                    Label("Now", systemImage: "clock.fill")
                }
                .tag(Tab.now)

            ShareView()
                .tabItem {
                    Label("Share", systemImage: "person.2.fill")
                }
                .tag(Tab.share)
        }
        .tint(KORATheme.accent)
    }
}

#Preview {
    MainTabView()
}
