//
//  RideSnapshot.swift
//  아이폰 · 워치 · 워치 컴플리케이션이 함께 쓰는 '지금 타고 있는 열차' 한 장.
//
//  아이폰이 탑승할 때, 정거장이 바뀔 때, 내릴 때 이 한 장을 워치로 보낸다.
//  역 이름과 문구는 아이폰에서 앱 안 언어로 이미 바뀐 채 온다(라이브 액티비티와 같은 규칙).
//  위치는 '어느 역에 언제 있었나'(index · at)와 역 사이 시간(secondsPerStop)으로 담는다 —
//  아이폰이 주머니에서 잠들어 더 보내지 못해도 워치가 혼자 세고, 혼자 하차 진동을 울린다.
//

import Foundation

struct RideSnapshot: Codable, Equatable {
    /// 이번 열차 한 번의 이름. 하차 알림 identifier 로 쓴다 — 같은 열차에서 두 번 울리지 않게.
    var id: String
    var line: String                // "2호선" · "Line 2"
    var lineColorHex: String        // "#00A84D"
    /// 이번 열차가 서는 역, 탄 역 → 내릴 역 (화면 언어로)
    var stations: [String]
    /// `at` 에 열차가 서 있던 역 — stations 의 칸 번호
    var index: Int
    var at: Date
    var secondsPerStop: Int
    /// 내릴 역에서 갈아타는가(아니면 목적지)
    var transfers: Bool
    /// 하차 진동을 울릴까 (아이폰의 하차 진동과 같은 조건 — 안내 탑승일 때만)
    var vibrate: Bool
    /// 숫자 뒤에 붙는 말, 남은 정거장 수마다 ("정거장" · "stop"/"stops" · "станции"/"станций")
    var stopsUnits: [String]
    var labels: Labels

    /// 화면 문구 — 아이폰이 앱 안 언어로 골라 보낸다.
    struct Labels: Codable, Equatable {
        var getOffAt: String        // "내릴 역"
        var nextStation: String     // "다음역"
        var nextStopGetOff: String  // "다음 정거장에서 내리세요"
        var getOffNow: String       // "지금 내리세요!"
        var transfer: String        // "환승"
    }

    var alightStation: String { stations.last ?? "" }

    func stopsUnit(_ n: Int) -> String {
        stopsUnits.indices.contains(n) ? stopsUnits[n] : stopsUnits.last ?? ""
    }
    private var lastIndex: Int { max(stations.count - 1, 0) }
    private var step: TimeInterval { TimeInterval(max(secondsPerStop, 30)) }

    /// 그 시각에 열차가 있을 역 — 아이폰이 마지막으로 알려 준 역에서 시간으로 앞으로 센다.
    func index(at date: Date) -> Int {
        let ahead = max(Int(date.timeIntervalSince(at) / step), 0)
        return min(index + ahead, lastIndex)
    }

    func stopsLeft(at date: Date) -> Int { lastIndex - index(at: date) }

    func nextStation(at date: Date) -> String? {
        let i = index(at: date) + 1
        return i <= lastIndex ? stations[i] : nil
    }

    /// 그 칸 번호의 역에 닿는 시각
    func arrival(atIndex i: Int) -> Date {
        at.addingTimeInterval(Double(max(i - index, 0)) * step)
    }

    /// 한 정거장 남는 순간 — 하차 진동을 울릴 때
    var alertDate: Date { arrival(atIndex: max(lastIndex - 1, index)) }

    /// 내릴 역에 닿고 한참 지나면 이 장은 끝난 것으로 본다(아이폰이 '내림' 을 못 보낸 채 멀어진 경우).
    var expiresAt: Date { arrival(atIndex: lastIndex).addingTimeInterval(15 * 60) }
}

// MARK: - 주고받는 말 · 손목에 남겨 두는 장

enum RideLink {
    /// 아이폰 → 워치: 지금 열차 (JSON). 내리면 빈 Data.
    static let snapshotKey = "ride"
    /// 워치 앱과 컴플리케이션이 함께 여는 저장소
    static let group = "group.com.kora.leeo"

    static func encode(_ ride: RideSnapshot?) -> Data {
        guard let ride else { return Data() }
        return (try? JSONEncoder().encode(ride)) ?? Data()
    }

    static func decode(_ data: Data?) -> RideSnapshot? {
        guard let data, !data.isEmpty else { return nil }
        return try? JSONDecoder().decode(RideSnapshot.self, from: data)
    }

    private static var defaults: UserDefaults { UserDefaults(suiteName: group) ?? .standard }

    /// 마지막으로 받은 열차. 내릴 역을 한참 지났으면 버린다.
    static func load() -> RideSnapshot? {
        guard let ride = decode(defaults.data(forKey: snapshotKey)), ride.expiresAt > .now else { return nil }
        return ride
    }

    static func save(_ ride: RideSnapshot?) {
        defaults.set(encode(ride), forKey: snapshotKey)
    }
}

// MARK: - 노선 색

import SwiftUI

extension RideSnapshot {
    /// 노선 색 ("#00A84D"). 읽지 못하면 nil.
    var lineColor: Color? {
        let hex = lineColorHex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard hex.count == 6, let v = UInt32(hex, radix: 16) else { return nil }
        return Color(red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255,
                     blue: Double(v & 0xFF) / 255)
    }
}
