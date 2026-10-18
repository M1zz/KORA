//
//  KORASpec.swift
//  KORA
//
//  LeeoKit 계약(LeeoAppSpec) 준수 — 이 앱의 공통 기능 설정값 단일 소스.
//
//  피드백 허브(iCloud.com.Ysoup.FeedbackHub)는 KORA.entitlements 에 있다.
//  크래시 진단·사용 통계·피드백이 모두 이 컨테이너로 간다.
//

import Foundation
import LeeoKit

enum KORASpec: LeeoAppSpec {
    static let appName = "KORA"
    static let developerEmail = "leeo@kakao.com"
    /// 설정의 "리뷰 남기기" 가 작성 페이지로 바로 가도록 (itunes lookup com.kora.leeo).
    static let appStoreID: String? = "6775176578"

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

    /// 결제 퍼널 이벤트를 피드백 허브(CloudKit)로. no-op 으로 두면 LeeoKit 이 사용 통계 보고도 끈다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: KORASpec.self)
}
