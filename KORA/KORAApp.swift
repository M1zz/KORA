import SwiftUI
import TipKit
import UserNotifications
import LeeoKit
import OSLog

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
        // 원격 킬스위치(KORAFlag)도 함께 켠다 — 같은 허브의 RemoteFlags 레코드를 읽는다.
        LeeoKit.bootstrap(KORASpec.self, flags: KORAFlag.self)

        // 연달아 시작하다 죽으면 이번 실행은 세이프 모드 — 시작할 때 하는 무거운 일을 건너뛴다.
        let safeMode = KORALaunch.begin()

        // 사용법 안내가 생기기 전부터 쓰던 사람에게는 안내를 띄우지 않는다.
        KORAOnboarding.markDoneForExistingUsers(launchCount: LeeoEngagement.shared.launchCount)

        #if DEBUG
        // Fail-fast: if any station's English is a translation instead of a
        // romanization (and it isn't whitelisted), crash DEBUG so the dev
        // notices immediately.
        MetroLineData.assertStationNamesValid()
        // 계약(정책 URL · 결제 문턱 · 분석 싱크 등)이 배포할 수 없는 상태면 개발 중에 바로 멈춘다.
        // 부트스트랩은 보고서를 찍기만 하므로 놓치기 쉽다 — 역 이름 검사와 같은 방식으로 막는다.
        let preflight = LeeoPreflight.audit(KORASpec.self)
        assert(preflight.isReleasable, "LeeoKit 계약 점검 실패: \(preflight)")
        #endif

        // A Live Activity must not outlive the app: the ride state is in memory
        // only, so end it when the app is killed, and clear any left over from
        // a run that was killed while suspended (no willTerminate in that case).
        if #available(iOS 16.1, *), !safeMode {
            NotificationCenter.default.addObserver(
                forName: UIApplication.willTerminateNotification, object: nil, queue: .main
            ) { _ in
                KORALiveActivityManager.endAllBeforeTermination()
            }
            Task { @MainActor in await KORALiveActivityManager.shared.endAll() }
        }

        // 막차 알림을 앱을 보고 있을 때도 배너로 띄운다.
        UNUserNotificationCenter.current().delegate = KORANotificationPresenter.shared

        // 팁 저장소가 깨져 시작이 죽는 경우가 있어 세이프 모드에서는 열지 않는다(팁만 안 뜬다).
        if !safeMode {
            do {
                try Tips.configure([
                    .displayFrequency(.immediate),
                    .datastoreLocation(.applicationDefault)
                ])
            } catch {
                KORALog.app.error("팁 설정 실패: \(error.localizedDescription, privacy: .public)")
            }
        }
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
