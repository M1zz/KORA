//
//  KORASpec.swift
//  KORA
//
//  LeeoKit 계약(LeeoAppSpec) 준수 — 이 앱의 공통 기능 설정값 단일 소스.
//
//  ⚠️ 피드백 허브(iCloud.com.Ysoup.FeedbackHub)는 아직 이 앱의 entitlements 에 없다.
//     피드백 화면·크래시 진단을 켜기 전에 그 컨테이너를 먼저 추가해야 한다.
//

import Foundation
import LeeoKit

enum KORASpec: LeeoAppSpec {
    static let appName = "한국 길찾기"
    static let developerEmail = "leeo@kakao.com"

    static let feedback = LeeoFeedbackConfig(
        containerIdentifier: "iCloud.com.Ysoup.FeedbackHub",
        appIdentifier: "com.kora.leeo"
    )

    /// 지원·개인정보 페이지 (README.md). 언어별 페이지는 docs/appstore/README.md 참고.
    static let legal = LeeoLegalConfig(
        privacyURL: URL(string: "https://m1zz.github.io/KORA/privacy.html")!,
        supportURL: URL(string: "https://m1zz.github.io/KORA/support.html")!,
        // 계정을 만들지 않는다.
        createsAccounts: false,
        marketingURL: URL(string: "https://m1zz.github.io/KORA/")
    )

    /// 부분유료: 길찾기는 늘 무료, "안내 탑승"(잠금 화면·안내방송 인식·하차 진동)은
    /// 여정 3회까지 무료, 그 뒤로는 평생 이용권 한 번으로 연다. 구독은 팔지 않는다 —
    /// 며칠 머무는 여행자에게 자동 갱신은 잊힌 결제가 된다. 흐름은 `KORAPro` 참고.
    static let monetization = LeeoMonetization.freemium(
        LeeoPurchaseConfig(
            productIDs: ["com.kora.leeo.pro"],
            gate: LeeoGatePolicy(
                freeLimits: [KORAPro.guidedRideKey: 3],
                warnWhenRemaining: 1)))

    /// 결제 퍼널 이벤트를 Firebase 로.
    static let analytics: any LeeoAnalytics = KORAFirebaseAnalytics()
}
