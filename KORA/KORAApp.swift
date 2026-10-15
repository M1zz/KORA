import SwiftUI
import TipKit
import UserNotifications
import LeeoKit

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
        // LeeoKit 앱 계약. 크래시 진단과 사용 통계(설치·실행·하루 한 번 app_open)는
        // 피드백 허브(iCloud.com.Ysoup.FeedbackHub)로 간다. 그 컨테이너가 KORA.entitlements 와
        // App ID(com.kora.leeo) 양쪽에 있어야 한다. 빠지면 컨테이너를 여는 순간 실행 즉시 죽는다.
        // 결제 퍼널 이벤트도 같은 허브로 간다 (KORASpec.analytics).
        LeeoKit.bootstrap(KORASpec.self)

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

        // 막차 알림을 앱을 보고 있을 때도 배너로 띄운다.
        UNUserNotificationCenter.current().delegate = KORANotificationPresenter.shared

        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
        // Screenshot runs must show clean screens — no coaching popovers.
        if ScreenshotScene.isActive { Tips.hideAllTipsForTesting() }
    }

    var body: some Scene {
        WindowGroup {
            // Single screen — the subway navigator is the whole app.
            SubwayView()
                .tint(KORATheme.accent)
        }
    }
}
