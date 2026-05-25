import SwiftUI

// MARK: - Data Models

struct MetroRoute: Identifiable {
    let id = UUID()
    let label: String
    let stations: [String]
    let isCircular: Bool

    var terminusA: String { stations.first ?? "" }
    var terminusB: String { stations.last ?? "" }
}

struct SeoulMetroLineInfo: Identifiable {
    let id = UUID()
    let number: Int
    let name: String
    let color: Color
    let routes: [MetroRoute]
}

// MARK: - Station Data

enum MetroLineData {
    static let seoulLines: [SeoulMetroLineInfo] = [
        line1, line2, line3, line4, line5, line6, line7, line8, line9
    ]

    // MARK: Line 1

    private static let line1NorthSection: [String] = [
        "소요산", "동두천", "보산", "동두천중앙", "지행", "덕정", "덕계",
        "양주", "녹양", "가능", "의정부", "회룡", "망월사", "도봉산",
        "도봉", "방학", "창동", "녹천", "월계", "광운대", "석계",
        "신이문", "외대앞", "회기", "청량리", "제기동", "신설동",
        "동묘앞", "동대문", "종각", "서울역", "남영", "용산",
        "노량진", "대방", "신길", "영등포", "신도림", "구로"
    ]

    static let line1 = SeoulMetroLineInfo(
        number: 1, name: "1호선",
        color: Color(red: 0.17, green: 0.46, blue: 0.82),
        routes: [
            MetroRoute(
                label: "소요산↔인천",
                stations: line1NorthSection + [
                    "개봉", "오류동", "온수", "역곡", "소사",
                    "부천", "중동", "송내", "부개", "부평",
                    "백운", "동암", "간석", "주안", "도화",
                    "제물포", "도원", "동인천", "인천"
                ],
                isCircular: false
            ),
            MetroRoute(
                label: "소요산↔신창",
                stations: line1NorthSection + [
                    "구일", "가산디지털단지", "독산", "금천구청",
                    "시흥", "관악", "석수", "명학", "안양",
                    "성결대", "중앙", "군포", "당정", "의왕",
                    "성균관대", "화서", "수원", "세류", "병점",
                    "세마", "오산대", "오산", "진위", "송탄",
                    "서정리", "지제", "평택", "성환", "직산",
                    "두정", "천안", "아산", "배방", "온양온천", "신창"
                ],
                isCircular: false
            ),
            MetroRoute(
                label: "서동탄지선",
                stations: ["병점", "서동탄"],
                isCircular: false
            )
        ]
    )

    // MARK: Line 2

    static let line2 = SeoulMetroLineInfo(
        number: 2, name: "2호선",
        color: Color(red: 0.21, green: 0.72, blue: 0.31),
        routes: [
            MetroRoute(
                label: "순환선",
                stations: [
                    "시청", "을지로입구", "을지로3가", "을지로4가",
                    "동대문역사문화공원", "신당", "상왕십리", "왕십리",
                    "한양대", "뚝섬", "성수", "건대입구", "구의",
                    "강변", "잠실나루", "잠실", "잠실새내", "종합운동장",
                    "삼성", "선릉", "역삼", "강남", "교대", "서초",
                    "방배", "사당", "낙성대", "서울대입구", "봉천",
                    "신림", "신대방", "구로디지털단지", "대림", "신도림",
                    "문래", "영등포구청", "당산", "합정", "홍대입구",
                    "신촌", "이대", "아현", "충정로"
                ],
                isCircular: true
            ),
            MetroRoute(
                label: "성수지선",
                stations: ["성수", "용답", "신답"],
                isCircular: false
            ),
            MetroRoute(
                label: "신정지선",
                stations: ["신도림", "도림천", "양천구청", "신정네거리", "까치산"],
                isCircular: false
            )
        ]
    )

    // MARK: Line 3

