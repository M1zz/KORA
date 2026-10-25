//
//  KORATests.swift
//  KORATests
//
//  핵심 로직 시험 — 길찾기 · 막차 시각 표기 · 새로 생긴 것/사용법 안내 노출 규칙 · LeeoKit 계약 · 명소 → 역.
//

import XCTest
import LeeoKit
import TrainBoardKit
import CoreLocation
@testable import KORA

final class KORASpecTests: XCTestCase {
    /// 부트스트랩의 DEBUG 감사와 별개로, 계약이 배포 가능한 상태인지 시험이 지킨다.
    func testPreflightIsReleasable() {
        let report = LeeoPreflight.audit(KORASpec.self)
        XCTAssertTrue(report.isReleasable, "\(report)")
    }

    func testRemoteFlagNamesAreUnique() {
        let names = KORAFlag.allCases.map(\.rawValue)
        XCTAssertEqual(Set(names).count, names.count)
    }
}

final class RouteFindingTests: XCTestCase {
    func testDirectRouteOnOneLine() throws {
        // 2호선 한 줄: 홍대입구 → 강남
        let journeys = MetroLineData.findAnyJourneys(from: "홍대입구", to: "강남")
        let first = try XCTUnwrap(journeys.first)
        XCTAssertEqual(first.segments.first?.stations.first, "홍대입구")
        XCTAssertEqual(first.segments.last?.stations.last, "강남")
    }

    func testRouteWithTransferEndsAtDestination() throws {
        // 갈아타야 하는 길: 김포공항 → 명동
        let journeys = MetroLineData.findAnyJourneys(from: "김포공항", to: "명동")
        XCTAssertFalse(journeys.isEmpty)
        for j in journeys {
            XCTAssertEqual(j.segments.first?.stations.first, "김포공항")
            XCTAssertEqual(j.segments.last?.stations.last, "명동")
            // 구간이 이어진다 — 앞 구간의 내린 역이 다음 구간의 탄 역.
            for (a, b) in zip(j.segments, j.segments.dropFirst()) {
                XCTAssertEqual(a.stations.last, b.stations.first)
            }
        }
    }

    func testSameStationHasNoRoute() {
        XCTAssertTrue(MetroLineData.findAnyJourneys(from: "서울역", to: "서울역").isEmpty)
    }
}

final class LastTrainClockTests: XCTestCase {
    /// 서울 0시 46분 — 언어마다 그 나라 시각 표기로.
    private var deadline: LastTrainService.Deadline {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Seoul")!
        let date = c.date(from: DateComponents(year: 2026, month: 10, day: 18, hour: 0, minute: 46))!
        return LastTrainService.Deadline(station: "강남", date: date)
    }

    func testEnglishUsesTwelveHourClock() {
        let s = deadline.clock(.english)
        XCTAssertTrue(s.contains("12:46"), s)
        XCTAssertTrue(s.contains("AM"), s)
    }

    func testGermanUsesTwentyFourHourClock() {
        let s = deadline.clock(.german)
        XCTAssertTrue(s.hasSuffix("0:46"), s)
        XCTAssertFalse(s.contains("AM") || s.contains("12:46"), s)
    }

    func testClockIsSeoulTimeWhateverTheDeviceZone() {
        // 기기 시간대와 관계없이 서울 시각이어야 한다(여행자 폰이 고향 시간대여도).
        XCTAssertTrue(deadline.clock(.korean).contains("12:46") || deadline.clock(.korean).contains("0:46"),
                      deadline.clock(.korean))
    }
}

final class FirstRunTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "KORATests.firstRun"

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: suite)
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suite)
        super.tearDown()
    }

    private let notes: [String: [KORAWhatsNew.Item]] = [
        "2.0.0": [KORAWhatsNew.Item(symbol: "star", text: .whatsNew1)],
    ]

    func testFirstInstallDoesNotShowWhatsNew() {
        XCTAssertFalse(KORAWhatsNew.shouldPresent(isFirstLaunch: true, defaults: defaults,
                                                  version: "2.0.0", notes: notes))
        // 같은 버전으로 다시 열어도 뜨지 않는다.
        XCTAssertFalse(KORAWhatsNew.shouldPresent(isFirstLaunch: false, defaults: defaults,
                                                  version: "2.0.0", notes: notes))
    }

    func testUpdateShowsOnceUntilSeen() {
        defaults.set("1.9.0", forKey: KORAWhatsNew.lastSeenKey)
        XCTAssertTrue(KORAWhatsNew.shouldPresent(isFirstLaunch: false, defaults: defaults,
                                                 version: "2.0.0", notes: notes))
        KORAWhatsNew.markSeen(defaults: defaults, version: "2.0.0")
        XCTAssertFalse(KORAWhatsNew.shouldPresent(isFirstLaunch: false, defaults: defaults,
                                                  version: "2.0.0", notes: notes))
    }

    func testVersionWithoutNotesShowsNothing() {
        defaults.set("1.9.0", forKey: KORAWhatsNew.lastSeenKey)
        XCTAssertFalse(KORAWhatsNew.shouldPresent(isFirstLaunch: false, defaults: defaults,
                                                  version: "2.0.1", notes: notes))
    }

    func testExistingUsersSkipOnboarding() {
        KORAOnboarding.markDoneForExistingUsers(launchCount: 5, defaults: defaults)
        XCTAssertTrue(defaults.bool(forKey: KORAOnboarding.completedKey))
    }

    func testNewUsersStillSeeOnboarding() {
        KORAOnboarding.markDoneForExistingUsers(launchCount: 1, defaults: defaults)
        XCTAssertNil(defaults.object(forKey: KORAOnboarding.completedKey))
    }
}

