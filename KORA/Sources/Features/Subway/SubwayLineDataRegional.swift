import SwiftUI

// MARK: - 지방 광역시 도시철도
//
// 부산·대구·광주·대전 권역 노선 (2026-07 영업 구간, 미개통역 제외).
// region 값으로 수도권과 분리되어 권역 간 환승/경로 탐색은 발생하지 않는다.
//
// 동명이역 규칙: 수도권 역과 이름이 겹치면 "역명(권역)"으로 구분한다
// (예: 시청(부산), 용문(대전)). 같은 권역 안에서 이름은 같지만 물리적으로
// 다른 역(부산 1호선 부전 vs 동해선 부전)은 노선명을 붙여 구분한다
// (예: 부전(동해선)) — 이름이 같으면 환승역으로 파생되기 때문.
//
// 좌표·다국어 표기는 SubwayStationDataExpansion.swift에 있다.

extension MetroLineData {

    static let regionalLines: [SeoulMetroLineInfo] = [
        busanLine1, busanLine2, busanLine3, busanLine4,
        busanGimhaeLRT, donghaeLine,
        daeguLine1, daeguLine2, daeguLine3, daegyeongLine,
        gwangjuLine1, daejeonLine1
    ]

    // MARK: - 부산 (31~36)

    static let busanLine1 = SeoulMetroLineInfo(
        number: 31, name: "부산 1호선", code: "부산1",
        color: Color(red: 0.94, green: 0.42, blue: 0.00),   // #F06A00
        region: .busan,
        routes: [
            MetroRoute(
                label: "다대포해수욕장↔노포",
                stations: [
                    "다대포해수욕장", "다대포항", "낫개", "신장림", "장림",
                    "동매", "신평", "하단", "당리", "사하", "괴정", "대티",
                    "서대신", "동대신", "토성", "자갈치", "남포", "중앙(부산)",
                    "부산", "초량", "부산진", "좌천", "범일", "범내골",
                    "서면", "부전", "양정(부산)", "시청(부산)", "연산",
                    "교대(부산)", "동래", "명륜", "온천장", "부산대", "장전",
                    "구서", "두실", "남산(부산)", "범어사", "노포"
                ],
                isCircular: false,
                // 다대포 방면은 신평 착발이 많다
                shortTermini: ["신평"]
            )
        ]
    )

    static let busanLine2 = SeoulMetroLineInfo(
        number: 32, name: "부산 2호선", code: "부산2",
        color: Color(red: 0.51, green: 0.75, blue: 0.28),   // #81BF48
        region: .busan,
        routes: [
            MetroRoute(
                label: "장산↔양산",
                stations: [
                    "장산", "중동(부산)", "해운대", "동백(부산)", "벡스코",
                    "센텀시티", "민락", "수영", "광안", "금련산", "남천",
                    "경성대·부경대", "대연", "못골", "지게골", "문현",
                    "국제금융센터·부산은행", "전포", "서면", "부암", "가야",
                    "동의대", "개금", "냉정", "주례", "감전", "사상", "덕포",
                    "모덕", "모라", "구남", "구명", "덕천", "수정", "화명",
                    "율리", "동원", "금곡(부산)", "호포", "증산(부산)",
                    "부산대양산캠퍼스", "남양산", "양산"
                ],
                isCircular: false,
                // 전포·구명·광안·호포 중간 착발 운행 존재
                shortTermini: ["전포", "구명", "광안", "호포"]
            )
        ]
    )

    static let busanLine3 = SeoulMetroLineInfo(
        number: 33, name: "부산 3호선", code: "부산3",
        color: Color(red: 0.73, green: 0.55, blue: 0.00),   // #BB8C00
        region: .busan,
        routes: [
            MetroRoute(
                label: "수영↔대저",
                stations: [
                    "수영", "망미", "배산", "물만골", "연산", "거제",
                    "종합운동장(부산)", "사직", "미남", "만덕", "남산정",
                    "숙등", "덕천", "구포", "강서구청", "체육공원", "대저"
                ],
                isCircular: false
            )
        ]
    )

    static let busanLine4 = SeoulMetroLineInfo(
        number: 34, name: "부산 4호선", code: "부산4",
        color: Color(red: 0.13, green: 0.49, blue: 0.80),   // #217DCB
        region: .busan,
        routes: [
            MetroRoute(
                label: "미남↔안평",
                stations: [
                    "미남", "동래", "수안", "낙민", "충렬사", "명장",
                    "서동", "금사", "반여농산물시장", "석대", "윤산",
                    "윗반송", "고촌(부산)", "안평"
                ],
                isCircular: false
            )
        ]
    )

    static let busanGimhaeLRT = SeoulMetroLineInfo(
        number: 35, name: "부산김해경전철", code: "김해",
        color: Color(red: 0.53, green: 0.32, blue: 0.63),   // #8652A1
        region: .busan,
        routes: [
            MetroRoute(
                label: "사상↔가야대",
                stations: [
                    "사상", "괘법르네시떼", "서부산유통지구", "공항(부산)",
                    "덕두", "등구", "대저", "평강", "대사", "불암", "지내",
                    "김해대학", "인제대", "김해시청", "부원", "봉황",
                    "수로왕릉", "박물관", "연지공원", "장신대", "가야대"
                ],
                isCircular: false
            )
        ]
    )

