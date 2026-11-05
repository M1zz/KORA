//
//  WatchRideLink.swift
//  아이폰과 잇는다. '지금 열차' 를 받아 두고, 한 정거장 남는 시각에 손목 알림을 건다.
//
//  알림은 워치가 스스로 건다 — 아이폰이 주머니에서 잠들어 더 보내지 못해도, 아이폰 화면을 보고 있어
//  아이폰 알림이 손목으로 넘어오지 않을 때도 손목이 울린다. 같은 열차에서는 한 번만 울린다.
//

import Foundation
import SwiftUI
import WatchConnectivity
import UserNotifications
import WidgetKit

@MainActor
final class WatchRideLink: NSObject, ObservableObject {
    static let shared = WatchRideLink()

    @Published private(set) var ride: RideSnapshot? = RideLink.load()

    func activate() {
        #if DEBUG
        if let demo = WatchDemo.ride { ride = demo; return }
        #endif
        guard WCSession.isSupported(), WCSession.default.activationState != .activated else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// 백그라운드로 깨어났을 때 받을 것이 다 들어올 때까지 기다린다 (최대 몇 초)
    func drain() async {
        activate()
        for _ in 0..<25 where WCSession.default.hasContentPending {
            try? await Task.sleep(for: .milliseconds(200))
        }
    }

    fileprivate func receive(_ info: [String: Any]) {
        guard let data = info[RideLink.snapshotKey] as? Data else { return }
        let new = RideLink.decode(data)
        RideLink.save(new)
        scheduleAlert(new)
        guard new != ride else { return }
        ride = new
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: 하차 진동

    private static let alertID = "kora.alight"

    /// 한 정거장 남는 시각에 알림 한 통. 새 장이 오면 시각을 다시 맞추고, 이미 울린 열차는 다시 울리지 않는다.
    private func scheduleAlert(_ ride: RideSnapshot?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.alertID])
        guard let ride, ride.vibrate, ride.stations.count > 1 else { return }
        // 이 열차에 건 알림의 시각이 이미 지났다 = 울렸다
        let defaults = UserDefaults(suiteName: RideLink.group) ?? .standard
        if defaults.string(forKey: "alertRide") == ride.id,
           defaults.double(forKey: "alertAt") <= Date.now.timeIntervalSince1970 { return }

        let at = max(ride.alertDate, .now.addingTimeInterval(1))
        defaults.set(ride.id, forKey: "alertRide")
        defaults.set(at.timeIntervalSince1970, forKey: "alertAt")

        let content = UNMutableNotificationContent()
        content.title = ride.labels.nextStopGetOff
        content.body = ride.transfers ? "\(ride.alightStation) · \(ride.labels.transfer)" : ride.alightStation
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: at.timeIntervalSinceNow, repeats: false)
        center.add(UNNotificationRequest(identifier: Self.alertID, content: content, trigger: trigger))
    }
}

extension WatchRideLink: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {
        let context = session.receivedApplicationContext
        Task { @MainActor in self.receive(context) }
    }
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        Task { @MainActor in self.receive(context) }
    }
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { @MainActor in self.receive(userInfo) }
    }
}

/// 워치는 늘 어두운 화면이라 아이폰의 어두운 화면 색을 쓴다.
enum WatchTheme {
    static let accent = Color(red: 0.898, green: 0.314, blue: 0.357)   // KORAAccent (어두운 화면)
    static let alert = Color(red: 1.0, green: 0.78, blue: 0.25)         // 하차 경고 — 노선 색 위에서도 읽히게
}