final class TrainBoardJudgeTests: XCTestCase {
    /// 9호선: 신논현 → 노량진 (서쪽, 김포공항·개화 방향). 둘 다 급행역.
    private func judge(from boarding: String, to destination: String) -> TrainBoardJudge {
        let stations = MetroLineData.line9.routes[0].stations
        let bi = stations.firstIndex(of: boarding)!, di = stations.firstIndex(of: destination)!
        let forward = di < bi ? Set(stations[...di]) : Set(stations[di...])
        let backward = Set(stations).subtracting(forward).subtracting([boarding])
        return TrainBoardJudge(forward: forward, backward: backward,
                               boarding: boarding, destination: destination,
                               services: [MetroLineData.line9Express])
    }

    func testLocalTrainBoardsAnywhere() {
        let j = judge(from: "신논현", to: "흑석")
        XCTAssertEqual(j.judge(row: "일반 개화행"), .board(matched: "개화"))
    }

    func testExpressBetweenExpressStopsBoards() {
        let j = judge(from: "신논현", to: "노량진")
        XCTAssertEqual(j.judge(row: "급행 김포공항"), .board(matched: "김포공항"))
    }

    func testExpressSkippingDestinationIsCaught() {
        // 흑석은 급행이 서지 않는다.
        let j = judge(from: "신논현", to: "흑석")
        XCTAssertEqual(j.judge(row: "급행 김포공항행"), .skipsStop(serviceWord: "급행", station: "흑석"))
    }

    func testExpressSkippingBoardingIsCaught() {
        let j = judge(from: "언주", to: "노량진")
        XCTAssertEqual(j.judge(row: "급행 김포공항"), .skipsStop(serviceWord: "급행", station: "언주"))
    }

    func testWrongDirectionStaysWrongEvenForExpress() {
        let j = judge(from: "신논현", to: "흑석")
        XCTAssertEqual(j.judge(row: "급행 중앙보훈병원"), .wrongDirection(matched: "중앙보훈병원"))
    }

    func testExpressBusTerminalIsNotAnExpressTrain() {
        // 고속터미널의 영어 이름에 Express 가 들어 있어도 급행으로 보지 않는다.
        let j = judge(from: "신논현", to: "흑석")
        XCTAssertEqual(j.judge(row: "Express Bus Terminal 고속터미널 개화"), .board(matched: "개화"))
    }

    func testTopRowOfTheBoardDecides() {
        // 전광판 첫 줄이 다음 열차다. 첫 줄 급행(흑석 통과), 둘째 줄 일반.
        let boxes: [TrainBoardJudge.TextBox] = [
            .init(text: "일반", minY: 0.40, maxY: 0.50, minX: 0.1),
            .init(text: "김포공항", minY: 0.41, maxY: 0.49, minX: 0.3),
            .init(text: "김포공항", minY: 0.61, maxY: 0.69, minX: 0.3),
            .init(text: "급행", minY: 0.60, maxY: 0.70, minX: 0.1),
        ]
        let rows = TrainBoardJudge.rows(from: boxes)
        XCTAssertEqual(rows, ["급행 김포공항", "일반 김포공항"])
        let j = judge(from: "신논현", to: "흑석")
        XCTAssertEqual(j.judge(rows: rows), .skipsStop(serviceWord: "급행", station: "흑석"))
        XCTAssertEqual(j.judge(rows: Array(rows.dropFirst())), .board(matched: "김포공항"))
    }

    func testStationSignNamingBothNeighboursIsAmbiguous() {
        let j = TrainBoardJudge(forward: ["개화"], backward: ["언주", "중앙보훈병원"], nextStop: ["사평"])
        XCTAssertEqual(j.judge(row: "← 사평 | 신논현 | 언주 →"), .ambiguous)
    }
}

final class AttractionDataTests: XCTestCase {
    private let all = KORAAttractions.all

