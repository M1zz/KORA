import ActivityKit
import SwiftUI

// MARK: - Shared attributes (must mirror widget/KORALiveActivityAttributes.swift exactly)

@available(iOS 16.1, *)
struct KORALiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var currentStation: String
        var nextStation: String
        var stopsRemaining: Int
        var lineColorHex: String
        var lineName: String
    }

    var destinationStation: String
}

// MARK: - Manager

@available(iOS 16.1, *)
@MainActor
final class KORALiveActivityManager {
    static let shared = KORALiveActivityManager()
    private init() {}

    private var currentActivity: Activity<KORALiveActivityAttributes>?

    func start(
        destination: String,
        current: String,
        next: String,
        stopsRemaining: Int,
        lineColor: Color,
        lineName: String
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        await end()
        let attributes = KORALiveActivityAttributes(destinationStation: destination)
        let state = KORALiveActivityAttributes.ContentState(
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
        } catch {}
    }

    func update(current: String, next: String, stopsRemaining: Int) async {
        guard let activity = currentActivity else { return }
        let prev = activity.content.state
        let state = KORALiveActivityAttributes.ContentState(
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
}

// MARK: - Color → hex helper

private extension Color {
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