    /// 동해선 광역전철 (부전↔태화강). 부전·동래·좌천은 1·4호선의 동명역과
    /// 물리적으로 다른 별개 역이라 노선명을 붙여 구분한다.
    static let donghaeLine = SeoulMetroLineInfo(
        number: 36, name: "동해선", code: "동해",
        color: Color(red: 0.00, green: 0.24, blue: 0.65),   // #003DA5
        region: .busan,
        routes: [
            MetroRoute(
                label: "부전↔태화강",
                stations: [
                    "부전(동해선)", "거제해맞이", "거제", "교대(부산)",
                    "동래(동해선)", "안락", "부산원동", "재송", "센텀",
                    "벡스코", "신해운대", "송정(부산)", "오시리아", "기장",
                    "일광", "좌천(동해선)", "월내", "서생", "남창", "망양",
                    "덕하", "개운포", "태화강"
                ],
                isCircular: false,
                // 전 구간 직통 외에 기장·일광 단축 운행이 많다
                shortTermini: ["기장", "일광"]
            )
        ]
    )

    // MARK: - 대구 (41~44)

    static let daeguLine1 = SeoulMetroLineInfo(
        number: 41, name: "대구 1호선", code: "대구1",
        color: Color(red: 0.85, green: 0.25, blue: 0.36),   // #D93F5C
        region: .daegu,
        routes: [
            MetroRoute(
                label: "설화명곡↔하양",
                stations: [
                    "설화명곡", "화원", "대곡(대구)", "진천", "월배", "상인",
                    "월촌", "송현", "서부정류장", "대명", "안지랑", "현충로",
                    "영대병원", "교대(대구)", "명덕", "반월당", "중앙로(대구)",
                    "대구", "칠성시장", "신천(대구)", "동대구", "동구청",
                    "아양교", "동촌", "해안", "방촌", "용계", "율하", "신기",
                    "반야월", "각산", "안심", "대구한의대병원", "부호", "하양"
                ],
                isCircular: false,
                shortTermini: ["안심"]
            )
        ]
    )

    static let daeguLine2 = SeoulMetroLineInfo(
        number: 42, name: "대구 2호선", code: "대구2",
        color: Color(red: 0.00, green: 0.67, blue: 0.50),   // #00AA80
        region: .daegu,
        routes: [
            MetroRoute(
                label: "문양↔영남대",
                stations: [
                    "문양", "다사", "대실", "강창", "계명대", "성서산업단지",
                    "이곡", "용산(대구)", "죽전(대구)", "감삼", "두류", "내당",
                    "반고개", "청라언덕", "반월당", "경대병원", "대구은행",
                    "범어", "수성구청", "만촌", "담티", "연호", "수성알파시티",
                    "고산", "신매", "사월", "정평", "임당", "영남대"
                ],
                isCircular: false
            )
        ]
    )

    static let daeguLine3 = SeoulMetroLineInfo(
        number: 43, name: "대구 3호선", code: "대구3",
        color: Color(red: 1.00, green: 0.69, blue: 0.00),   // #FFB100
        region: .daegu,
        routes: [
            MetroRoute(
                label: "칠곡경대병원↔용지",
                stations: [
                    "칠곡경대병원", "학정", "팔거", "동천(대구)", "칠곡운암",
                    "구암(대구)", "태전", "매천", "매천시장", "팔달", "공단",
                    "만평", "팔달시장", "원대", "북구청", "달성공원",
                    "서문시장", "청라언덕", "남산(대구)", "명덕", "건들바위",
                    "대봉교", "수성시장", "수성구민운동장", "어린이세상",
                    "황금", "수성못", "지산", "범물", "용지"
                ],
                isCircular: false
            )
        ]
    )

    /// 대경선 광역철도 (2024-12 개통, 2026-02 북삼역 추가).
    /// 대구·동대구에서 대구 1호선과 간접환승.
    static let daegyeongLine = SeoulMetroLineInfo(
        number: 44, name: "대경선", code: "대경",
        color: Color(red: 0.00, green: 0.24, blue: 0.65),   // #003DA5
        region: .daegu,
        routes: [
            MetroRoute(
                label: "구미↔경산",
                stations: [
                    "구미", "사곡", "북삼", "왜관", "서대구", "대구",
                    "동대구", "경산"
                ],
                isCircular: false
            )
        ]
    )

    // MARK: - 광주 (51)

    static let gwangjuLine1 = SeoulMetroLineInfo(
        number: 51, name: "광주 1호선", code: "광주1",
        color: Color(red: 0.00, green: 0.56, blue: 0.53),   // #009088
        region: .gwangju,
        routes: [
            MetroRoute(
                label: "녹동↔평동",
                stations: [
                    "녹동", "소태", "학동·증심사입구", "남광주", "문화전당",
                    "금남로4가", "금남로5가", "양동시장", "돌고개", "농성",
                    "화정(광주)", "쌍촌", "운천", "상무", "김대중컨벤션센터",
                    "공항(광주)", "송정공원", "광주송정역", "도산", "평동"
                ],
                isCircular: false,
                // 녹동은 단선 승강장이라 소태 착발이 많다
                shortTermini: ["소태"]
            )
        ]
    )

    // MARK: - 대전 (61)

    static let daejeonLine1 = SeoulMetroLineInfo(
        number: 61, name: "대전 1호선", code: "대전1",
        color: Color(red: 0.00, green: 0.45, blue: 0.28),   // #007448
        region: .daejeon,
        routes: [
            MetroRoute(
                label: "판암↔반석",
                stations: [
                    "판암", "신흥(대전)", "대동", "대전역", "중앙로(대전)",
                    "중구청", "서대전네거리", "오룡", "용문(대전)", "탄방",
                    "시청(대전)", "정부청사", "갈마", "월평", "갑천",
                    "유성온천", "구암(대전)", "현충원", "월드컵경기장(대전)",
                    "노은", "지족", "반석"
                ],
                isCircular: false
            )
        ]
    )
}
