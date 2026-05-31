import SwiftUI
import TipKit

/// Print only in debug builds. Release builds compile the call site away.
/// Tagged logs throughout the app (`[Exit]`, `[ExitFetch]`, `[InlineResolve]`,
/// `[CoordBackfill]`, `[Odsay]`) all funnel through this so production users
/// never see them in os_log either.
@inline(__always)
func debugLog(_ message: @autoclosure () -> String) {
    #if DEBUG
    print(message())
    #endif
}

@main
struct KORAApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        #if DEBUG
        // Fail-fast: if any station's English is a translation instead of a
        // romanization (and it isn't whitelisted), crash DEBUG so the dev
        // notices immediately.
        MetroLineData.assertStationNamesValid()
        #endif

        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { consumeSharedInbox() }
        }
    }

    /// Reads any pending URL handed off from the Share Extension and routes it
    /// to the Save tab for parsing. Called every time the app becomes active so
    /// shares received while the app was in the background are never missed.
    private func consumeSharedInbox() {
        // Drain places saved directly by the Share Extension (new SwiftUI flow)
        Task { @MainActor in PlaceStore.shared.drainExtensionQueue() }

        // Handle URL/text handoff from the old SLCompose-based extension path
        guard let payload = SharedInbox.consume() else { return }
        Task { @MainActor in
            NavigationCoordinator.shared.receiveSharedURL(payload.url, text: payload.text)
        }
    }
}
