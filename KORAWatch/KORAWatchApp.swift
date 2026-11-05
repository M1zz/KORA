//
//  KORAWatchApp.swift
//  KORAWatch
//
//  손목 위 한 화면: 내릴 역까지 남은 정거장 하나. 한 정거장 남으면 손목이 울린다.
//  붐비는 열차에서 폰을 꺼내지 않아도 되게 — 길 안내는 아이폰에서 시작하고, 타는 동안은 손목만 본다.
//  누를 것은 없다. 열차가 움직이는 대로 바뀌고, Digital Crown 으로 위아래를 본다.
//

import SwiftUI
import WatchKit
import UserNotifications

@main
struct KORAWatchApp: App {
    @WKApplicationDelegateAdaptor private var delegate: WatchAppDelegate

    var body: some Scene {
        WindowGroup {
            WatchRideView(link: .shared)
        }
        // 아이폰이 컴플리케이션을 깨우면 앱이 잠깐 깨어 새 장을 받고 컴플리케이션 · 하차 진동을 맞춘다
        .backgroundTask(.watchConnectivity) { await WatchRideLink.shared.drain() }
    }
}

final class WatchAppDelegate: NSObject, WKApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        // 스크린샷용 데모에서는 권한 창이 화면을 가리지 않게 묻지 않는다
        #if DEBUG
        let demo = WatchDemo.ride != nil
        #else
        let demo = false
        #endif
        if !demo { center.requestAuthorization(options: [.alert, .sound]) { _, _ in } }
        Task { @MainActor in WatchRideLink.shared.activate() }
    }

    /// 앱을 보고 있을 때 한 정거장 남아도 알림 · 진동은 그대로 온다
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions { [.banner, .sound] }
}

// MARK: - 한 화면

struct WatchRideView: View {
    @ObservedObject var link: WatchRideLink

    var body: some View {
        NavigationStack {
            if let ride = link.ride {
                TimelineView(.periodic(from: .now, by: 5)) { context in
                    RideBody(ride: ride, now: context.date)
                }
            } else {
                waiting
            }
        }
    }

    private var waiting: some View {
        VStack(spacing: 8) {
            Image(systemName: "tram.fill")
                .font(.title)
                .foregroundStyle(WatchTheme.accent)
                .accessibilityHidden(true)
            Text("Start a route on your iPhone and the stops left will show here.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
        .navigationTitle(Text(verbatim: "KORA"))
    }
}

/// 타는 중 — 남은 정거장을 크게, 그 아래 내릴 역과 다음 역.
/// 한 정거장 남으면 화면 전체가 '다음 정거장에서 내리세요' 로 바뀐다.
struct RideBody: View {
    let ride: RideSnapshot
    let now: Date

    var body: some View {
        let left = ride.stopsLeft(at: now)
        let color = ride.lineColor ?? WatchTheme.accent
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                // 노선 — 승강장 표지판처럼 노선 색으로
                Label { Text(ride.line) } icon: { Image(systemName: "tram.fill") }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(color)
                if left <= 1 {
                    alert(left: left)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(verbatim: "\(left)")
                            .font(.system(size: 64, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(color)
                            .contentTransition(.numericText(countsDown: true))
                        Text(ride.stopsUnit(left))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
                alight
                if left >= 2, let next = ride.nextStation(at: now) {
                    HStack(spacing: 4) {
                        Text(ride.labels.nextStation).foregroundStyle(.secondary)
                        Text(next).fontWeight(.semibold)
                    }
                    .font(.footnote)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityElement(children: .combine)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.snappy, value: left)
        }
        .containerBackground(color.opacity(left <= 1 ? 0.45 : 0.22).gradient, for: .navigation)
    }

    /// 한 정거장 남음 · 지금 내릴 때 — 다른 것 다 걷어 내고 이 말만
    private func alert(left: Int) -> some View {
        Text(left == 1 ? ride.labels.nextStopGetOff : ride.labels.getOffNow)
            .font(.title2.weight(.bold))
            .foregroundStyle(WatchTheme.alert)
            .lineLimit(3)
            .minimumScaleFactor(0.6)   // 긴 낱말(그리스어 · 독일어)이 잘리지 않게
            .accessibilityAddTraits(.isHeader)
    }

    /// 내릴 역 — 갈아타는 역이면 '환승' 을 붙인다
    private var alight: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(ride.labels.getOffAt)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Text(ride.alightStation)
                    .font(.title3.weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                if ride.transfers {
                    Text(ride.labels.transfer)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(.white.opacity(0.2), in: Capsule())
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
