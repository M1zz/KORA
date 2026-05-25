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
}
