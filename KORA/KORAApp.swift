import SwiftUI
import TipKit
import FirebaseCore

/// Print only in debug builds. Release builds compile the call site away.
/// Tagged logs throughout the app (`[Exit]`, `[ExitFetch]`, `[InlineResolve]`,
/// `[CoordBackfill]`) all funnel through this so production users never see
/// them in os_log either.
@inline(__always)
func debugLog(_ message: @autoclosure () -> String) {
    #if DEBUG
    print(message())
    #endif
}

@main
struct KORAApp: App {
    init() {
        // Initialize Firebase (Google Analytics for Firebase). Must run before
        // any Analytics calls; reads GoogleService-Info.plist from the bundle.
        FirebaseApp.configure()

        #if DEBUG
        // Fail-fast: if any station's English is a translation instead of a
        // romanization (and it isn't whitelisted), crash DEBUG so the dev
        // notices immediately.
        MetroLineData.assertStationNamesValid()
        #endif

        // A Live Activity must not outlive the app: the ride state is in memory
        // only, so end it when the app is killed, and clear any left over from
        // a run that was killed while suspended (no willTerminate in that case).
        if #available(iOS 16.1, *) {
            NotificationCenter.default.addObserver(
                forName: UIApplication.willTerminateNotification, object: nil, queue: .main
            ) { _ in
                KORALiveActivityManager.endAllBeforeTermination()
            }
            Task { @MainActor in await KORALiveActivityManager.shared.endAll() }
        }

        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }

    var body: some Scene {
        WindowGroup {
            // Single screen — the subway navigator is the whole app.
            SubwayView()
                .tint(KORATheme.accent)
        }
    }
}