    static let line3 = SeoulMetroLineInfo(
        number: 3, name: "3호선",
        color: Color(red: 1.00, green: 0.60, blue: 0.00),
        routes: [
            MetroRoute(
                label: "본선",
                stations: [
                    "대화", "주엽", "정발산", "마두", "백석", "대곡",
                    "화정", "원당", "원흥", "삼송", "지축", "구파발",
                    "연신내", "불광", "녹번", "홍제", "무악재", "독립문",
                    "경복궁", "안국", "종로3가", "을지로3가", "충무로",
                    "동대입구", "약수", "금호", "옥수", "압구정",
                    "신사", "잠원", "고속터미널", "교대", "남부터미널",
                    "양재", "매봉", "도곡", "대치", "학여울", "대청",
                    "일원", "수서", "가락시장", "경찰병원", "오금"
                ],
                isCircular: false
            )
        ]
    )

    // MARK: Line 4

    static let line4 = SeoulMetroLineInfo(
        number: 4, name: "4호선",
        color: Color(red: 0.24, green: 0.64, blue: 0.94),
        routes: [
            MetroRoute(
                label: "본선",
                stations: [
                    "당고개", "상계", "노원", "창동", "쌍문", "수유",
                    "미아", "미아사거리", "길음", "성신여대입구", "한성대입구",
                    "혜화", "동대문", "동대문역사문화공원", "충무로", "명동",
                    "회현", "서울역", "숙대입구", "삼각지", "신용산",
                    "이촌", "동작", "총신대입구", "사당", "남태령",
                    "선바위", "경마공원", "대공원", "과천", "정부과천청사",
                    "인덕원", "평촌", "범계", "금정", "산본", "수리산",
                    "대야미", "반월", "상록수", "한대앞", "중앙",
                    "고잔", "초지", "안산", "신길온천", "정왕", "오이도"
                ],
                isCircular: false
            )
        ]
    )

    // MARK: Line 5

    private static let line5CommonSection: [String] = [
        "방화", "개화산", "김포공항", "송정", "마곡", "발산",
        "우장산", "화곡", "까치산", "신정", "목동", "오목교",
        "양평", "영등포구청", "영등포시장", "신길", "여의도",
        "여의나루", "마포", "공덕", "애오개", "충정로", "서대문",
        "광화문", "종로3가", "을지로4가", "동대문역사문화공원",
        "청구", "신금호", "행당", "왕십리", "마장", "답십리",
        "장한평", "군자", "아차산", "광나루", "천호", "강동"
    ]

    static let line5 = SeoulMetroLineInfo(
        number: 5, name: "5호선",
        color: Color(red: 0.51, green: 0.24, blue: 0.73),
        routes: [
            MetroRoute(
                label: "방화↔마천",
                stations: line5CommonSection + [
                    "길동", "굽은다리", "명일", "고덕", "상일동", "마천"
                ],
                isCircular: false
            ),
            MetroRoute(
                label: "방화↔하남검단산",
                stations: line5CommonSection + [
                    "길동", "굽은다리", "명일", "고덕", "상일동",
                    "미사", "하남풍산", "하남시청", "하남검단산"
                ],
                isCircular: false
            )
        ]
    )

    // MARK: Line 6

    static let line6 = SeoulMetroLineInfo(
        number: 6, name: "6호선",
        color: Color(red: 0.77, green: 0.40, blue: 0.15),
        routes: [
            MetroRoute(
                label: "본선",
                stations: [
                    "신내", "봉화산", "화랑대", "태릉입구", "석계",
                    "돌곶이", "상월곡", "월곡", "고려대", "안암",
                    "보문", "창신", "동묘앞", "신당", "청구", "약수",
                    "버티고개", "한강진", "이태원", "녹사평", "삼각지",
                    "효창공원앞", "공덕", "대흥", "광흥창", "상수",
                    "합정", "망원", "마포구청", "월드컵경기장",
                    "디지털미디어시티", "수색", "증산", "새절", "응암"
                ],
                isCircular: false
            )
        ]
    )

