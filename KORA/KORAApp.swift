import SwiftUI
import TipKit

@main
struct KORAApp: App {
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
    }
}
