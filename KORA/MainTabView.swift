import SwiftUI

/// During the "navigation-first" phase we hide all tabs and run the
/// SubwayView as the sole root screen. The data layer (PlaceStore,
/// SharedInbox, NavigationCoordinator) stays intact so that:
/// - previously-saved places still surface in the navigator's quick list
/// - URLs sent via Share Extension are kept in the App Group inbox and will
///   be picked up automatically when the Save UI is reintroduced.
struct MainTabView: View {
    var body: some View {
        SubwayView()
    }
}

#Preview {
    MainTabView()
}
