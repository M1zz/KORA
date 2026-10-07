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

    /// 인앱 결제 없음.
    static let monetization = LeeoMonetization.free
}
