import SwiftUI

// MARK: - 수도권 확장 노선
//
// 1~9호선·공항철도·신분당·수인분당·경의중앙(SubwayLineData.swift) 이후에
// 추가된 수도권 노선들. 역명·순서·색상은 각 운영사 공식 자료 기준
// (2026-07 영업 구간, 미개통역 제외).
// 좌표·다국어 표기는 SubwayStationDataExpansion.swift에 있다.

extension MetroLineData {

    static let capitalExpansionLines: [SeoulMetroLineInfo] = [
        line14GTXA, line15Gyeongchun, line16Gyeonggang, line17Seohae,
        line18GimpoGold, line19Sillim, line20UiSinseol,
        line21Uijeongbu, line22Everline, line23Incheon1, line24Incheon2
    ]

    // MARK: Line 14 — GTX-A
    //
    // 삼성역 미개통(2028 예정)으로 운정중앙↔서울역 / 수서↔동탄 두 구간이
    // 분리 운행 중이다. 하나의 노선, 두 개의 독립 route로 모델링한다.

    static let line14GTXA = SeoulMetroLineInfo(
        number: 14, name: "GTX-A", code: "GTX-A",
        color: Color(red: 0.60, green: 0.38, blue: 0.57),   // #9A6292
        routes: [
            MetroRoute(
                label: "운정중앙↔서울역",
                stations: ["운정중앙", "킨텍스", "대곡", "연신내", "서울역"],
                isCircular: false
            ),
            MetroRoute(
                label: "수서↔동탄",
                stations: ["수서", "성남", "구성", "동탄"],
                isCircular: false
            )
        ]
    )

    // MARK: Line 15 — 경춘선

    static let line15Gyeongchun = SeoulMetroLineInfo(
        number: 15, name: "경춘선", code: "경춘",
        color: Color(red: 0.05, green: 0.56, blue: 0.45),   // #0C8E72
        routes: [
            MetroRoute(
                label: "청량리↔춘천",
                stations: [
                    "청량리", "회기", "상봉", "망우", "신내", "갈매",
                    "별내", "퇴계원", "사릉", "금곡", "평내호평", "천마산",
                    "마석", "대성리", "청평", "상천", "가평", "굴봉산",
                    "백양리", "강촌", "김유정", "남춘천", "춘천"
                ],
                isCircular: false,
                // 대부분 상봉 착발, 춘천 방면은 평내호평·마석 단축 운행 존재
                shortTermini: ["상봉", "평내호평", "마석"]
            )
        ]
    )

    // MARK: Line 16 — 경강선

    static let line16Gyeonggang = SeoulMetroLineInfo(
        number: 16, name: "경강선", code: "경강",
        color: Color(red: 0.00, green: 0.33, blue: 0.65),   // #0054A6
        routes: [
            MetroRoute(
                label: "판교↔여주",
                stations: [
                    "판교", "성남", "이매", "삼동", "경기광주", "초월",
                    "곤지암", "신둔도예촌", "이천", "부발", "세종대왕릉", "여주"
                ],
                isCircular: false
            )
        ]
    )

    // MARK: Line 17 — 서해선
    //
    // 일산~대곡 구간은 경의선 선로 공용 (일산·풍산·백마·곡산·대곡·능곡은
    // 경의중앙선과 같은 역 → 환승 자동 파생). 원시 이남(서화성)은
    // 2026-07 기준 미개통.

    static let line17Seohae = SeoulMetroLineInfo(
        number: 17, name: "서해선", code: "서해",
        color: Color(red: 0.56, green: 0.76, blue: 0.12),   // #8FC31F
        routes: [
            MetroRoute(
                label: "일산↔원시",
                stations: [
                    "일산", "풍산", "백마", "곡산", "대곡", "능곡",
                    "김포공항", "원종", "부천종합운동장", "소사", "소새울",
                    "시흥대야", "신천", "신현", "시흥시청", "시흥능곡",
                    "달미", "선부", "초지", "시우", "원시"
                ],
                isCircular: false,
                shortTermini: ["김포공항", "소사"]
            )
        ]
    )

    // MARK: Line 18 — 김포골드라인

    static let line18GimpoGold = SeoulMetroLineInfo(
        number: 18, name: "김포골드라인", code: "김포",
        color: Color(red: 0.68, green: 0.53, blue: 0.02),   // #AD8605
        routes: [
            MetroRoute(
                label: "양촌↔김포공항",
                stations: [
                    "양촌", "구래", "마산", "장기", "운양", "걸포북변",
                    "사우", "풍무", "고촌", "김포공항"
                ],
                isCircular: false
            )
        ]
    )