    // MARK: Line 7

    static let line7 = SeoulMetroLineInfo(
        number: 7, name: "7호선",
        color: Color(red: 0.40, green: 0.55, blue: 0.22),
        routes: [
            MetroRoute(
                label: "본선",
                stations: [
                    "장암", "도봉산", "수락산", "마들", "노원",
                    "중계", "하계", "공릉", "태릉입구", "먹골",
                    "중화", "상봉", "면목", "사가정", "용마산",
                    "중곡", "군자", "어린이대공원", "건대입구",
                    "뚝섬유원지", "청담", "강남구청", "학동", "논현",
                    "반포", "고속터미널", "내방", "이수", "남성",
                    "숭실대입구", "상도", "장승배기", "신대방삼거리",
                    "보라매", "신풍", "대림", "남구로", "가산디지털단지",
                    "철산", "광명사거리", "천왕", "온수", "까치울",
                    "부천종합운동장", "춘의", "부천시청", "상동",
                    "삼산체육관", "굴포천", "부평구청"
                ],
                isCircular: false
            )
        ]
    )

    // MARK: Line 8

    static let line8 = SeoulMetroLineInfo(
        number: 8, name: "8호선",
        color: Color(red: 0.87, green: 0.13, blue: 0.42),
        routes: [
            MetroRoute(
                label: "본선",
                stations: [
                    "별내", "별내별가람", "다산", "동구릉", "구리",
                    "암사", "천호", "강동구청", "몽촌토성", "잠실",
                    "석촌", "송파", "가락시장", "문정", "장지",
                    "복정", "산성", "남한산성입구", "단대오거리",
                    "신흥", "수진", "모란"
                ],
                isCircular: false
            )
        ]
    )

    // MARK: Line 9

    static let line9 = SeoulMetroLineInfo(
        number: 9, name: "9호선",
        color: Color(red: 0.80, green: 0.67, blue: 0.20),
        routes: [
            MetroRoute(
                label: "본선",
                stations: [
                    "개화", "김포공항", "공항시장", "신방화", "마곡나루",
                    "양천향교", "가양", "증미", "등촌", "염창",
                    "신목동", "선유도", "당산", "국회의사당", "여의도",
                    "샛강", "노량진", "노들", "흑석", "동작",
                    "구반포", "신반포", "고속터미널", "사평", "신논현",
                    "언주", "선정릉", "삼성중앙", "봉은사", "종합운동장",
                    "삼전", "석촌고분", "석촌", "송파나루", "한성백제",
                    "올림픽공원", "둔촌오륜", "중앙보훈병원"
                ],
                isCircular: false
            )
        ]
    )

    // MARK: - Transfer Stations

    static let stationTransferLines: [String: [Int]] = [
        // Line 1 transfers
        "시청": [1, 2],
        "신도림": [1, 2],
        "동대문": [1, 4],
        "서울역": [1, 4],
        "창동": [1, 4],
        "금정": [1, 4],
        "석계": [1, 6],
        "도봉산": [1, 7],
        "가산디지털단지": [1, 7],
        "온수": [1, 7],
        "노량진": [1, 9],
        // Line 2 transfers
        "을지로3가": [2, 3],
        "교대": [2, 3],
        "동대문역사문화공원": [2, 4, 5],
        "사당": [2, 4],
        "을지로4가": [2, 5],
        "왕십리": [2, 5],
        "영등포구청": [2, 5],
        "충정로": [2, 5],
        "신당": [2, 6],
        "합정": [2, 6],
        "건대입구": [2, 7],
        "대림": [2, 7],
        "잠실": [2, 8],
        "당산": [2, 9],
        "종합운동장": [2, 9],
        "삼성": [2, 9],
        // Line 3 transfers
        "충무로": [3, 4],
        "약수": [3, 6],
        "고속터미널": [3, 7, 9],
        "가락시장": [3, 8],
        // Line 4 transfers
        "삼각지": [4, 6],
        "노원": [4, 7],
        "총신대입구": [4, 7],
        "이수": [4, 7],
        "동작": [4, 9],
        // Line 5 transfers
        "공덕": [5, 6],
        "청구": [5, 6],
        "군자": [5, 7],
        "천호": [5, 8],
        "여의도": [5, 9],
        // Line 6 transfers
        "태릉입구": [6, 7],
        // Line 8 transfers
        "석촌": [8, 9],
    ]

