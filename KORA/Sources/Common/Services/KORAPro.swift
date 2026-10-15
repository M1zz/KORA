import Foundation
import Combine
import StoreKit
import LeeoKit

/// KORA Pro 권한과 무료 "안내 탑승" 횟수.
///
/// 길찾기·타는 방향·실시간 도착·카메라 방향 확인은 늘 무료다. 무료로 세는 건
/// **안내 탑승**(잠금 화면 라이브 액티비티, 안내방송 인식, 하차 진동) 하나뿐이고,
/// 여정 하나(출발 → 도착)를 1회로 센다. 한도를 넘어도 탑승은 막지 않는다 —
/// 화면 안 진행 표시는 그대로 두고 위의 세 가지만 끈다. 열차 안에서 결제 화면으로
/// 길을 막으면 내릴 역을 놓친다.
///
/// 정책(한도 3회, 상품 ID)은 `KORASpec.monetization` 한 곳에 있다.
@MainActor
final class KORAPro: ObservableObject {
    static let shared = KORAPro()

    /// `KORASpec.monetization` 의 `freeLimits` 키.
    nonisolated static let guidedRideKey = "guidedRide"

    /// 결제 없이 나간 마지막 빌드 번호. 이 빌드 이하로 처음 설치한 사람은 평생 Pro다
    /// ("광고·인앱 결제 없음" 이라고 약속하고 받은 사용자). 결제가 들어가기 전에
    /// 무료 빌드를 하나 더 올리면 이 숫자도 같이 올린다.
    static let lastFreeBuild = 8

    let store: LeeoStore

    /// 지금까지 쓴 무료 안내 탑승 횟수 (Pro 가 된 뒤에는 늘지 않는다).
    @Published private(set) var guidedRidesUsed: Int

    private static let usedKey = "kora.guided_rides_used"
    private var storeChange: AnyCancellable?

    private init() {
        guard let config = KORASpec.paywall else {
            preconditionFailure("KORASpec.monetization 에 상품이 없다")
        }
        store = LeeoStore(
            config: config,
            unlockOverride: { Self.unlockOverride() },
            grandfather: { await Self.installedBeforePaywall() }
        )
        guidedRidesUsed = UserDefaults.standard.integer(forKey: Self.usedKey)
        // 구매·복원·환불로 권한이 바뀌면 이 객체를 보는 화면도 다시 그린다.
        storeChange = store.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var hasPro: Bool { store.hasPro }

    /// 남은 무료 안내 탑승. Pro 면 nil.
    var freeRidesLeft: Int? {
        store.gate.remaining(Self.guidedRideKey, current: guidedRidesUsed)
    }

    /// 새 여정의 첫 열차에 탈 때 한 번 부른다. true 면 이번 여정은 Pro 안내로 간다.
    func beginGuidedRide() -> Bool {
        let decision = store.gate.evaluate(Self.guidedRideKey, current: guidedRidesUsed)
        guard decision.isAllowed else {
            LeeoAnalyticsCenter.track(.gateBlocked(key: Self.guidedRideKey))
            return false
        }
        if !hasPro {
            guidedRidesUsed += 1
            UserDefaults.standard.set(guidedRidesUsed, forKey: Self.usedKey)
        }
        LeeoAnalyticsCenter.track(.custom(name: "guided_ride_started",
                                          parameters: ["pro": hasPro ? "1" : "0"]))
        return true
    }

    // MARK: - 권한 정책

    /// DEBUG 에서 결제 화면을 시험할 때: `-KORAForcePro NO` 는 강제 잠금, `YES` 는 해제.
    /// 스크린샷 촬영은 늘 Pro 화면이어야 한다.
    private static func unlockOverride() -> Bool? {
        #if DEBUG
        if ScreenshotScene.isActive { return true }
        return UserDefaults.standard.object(forKey: "KORAForcePro") as? Bool
        #else
        return nil
        #endif
    }

    /// 결제가 들어가기 전 빌드로 처음 설치했는지. iOS 의 `originalAppVersion` 은
    /// 버전이 아니라 **빌드 번호**다. 샌드박스·TestFlight 는 늘 "1.0" 을 주므로
    /// 실서비스 영수증만 본다 (그러지 않으면 테스트에서 결제 화면을 볼 수 없다).
    private static func installedBeforePaywall() async -> Bool {
        guard let result = try? await AppTransaction.shared,
              case .verified(let transaction) = result,
              transaction.environment == .production,
              let build = Int(transaction.originalAppVersion)
        else { return false }
        return build <= lastFreeBuild
    }
}