    // MARK: Line 19 — 신림선

    static let line19Sillim = SeoulMetroLineInfo(
        number: 19, name: "신림선", code: "신림",
        color: Color(red: 0.40, green: 0.54, blue: 0.79),   // #6789CA
        routes: [
            MetroRoute(
                label: "샛강↔관악산",
                stations: [
                    "샛강", "대방", "서울지방병무청", "보라매", "보라매공원",
                    "보라매병원", "당곡", "신림", "서원", "서울대벤처타운",
                    "관악산"
                ],
                isCircular: false
            )
        ]
    )

    // MARK: Line 20 — 우이신설선

    static let line20UiSinseol = SeoulMetroLineInfo(
        number: 20, name: "우이신설선", code: "우이",
        color: Color(red: 0.69, green: 0.81, blue: 0.09),   // #B0CE18
        routes: [
            MetroRoute(
                label: "북한산우이↔신설동",
                stations: [
                    "북한산우이", "솔밭공원", "4·19민주묘지", "가오리",
                    "화계", "삼양", "삼양사거리", "솔샘", "북한산보국문",
                    "정릉", "성신여대입구", "보문", "신설동"
                ],
                isCircular: false
            )
        ]
    )

    // MARK: Line 21 — 의정부경전철

    static let line21Uijeongbu = SeoulMetroLineInfo(
        number: 21, name: "의정부경전철", code: "U",
        color: Color(red: 0.99, green: 0.65, blue: 0.00),   // #FDA600
        routes: [
            MetroRoute(
                label: "발곡↔탑석",
                stations: [
                    "발곡", "회룡", "범골", "경전철의정부", "의정부시청",
                    "흥선", "의정부중앙", "동오", "새말", "경기도청북부청사",
                    "효자", "곤제", "어룡", "송산", "탑석"
                ],
                isCircular: false
            )
        ]
    )

    // MARK: Line 23 — 인천 1호선
    //
    // 검단연장 (검단호수공원·신검단중앙·아라) 2025-06 개통 반영.

    static let line23Incheon1 = SeoulMetroLineInfo(
        number: 23, name: "인천 1호선", code: "인천1",
        color: Color(red: 0.49, green: 0.66, blue: 0.84),   // #7CA8D5
        category: .incheon,
        routes: [
            MetroRoute(
                label: "검단호수공원↔송도달빛축제공원",
                stations: [
                    "검단호수공원", "신검단중앙", "아라", "계양", "귤현",
                    "박촌", "임학", "계산", "경인교대입구", "작전", "갈산",
                    "부평구청", "부평시장", "부평", "동수", "부평삼거리",
                    "간석오거리", "인천시청", "예술회관", "인천터미널",
                    "문학경기장", "선학", "신연수", "원인재", "동춘", "동막",
                    "캠퍼스타운", "테크노파크", "지식정보단지", "인천대입구",
                    "센트럴파크", "국제업무지구", "송도달빛축제공원"
                ],
                isCircular: false,
                shortTermini: ["계양", "동막"]
            )
        ]
    )

    // MARK: Line 24 — 인천 2호선

    static let line24Incheon2 = SeoulMetroLineInfo(
        number: 24, name: "인천 2호선", code: "인천2",
        color: Color(red: 0.93, green: 0.55, blue: 0.00),   // #ED8B00
        category: .incheon,
        routes: [
            MetroRoute(
                label: "검단오류↔운연",
                stations: [
                    "검단오류", "왕길", "검단사거리", "마전", "완정", "독정",
                    "검암", "검바위", "아시아드경기장", "서구청", "가정",
                    "가정중앙시장", "석남", "서부여성회관", "인천가좌",
                    "가재울", "주안국가산단", "주안", "시민공원", "석바위시장",
                    "인천시청", "석천사거리", "모래내시장", "만수", "남동구청",
                    "인천대공원", "운연"
                ],
                isCircular: false
            )
        ]
    )

    // MARK: Line 22 — 용인 에버라인

    static let line22Everline = SeoulMetroLineInfo(
        number: 22, name: "용인에버라인", code: "에버",
        color: Color(red: 0.31, green: 0.62, blue: 0.13),   // #509F22
        routes: [
            MetroRoute(
                label: "기흥↔전대·에버랜드",
                stations: [
                    "기흥", "강남대", "지석", "어정", "동백", "초당",
                    "삼가", "시청·용인대", "명지대", "김량장", "용인중앙시장",
                    "고진", "보평", "둔전", "전대·에버랜드"
                ],
                isCircular: false
            )
        ]
    )
}
