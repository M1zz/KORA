//
//  KORAOps.swift
//  KORA
//
//  운영 장치 한 곳 — 원격 킬스위치 · 크래시 루프 가드 · 로그 · 성능 구간.
//

import Foundation
import OSLog
import LeeoKit

// MARK: - 원격 킬스위치

/// 심사 없이 끌 수 있는 기능. CloudKit 대시보드의 `RemoteFlags` 레코드
/// (`flags_com.kora.leeo`)에 같은 이름의 Int64 필드를 0 으로 두면 꺼진다.
/// 조회 실패·필드 없음은 켬이다 — 네트워크가 없다고 안내가 멈추면 안 된다.
enum KORAFlag: String, LeeoRemoteFlag, CaseIterable {
    /// 잠금 화면 라이브 액티비티. 시스템 쪽 문제로 잠금 화면이 꼬이면 끈다.
    case liveActivity
    /// 마이크로 안내방송을 듣고 역을 맞추는 기능. 오인식이 퍼지면 끈다.
    case announcementListening
    /// 서울 열린데이터광장 실시간 도착 API. API 장애·키 문제 때 끈다(시간표 추정으로 물러난다).
    case realtimeArrivals

    var isEnabled: Bool { LeeoRemoteFlags.isEnabled(self) }
}

// MARK: - 크래시 루프 가드

/// 켤 때마다 같은 자리에서 죽으면 다음 실행을 세이프 모드로 연다.
/// 세이프 모드에서는 시작할 때 하는 무거운 일(팁 저장소 열기 · 남은 라이브 액티비티 정리 ·
/// 위치 자동 찾기)을 건너뛰고 빈 첫 화면부터 연다. 무사히 뜨면 다음 실행은 평소대로.
enum KORALaunch {
    static let crashGuard = LeeoCrashLoopGuard(name: "app", defaults: .standard)

    /// 앱 `init()` 에서 한 번. true 면 이번 실행은 세이프 모드다.
    @discardableResult
    static func begin() -> Bool {
        let safe = crashGuard.beginLaunch()
        if safe {
            KORALog.app.error("직전 실행이 연달아 끝나지 못해 세이프 모드로 엽니다")
        }
        return safe
    }

    static var isSafeMode: Bool { crashGuard.isInSafeMode }

    /// 첫 화면이 뜬 뒤. 몇 초 살아 있으면 이번 실행을 성공으로 센다.
    static func firstScreenAppeared() {
        crashGuard.markLaunchSucceededAfterSurvivalDelay()
    }
}

// MARK: - 로그

/// 오류와 중요한 흐름을 통합 로그에 남긴다. 사용자 위치·역 이름 같은 값은 `.private` 로 가린다.
enum KORALog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.kora.leeo"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let route = Logger(subsystem: subsystem, category: "route")
    static let location = Logger(subsystem: subsystem, category: "location")
    static let realtime = Logger(subsystem: subsystem, category: "realtime")
    static let announcement = Logger(subsystem: subsystem, category: "announcement")
    static let liveActivity = Logger(subsystem: subsystem, category: "liveActivity")
}

// MARK: - 성능 구간

/// Instruments ▸ os_signpost 에서 보는 구간. 경로 찾기와 위치 찾기가 얼마나 걸리는지 잰다.
enum KORASignpost {
    static let route = OSSignposter(subsystem: Bundle.main.bundleIdentifier ?? "com.kora.leeo",
                                    category: "route")
    static let location = OSSignposter(subsystem: Bundle.main.bundleIdentifier ?? "com.kora.leeo",
                                       category: "location")
}
