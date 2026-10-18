import SwiftUI

/// Single-screen subway navigation host. Wraps the navigator in a
/// NavigationStack so the language picker can live in the standard
/// trailing toolbar slot.
struct SubwayView: View {
    @AppStorage(KORAOnboarding.completedKey) private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    @State private var showWhatsNew = false

    var body: some View {
        NavigationStack {
            SubwayNavigatorView()
                .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            KORAOnboardingView(lang: .inAppChoice) {
                hasCompletedOnboarding = true
                showOnboarding = false
            }
        }
        .sheet(isPresented: $showWhatsNew) {
            WhatsNewView(lang: .inAppChoice, items: KORAWhatsNew.currentItems)
        }
        .onAppear {
            KORALaunch.firstScreenAppeared()
            guard !ScreenshotScene.isActive else { return }
            if !hasCompletedOnboarding {
                showOnboarding = true
                // 첫 설치: 새로 생긴 것은 띄우지 않고 지금 버전을 본 것으로 적는다.
                _ = KORAWhatsNew.shouldPresent(isFirstLaunch: true)
            } else if KORAWhatsNew.shouldPresent(isFirstLaunch: false) {
                showWhatsNew = true
            }
        }
    }
}

#Preview {
    SubwayView()
}

/// Fixed screen states for App Store screenshots, chosen with the launch
/// argument `-KORAShotScene <name>`. Only honoured in Debug builds.
enum ScreenshotScene: String {
    case route, board, ride, search, language, paywall, exits

    static var current: ScreenshotScene? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "KORAShotScene").flatMap(ScreenshotScene.init(rawValue:))
        #else
        nil
        #endif
    }

    static var isActive: Bool { current != nil }
}