    static func lineColor(_ number: Int) -> Color {
        seoulLines.first(where: { $0.number == number })?.color ?? .gray
    }

    static func transferBadges(for station: String, excluding lineNumber: Int) -> [(number: Int, color: Color)] {
        guard let lines = stationTransferLines[station] else { return [] }
        return lines
            .filter { $0 != lineNumber }
            .map { (number: $0, color: lineColor($0)) }
    }

    // MARK: - Transfer walking time

    /// Approximate platform-to-platform walking time at a transfer station, in minutes.
    /// Curated from publicly known walk times — large interchange hubs are heavier.
    /// Default 3 min when no entry exists.
    static func transferWalkingMinutes(at station: String) -> Int {
        transferWalkTimeTable[station] ?? 3
    }

    private static let transferWalkTimeTable: [String: Int] = [
        // Heavy hubs
        "서울역":              6,
        "동대문역사문화공원":  5,
        "고속터미널":          6,
        "사당":                5,
        "왕십리":              5,
        "신도림":              4,
        "충무로":              4,
        "종로3가":             4,
        "을지로3가":           3,
        "을지로4가":           3,
        "잠실":                4,
        "건대입구":            3,
        "교대":                3,
        "강남":                3,   // 신분당↔2 (실내 환승)
        "삼성":                3,
        "선릉":                3,
        "여의도":              4,
        "공덕":                4,
        "동대문":              3,
        "시청":                2,
        "합정":                3,
        "당산":                3,
        "노원":                3,
        "이수":                3,
        "총신대입구":          3,
        "삼각지":              3,
        "약수":                3,
        "청구":                3,
        "신당":                3,
        "군자":                3,
        "천호":                3,
        "석촌":                3,
        "가락시장":            3,
        "동작":                4,
        "도봉산":              3,
        "온수":                3,
        "가산디지털단지":      4,
        "노량진":              3,
        "대림":                3,
        "영등포구청":          3,
        "충정로":              3,
        "회기":                3,
        "태릉입구":            3,
        "종합운동장":          3,
        "창동":                3,
        "금정":                4
    ]

    // MARK: - Train schedule (last/first)

    /// Approximate last-train departure time at terminal stations (24h clock,
    /// minutes since midnight; values past midnight use +24h so 01:00 = 1500).
    /// Used to surface a "막차 임박" banner — not a precise per-station table.
    static func lastTrainMinutesPastMidnight(for line: Int) -> Int {
        switch line {
        case 1...9: return 60      // 翌01:00
        default:    return 30      // safer default
        }
    }

