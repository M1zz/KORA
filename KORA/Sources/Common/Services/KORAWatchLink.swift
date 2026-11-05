import Foundation
import WatchConnectivity

/// Apple Watch 로 '지금 타고 있는 열차' 한 장(RideSnapshot)을 보낸다.
///
/// 탑승 · 정거장이 바뀔 때 · 내릴 때 보낸다. 워치는 받은 장으로 남은 정거장을 혼자 세고,
/// 한 정거장 남는 순간 손목을 울린다 — 아이폰이 주머니에서 잠들어 더 보내지 못해도.
/// 컴플리케이션은 하루에 깨울 수 있는 횟수가 정해져 있어, 열차가 바뀔 때(역 · 탑승 · 하차)만 깨운다.
@MainActor
final class KORAWatchLink: NSObject {
    static let shared = KORAWatchLink()

    /// 마지막으로 보낸 장. 바깥 nil = 아직 안 보냄, 안쪽 nil = '안 타는 중'을 보냄
    private var lastSent: RideSnapshot??
    /// 보내려던 마지막 장 — 연결이 늦게 열리거나 워치가 바뀌면 이것을 다시 보낸다.
    /// 처음엔 '안 타는 중': 앱이 새로 켜졌다는 건 지난 열차가 끝났다는 뜻이다.
    private var latest: RideSnapshot?

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func publish(_ ride: RideSnapshot?) {
        latest = ride
        if let last = lastSent, last == ride { return }
        guard WCSession.isSupported() else { return }
        let wc = WCSession.default
        guard wc.activationState == .activated, wc.isPaired, wc.isWatchAppInstalled else { return }
        let hadRide = (lastSent ?? nil) != nil
        lastSent = .some(ride)

        let payload: [String: Any] = [RideLink.snapshotKey: RideLink.encode(ride)]
        try? wc.updateApplicationContext(payload)
        // '안 타는 중' 을 거듭 보낼 때는 컴플리케이션을 깨우지 않는다(지난 장은 워치가 스스로 버린다)
        if ride != nil || hadRide, wc.isComplicationEnabled, wc.remainingComplicationUserInfoTransfers > 0 {
            wc.transferCurrentComplicationUserInfo(payload)
        }
    }
}

private extension KORAWatchLink {
    func resend() {
        lastSent = nil
        publish(latest)
    }
}

extension KORAWatchLink: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState,
                             error: Error?) {
        Task { @MainActor in self.resend() }
    }
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.resend() }
    }
}
