import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            SubwayView()
                .tabItem {
                    Label("電車", systemImage: "tram.fill")
                }
            SaveView()
                .tabItem {
                    Label("行きたい", systemImage: "bookmark.fill")
                }
        }
        .tint(KORATheme.accent)
    }
}

#Preview {
    MainTabView()
}