    /// Current local minute-of-day mapped to the same +24h scheme so we can
    /// compare against lastTrainMinutesPastMidnight directly.
    static func currentMinutesPastMidnight(now: Date = Date()) -> Int {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.hour, .minute], from: now)
        let m = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        // After midnight but before 04:00, treat as previous day's late night
        // so the "last train" comparison stays monotonic.
        if (comps.hour ?? 0) < 4 { return m + 24 * 60 }
        return m
    }

    // MARK: - Navigator Helpers

    static var allStationNames: [String] {
        var seen = Set<String>()
        var names: [String] = []
        for line in seoulLines {
            for route in line.routes {
                for s in route.stations where seen.insert(s).inserted {
                    names.append(s)
                }
            }
        }
        // Sort by katakana reading (アイウエオ order) since that's the displayed primary name.
        return names.sorted { a, b in
            displayName(for: a, language: .japanese)
                < displayName(for: b, language: .japanese)
        }
    }

    static func findJourneys(from: String, to: String) -> [JourneyResult] {
        var results: [JourneyResult] = []
        for line in seoulLines {
            for route in line.routes {
                guard let fi = route.stations.firstIndex(of: from),
                      let ti = route.stations.firstIndex(of: to),
                      fi != ti else { continue }
                let reversed = ti < fi
                let slice = reversed
                    ? Array(route.stations[ti...fi].reversed())
                    : Array(route.stations[fi...ti])
                let terminus = reversed ? route.terminusA : route.terminusB
                results.append(JourneyResult(line: line, route: route, stations: slice, terminus: terminus))
            }
        }
        return results
    }

    // MARK: - Transfer Routing

    /// All lines that serve a given station (deduped).
    static func linesContaining(_ station: String) -> [Int] {
        var result: [Int] = []
        for line in seoulLines where !result.contains(line.number) {
            if line.routes.contains(where: { $0.stations.contains(station) }) {
                result.append(line.number)
            }
        }
        return result
    }

    /// Transfer stations that exist on both given lines.
    static func transferStations(between a: Int, and b: Int) -> [String] {
        guard a != b else { return [] }
        return stationTransferLines.compactMap { (station, lines) in
            (lines.contains(a) && lines.contains(b)) ? station : nil
        }
    }

    /// Find a single-line segment between two stations on a specific line.
    /// Returns the shortest variant when multiple routes contain both.
    /// Correctly handles circular routes (e.g. Line 2) by trying both
    /// wrap-around directions and picking the shorter.
    static func findSegment(from: String, to: String, lineNumber: Int) -> JourneySegment? {
        guard from != to,
              let line = seoulLines.first(where: { $0.number == lineNumber }) else { return nil }

        var best: JourneySegment? = nil
        for route in line.routes {
            guard let fi = route.stations.firstIndex(of: from),
                  let ti = route.stations.firstIndex(of: to),
                  fi != ti else { continue }

            let candidates: [JourneySegment]
            if route.isCircular {
                let count = route.stations.count
                let forwardLen = (ti - fi + count) % count
                let backwardLen = count - forwardLen

                let forwardSlice = buildCircularSlice(route.stations, from: fi, to: ti, forward: true)
                let backwardSlice = buildCircularSlice(route.stations, from: fi, to: ti, forward: false)

                // For circular trains the "terminus" sign typically displays the next
                // major arrival station — use the destination station itself as that
                // proxy so the user can match it to in-car signage.
                let forwardSeg = JourneySegment(
                    line: line,
                    stations: forwardSlice,
                    terminus: forwardSlice.last ?? route.terminusA
                )
                let backwardSeg = JourneySegment(
                    line: line,
                    stations: backwardSlice,
                    terminus: backwardSlice.last ?? route.terminusB
                )
                candidates = forwardLen <= backwardLen
                    ? [forwardSeg, backwardSeg]
                    : [backwardSeg, forwardSeg]
            } else {
                let reversed = ti < fi
                let slice = reversed
                    ? Array(route.stations[ti...fi].reversed())
                    : Array(route.stations[fi...ti])
                let terminus = reversed ? route.terminusA : route.terminusB
                candidates = [JourneySegment(line: line, stations: slice, terminus: terminus)]
            }

            for segment in candidates {
                if best == nil || segment.stations.count < best!.stations.count {
                    best = segment
                }
            }
        }
        return best
    }

    /// Walks the (circular) `stations` array from `start` to `end`,
    /// going forward (increasing index, wrap to 0) or backward.
    private static func buildCircularSlice(_ stations: [String], from start: Int, to end: Int, forward: Bool) -> [String] {
        var result: [String] = []
        let count = stations.count
        var i = start
        while true {
            result.append(stations[i])
            if i == end { break }
            i = forward ? (i + 1) % count : (i - 1 + count) % count
        }
        return result
    }

    /// Find direct + 1-transfer (+ 2-transfer fallback) journeys.
    /// Returns the best few options sorted by (transfers ↑, total stops ↑).
    static func findAnyJourneys(from: String, to: String) -> [TransferJourney] {
        guard from != to else { return [] }

        // 0-transfer (direct)
        let direct = findJourneys(from: from, to: to).map { d in
            TransferJourney(segments: [
                JourneySegment(line: d.line, stations: d.stations, terminus: d.terminus)
            ])
        }
        if !direct.isEmpty {
            return Array(direct.prefix(4))
        }

        let fromLines = linesContaining(from)
        let toLines = linesContaining(to)
        var results: [TransferJourney] = []
        var seen = Set<String>()

        // 1-transfer
        for fL in fromLines {
            for tL in toLines where tL != fL {
                for ts in transferStations(between: fL, and: tL) where ts != from && ts != to {
                    guard let s1 = findSegment(from: from, to: ts, lineNumber: fL),
                          let s2 = findSegment(from: ts, to: to, lineNumber: tL) else { continue }
                    let sig = "\(fL)|\(ts)|\(tL)"
                    if seen.insert(sig).inserted {
                        results.append(TransferJourney(segments: [s1, s2]))
                    }
                }
            }
        }

        // 2-transfer fallback (only if no 1-transfer path exists)
        if results.isEmpty {
            for fL in fromLines {
                for tL in toLines where tL != fL {
                    for mid in seoulLines where mid.number != fL && mid.number != tL {
                        let mL = mid.number
                        let firstHops = transferStations(between: fL, and: mL)
                        let secondHops = transferStations(between: mL, and: tL)
                        guard !firstHops.isEmpty, !secondHops.isEmpty else { continue }

                        for t1 in firstHops where t1 != from && t1 != to {
                            for t2 in secondHops where t2 != from && t2 != to && t2 != t1 {
                                guard let s1 = findSegment(from: from, to: t1, lineNumber: fL),
                                      let s2 = findSegment(from: t1, to: t2, lineNumber: mL),
                                      let s3 = findSegment(from: t2, to: to, lineNumber: tL) else { continue }
                                let sig = "\(fL)|\(t1)|\(mL)|\(t2)|\(tL)"
                                if seen.insert(sig).inserted {
                                    results.append(TransferJourney(segments: [s1, s2, s3]))
                                }
                            }
                        }
                    }
                }
            }
        }

        let sorted = results.sorted { a, b in
            if a.transferCount != b.transferCount { return a.transferCount < b.transferCount }
            return a.totalStops < b.totalStops
        }
        return Array(sorted.prefix(4))
    }
}

// MARK: - Journey Model

struct JourneyResult {
    let line: SeoulMetroLineInfo
    let route: MetroRoute
    let stations: [String]   // Korean names, from→to direction
    let terminus: String     // Korean terminus (matches in-train/platform display)
}

/// One single-line leg within a (possibly multi-line) journey.
struct JourneySegment: Identifiable {
    let id = UUID()
    let line: SeoulMetroLineInfo
    let stations: [String]   // [boarding, ..., disembark/transfer]
    let terminus: String
    var stopCount: Int { max(stations.count - 1, 0) }
}

/// A complete journey, possibly with transfers. `segments.count == 1` is a direct route.
struct TransferJourney: Identifiable {
    let id = UUID()
    let segments: [JourneySegment]

    var transferCount: Int { max(segments.count - 1, 0) }
    var totalStops: Int { segments.reduce(0) { $0 + $1.stopCount } }
    var isDirect: Bool { segments.count == 1 }

    /// Short label like "2号線 → 1号線" used in the alternative-route picker.
    var lineSummaryLabel: String {
        segments.map { "\($0.line.number)号線" }.joined(separator: " → ")
    }
}
