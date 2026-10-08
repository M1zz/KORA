import SwiftUI

/// Single-screen subway navigation host. Wraps the navigator in a
/// NavigationStack so the language picker can live in the standard
/// trailing toolbar slot.
struct SubwayView: View {
    var body: some View {
        NavigationStack {
            SubwayNavigatorView()
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SubwayView()
}

/// Fixed screen states for App Store screenshots, chosen with the launch
/// argument `-KORAShotScene <name>`. Only honoured in Debug builds.
enum ScreenshotScene: String {
    case route, board, ride, search, language

    static var current: ScreenshotScene? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "KORAShotScene").flatMap(ScreenshotScene.init(rawValue:))
        #else
        nil
        #endif
    }

    static var isActive: Bool { current != nil }
}
