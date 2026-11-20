import OSLog
import ActivityKit
import SwiftUI

// MARK: - Shared attributes (must mirror widget/KoreaNaviLiveActivityAttributes.swift exactly)

@available(iOS 16.1, *)
struct KoreaNaviLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var currentStation: String
        var nextStation: String
        var stopsRemaining: Int
        var lineColorHex: String
        var lineName: String
    }

    var destinationStation: String
    /// Localized unit under the stop count ("정거장", "stops" …). Station and
    /// line names arrive already localized in the app's display language.
    var stopsUnit: String
}

// MARK: - Manager

@available(iOS 16.1, *)
@MainActor
final class KoreaNaviLiveActivityManager {
    static let shared = KoreaNaviLiveActivityManager()
    private init() {}

    private var currentActivity: Activity<KoreaNaviLiveActivityAttributes>?

    func start(
        destination: String,
        current: String,
        next: String,
        stopsRemaining: Int,
        stopsUnit: String,
        lineColor: Color,
        lineName: String
    ) async {
        guard KoreaNaviFlag.liveActivity.isEnabled else {
            KoreaNaviLog.liveActivity.notice("라이브 액티비티가 원격으로 꺼져 있어 시작하지 않습니다")
            return
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        await end()
        let attributes = KoreaNaviLiveActivityAttributes(destinationStation: destination, stopsUnit: stopsUnit)
        let state = KoreaNaviLiveActivityAttributes.ContentState(
            currentStation: current,
            nextStation: next,
            stopsRemaining: stopsRemaining,
            lineColorHex: lineColor.hexString,
            lineName: lineName
        )
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            KoreaNaviLog.liveActivity.error("라이브 액티비티 시작 실패: \(error.localizedDescription, privacy: .public)")
        }
    }

    func update(current: String, next: String, stopsRemaining: Int) async {
        guard let activity = currentActivity else { return }
        let prev = activity.content.state
        let state = KoreaNaviLiveActivityAttributes.ContentState(
            currentStation: current,
            nextStation: next,
            stopsRemaining: stopsRemaining,
            lineColorHex: prev.lineColorHex,
            lineName: prev.lineName
        )
        await activity.update(ActivityContent(state: state, staleDate: nil))
    }

    func end() async {
        await currentActivity?.end(nil, dismissalPolicy: .immediate)
        currentActivity = nil
    }

    /// Ends every KoreaNavi Live Activity, including ones orphaned by a previous
    /// process. The ride state (`boardedAt`) isn't persisted, so an activity
    /// that survives an app kill would otherwise sit on the Lock Screen with
    /// nothing left to update or end it.
    func endAll() async {
        currentActivity = nil
        for activity in Activity<KoreaNaviLiveActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    /// For `willTerminate`: the process dies as soon as the handler returns, so
    /// block briefly until the end requests have been handed to the system.
    nonisolated static func endAllBeforeTermination() {
        let done = DispatchSemaphore(value: 0)
        Task.detached {
            for activity in Activity<KoreaNaviLiveActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            done.signal()
        }
        _ = done.wait(timeout: .now() + 2)
    }
}

// MARK: - Color → hex helper (라이브 액티비티 · 워치가 함께 쓴다)

extension Color {
    var hexString: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X",
                      Int((r * 255).rounded()),
                      Int((g * 255).rounded()),
                      Int((b * 255).rounded()))
    }
}