    func testDataLoads() {
        XCTAssertGreaterThanOrEqual(all.count, 60)
        let ids = all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "id 가 겹친다")
    }

    func testEveryStationExistsInLineData() {
        let names = Set(MetroLineData.allStationNames)
        for a in all {
            XCTAssertFalse(a.stations.isEmpty, a.id)
            for s in a.stations {
                XCTAssertTrue(names.contains(s.station), "\(a.id): 노선 데이터에 없는 역 \(s.station)")
                XCTAssertNotNil(MetroLineData.stationCoordinates[s.station], "\(a.id): 좌표 없는 역 \(s.station)")
            }
        }
    }

    func testStationsBelongToTheAttractionsRegion() {
        for a in all {
            for s in a.stations {
                let regions = Set(MetroLineData.linesContaining(s.station).compactMap { num in
                    MetroLineData.seoulLines.first { $0.number == num }?.region
                })
                XCTAssertTrue(regions.contains(a.region.region), "\(a.id): \(s.station) 은 다른 권역")
            }
        }
    }

    func testCoordinatesAreInKoreaAndNearTheirStations() {
        for a in all {
            XCTAssertTrue((33.0...38.7).contains(a.lat) && (124.5...131.0).contains(a.lng), "\(a.id): 한국 밖 좌표")
            for s in a.stations {
                guard let c = MetroLineData.stationCoordinates[s.station] else { continue }
                // 태종대·해동용궁사처럼 역에서 버스를 타는 곳도 있어 넉넉하게. 위도·경도를 바꿔 적은 실수는 잡는다.
                XCTAssertLessThan(meters(a.lat, a.lng, c.lat, c.lng), 8000, "\(a.id): \(s.station) 에서 너무 멀다")
            }
        }
    }

    func testNamesAndExits() {
        let exitPattern = try? NSRegularExpression(pattern: "^[0-9]+(-[0-9]+)?$")
        for a in all {
            for key in ["ko", "ja", "en", "zh-Hans", "zh-Hant"] {
                let name = a.name[key] ?? ""
                XCTAssertFalse(name.isEmpty, "\(a.id): \(key) 이름 없음")
                XCTAssertFalse(name.contains("—") || name.contains(" - "), "\(a.id): 엠대시")
            }
            XCTAssertFalse(a.sources.isEmpty, "\(a.id): 출처 없음")
            for s in a.stations {
                for e in s.exits ?? [] {
                    let range = NSRange(e.startIndex..., in: e)
                    XCTAssertNotNil(exitPattern?.firstMatch(in: e, range: range), "\(a.id): 출구 번호 \(e)")
                }
                if let w = s.walk { XCTAssertTrue((1...30).contains(w), "\(a.id): 도보 \(w)분") }
            }
        }
    }

    private func meters(_ lat1: Double, _ lng1: Double, _ lat2: Double, _ lng2: Double) -> Double {
        CLLocation(latitude: lat1, longitude: lng1).distance(from: CLLocation(latitude: lat2, longitude: lng2))
    }
}

final class AttractionSearchTests: XCTestCase {
    func testCoexLeadsToSamseongAndBongeunsa() throws {
        for q in ["코엑스", "COEX", "coex", "コエックス", "별마당도서관"] {
            let coex = try XCTUnwrap(KORAAttractions.search(q).first, q)
            XCTAssertEqual(coex.id, "coex", q)
            let stations = coex.stations.map(\.station)
            XCTAssertTrue(stations.contains("삼성"), q)
            XCTAssertTrue(stations.contains("봉은사"), q)
        }
    }

    func testGyeongbokgungInEveryScript() {
        for q in ["경복궁", "Gyeongbokgung", "gyeongbokgung palace", "景福宮", "景福宫"] {
            XCTAssertTrue(KORAAttractions.search(q).contains { $0.id == "gyeongbokgung" }, q)
        }
    }

    func testIgnoresSpacesAndHyphens() {
        XCTAssertTrue(KORAAttractions.search("N 서울 타워").contains { $0.id == "n-seoul-tower" })
        XCTAssertTrue(KORAAttractions.search("myeong-dong").contains { $0.id == "myeongdong" })
    }

    func testSingleLatinLetterFindsNoPlace() {
        XCTAssertTrue(KORAAttractions.search("a").isEmpty)
        XCTAssertTrue(KORAAttractions.search("  ").isEmpty)
    }

    func testDetailLine() {
        let access = Attraction.Access(station: "삼성", exits: ["5", "6"], walk: 3)
        XCTAssertEqual(AttractionCard.detail(access, .korean), "5·6번 출구 · 도보 약 3분")
        XCTAssertEqual(AttractionCard.detail(access, .english), "Exits 5·6 · About 3 min walk")
        XCTAssertEqual(AttractionCard.detail(Attraction.Access(station: "삼성", exits: ["5"], walk: nil), .japanese), "5番出口")
        XCTAssertNil(AttractionCard.detail(Attraction.Access(station: "삼성", exits: nil, walk: nil), .korean))
    }
}
