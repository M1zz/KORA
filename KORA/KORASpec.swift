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
        privacyURL: URL(fixed: "https://m1zz.github.io/KORA/privacy.html"),
        supportURL: URL(fixed: "https://m1zz.github.io/KORA/support.html"),
        // 계정을 만들지 않는다.
        createsAccounts: false,
        marketingURL: URL(string: "https://m1zz.github.io/KORA/")
    )

    /// 부분유료: 길찾기는 늘 무료, "안내 탑승"(잠금 화면·안내방송 인식·하차 진동)은
    /// 여정 3회까지 무료, 그 뒤로는 평생 이용권 한 번으로 연다. 구독은 팔지 않는다 —
    /// 며칠 머무는 여행자에게 자동 갱신은 잊힌 결제가 된다. 흐름은 `KORAPro` 참고.
    static let monetization = LeeoMonetization.freemium(
        LeeoPurchaseConfig(
            productIDs: [proProductID],
            gate: LeeoGatePolicy(
                freeLimits: [KORAPro.guidedRideKey: 3],
                warnWhenRemaining: 1),
            // Pro 선물하기. 보내는 사람은 소모성 선물 상품을 사고, 받는 사람은 평생 이용권을 산 것과 같아진다.
            // 선물 기록은 피드백과 같은 허브 컨테이너의 공개 DB 에 둔다. KORA.entitlements 에 이미 있다.
            // ⚠️ 선물 상품은 productIDs · entitlementIDs 에 넣지 않는다. 넣으면 선물을 산 사람이 Pro 가 된다.
            gift: LeeoGiftConfig(
                productID: giftProductID,
                grantsProductID: proProductID,
                containerIdentifier: "iCloud.com.Ysoup.FeedbackHub"),
            // 개발자 응원하기(팁, 소모성). 기능을 열지 않는다 — productIDs · entitlementIDs 에 넣지 않는다.
            tipJar: LeeoTipJarConfig(productIDs: tipProductIDs)))

    /// 평생 이용권(비소모성, 가족 공유). 파는 상품은 이것 하나다.
    static let proProductID = "com.kora.leeo.pro"
    /// Pro 선물(소모성). 몇 번이고 살 수 있고, 산 사람이 아니라 코드를 받은 사람이 Pro 가 된다.
    static let giftProductID = "com.kora.leeo.gift.pro"
    /// 팁(소모성). 작은 것부터 큰 것 순.
    static let tipProductIDs = ["com.kora.leeo.tip.small", "com.kora.leeo.tip.medium", "com.kora.leeo.tip.large"]

    /// 결제 퍼널 이벤트를 피드백 허브(CloudKit)로. no-op 으로 두면 LeeoKit 이 사용 통계 보고도 끈다.
    static let analytics: any LeeoAnalytics = LeeoUsageAnalytics(spec: KORASpec.self)
}
