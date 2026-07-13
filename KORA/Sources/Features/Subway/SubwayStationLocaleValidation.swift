import Foundation

// MARK: - Station name validation
//
// Station names MUST be transliterations, not translations.
//   ✅ 소요산 → "Soyosan"
//   ❌ 소요산 → "Soyo Mountain"
//
// Some stations have officially-translated English names (e.g. 시청 = "City Hall")
// because Seoul Metro signage uses those gloss translations. Those exceptions
// live in `officialTranslationExceptions` below — every other station with
// suspicious English content gets flagged.

extension MetroLineData {

    /// Set of Korean station names whose English name is a Seoul-Metro-official
    /// translation rather than a romanization. Any station NOT in this set
    /// whose English name contains a translation marker is a bug.
    static let officialTranslationExceptions: Set<String> = [
        "시청",                  // City Hall
        "서울역",                // Seoul Station
        "대공원",                // Grand Park (Seoul Grand Park)
        "어린이대공원",          // Children's Grand Park
        "올림픽공원",            // Olympic Park
        "효창공원앞",            // Hyochang Park
        "월드컵경기장",          // World Cup Stadium
        "종합운동장",            // Sports Complex
        "부천종합운동장",        // Bucheon Stadium
        "삼산체육관",            // Samsan Gymnasium
        "디지털미디어시티",      // Digital Media City
        "고속터미널",            // Express Bus Terminal
        "남부터미널",            // Seoul Nambu Bus Terminal
        "동대문역사문화공원",    // Dongdaemun History & Culture Park
        "가락시장",              // Garak Market
        "영등포시장",            // Yeongdeungpo Market
        "공항시장",              // Airport Market
        "경찰병원",              // Police Hospital
        "중앙보훈병원",          // Veterans Hospital
        "경마공원",              // Seoul Racecourse Park
        "뚝섬유원지",            // Ttukseom Resort
        "국회의사당",            // National Assembly
        // 구청/시청 — "-gu Office", "City Hall"
        "금천구청", "영등포구청", "양천구청", "강남구청", "마포구청",
        "강동구청", "부평구청", "부천시청", "하남시청",
        // Line 10–13 official translations
        "양재시민의숲",          // Yangjae Citizen's Forest
        "서울숲",                // Seoul Forest
        "수지구청",              // Suji-gu Office
        "수원시청",              // Suwon City Hall
        // ── 전국 확장 (수도권 경전철·지방 권역) 공식 번역 역명 ──
        "강서구청",              // Gangseo-gu Office (부산)
        "경기도청북부청사",      // Gyeonggi Provincial Government Northern Office
        "경대병원",              // Kyungpook Nat'l Univ. Hospital (대구)
        "김대중컨벤션센터",      // Kimdaejung Convention Center (광주)
        "김해대학",              // Gimhae College
        "김해시청",              // Gimhae City Hall
        "다대포해수욕장",        // Dadaepo Beach (부산)
        "달성공원",              // Dalseong Park (대구)
        "대구한의대병원",        // Daegu Haany University Hospital
        "동구청",                // Dong-gu Office (대구)
        "매천시장",              // Maecheon Market (대구)
        "박물관",                // Gimhae National Museum
        "반여농산물시장",        // Banyeo Agricultural Market (부산)
        "보라매공원",            // Boramae Park (신림선)
        "보라매병원",            // Boramae Medical Center (신림선)
        "북구청",                // Buk-gu Office (대구)
        "서문시장",              // Seomun Market (대구)
        "서울지방병무청",        // Seoul Regional Office of Military Manpower
        "솔밭공원",              // Solbat Park (우이신설)
        "송정공원",              // Songjeong Park (광주)
        "수로왕릉",              // Royal Tomb of King Suro (김해)
        "수성구민운동장",        // Suseong District Stadium (대구)
        "수성구청",              // Suseong-gu Office (대구)
        "수성시장",              // Suseong Market (대구)
        "시청(대전)",            // City Hall (Daejeon)
        "시청(부산)",            // City Hall (Busan)
        "시흥시청",              // Siheung City Hall (서해선)
        "양동시장",              // Yangdong Market (광주)
        "연지공원",              // Yeonji Park (김해)
        "영대병원",              // Yeungnam Univ. Hospital (대구)
        "용인중앙시장",          // Yongin Jungang Market (에버라인)
        "월드컵경기장(대전)",    // World Cup Stadium (Daejeon)
        "의정부시청",            // Uijeongbu City Hall
        "중구청",                // Jung-gu Office (대전)
        "체육공원",              // Sports Park (부산)
        "칠곡경대병원",          // Chilgok Kyungpook Nat'l Univ. Medical Center
        "칠성시장",              // Chilseong Market (대구)
        "팔달시장",              // Paldal Market (대구)
        // ── 인천 1·2호선 ──
        "가정중앙시장",          // Gajeong Jungang Market
        "검단호수공원",          // Geomdan Lake Park
        "남동구청",              // Namdong-gu Office
        "모래내시장",            // Moraenae Market
        "부평시장",              // Bupyeong Market
        "서구청",                // Seo-gu Office
        "서부여성회관",          // West Women's Community Center
        "석바위시장",            // Seokbawi Market
        "센트럴파크",            // Central Park
        "송도달빛축제공원",      // Songdo Moonlight Festival Park
        "시민공원",              // Citizens Park
        "아시아드경기장",        // Asiad Stadium
        "예술회관",              // Arts Center
        "인천대공원",            // Incheon Grand Park
        "인천시청"               // Incheon City Hall
    ]

    /// English words that, when found in a station's English name, suggest
    /// translation rather than romanization. Stations not in the official
    /// exceptions list above must NOT contain any of these.
    static let translationMarkers: [String] = [
        "Mountain", "Hospital", "Park", "Hall", "Office", "Bridge",
        "Market", "Center", "Tomb", "Forest", "River", "Lake",
        "Stadium", "College", "Entrance", "Tunnel", "Beach", "Island",
        "Gate", "Garden", "Library", "Museum", "School", "Wall",
        "Tower", "Fortress", "Square", "Resort"
    ]

    /// Validation result — one issue per offending station.
    struct StationNameIssue: CustomStringConvertible {
        let koreanName: String
        let englishName: String
        let reason: String
        var description: String { "\(koreanName) → \"\(englishName)\": \(reason)" }
    }

    /// Walks the entire `stationLocale` and returns any English names that
    /// look like translations of stations not in the official exception set.
    /// Run from a unit test or app launch in DEBUG to catch regressions.
    static func validateStationNames() -> [StationNameIssue] {
        var issues: [StationNameIssue] = []

        for (ko, locale) in stationLocale {
            let en = locale.en

            if !officialTranslationExceptions.contains(ko) {
                for marker in translationMarkers where en.contains(marker) {
                    issues.append(StationNameIssue(
                        koreanName: ko,
                        englishName: en,
                        reason: "contains translation marker \"\(marker)\" but station is not in the official-translation exception list. Romanize instead."
                    ))
                    break
                }
            }

            // Phonetic sanity: English name shouldn't be empty.
            if en.trimmingCharacters(in: .whitespaces).isEmpty {
                issues.append(StationNameIssue(
                    koreanName: ko,
                    englishName: en,
                    reason: "English name is empty"
                ))
            }

            // Surface multi-syllable proper-name splits like "Sin Yongsan",
            // "Hanam Geomdan Mountain" — heuristic: if the English starts
            // with a multi-character Sin/Sangbong/etc. prefix that should
            // be one word, flag it. Conservative version: warn on any
            // 2+-word English that doesn't include an exception marker
            // and doesn't include a comma or parenthetical.
            // (Skipped here to avoid false positives on legitimate
            // multi-word romanizations like "Dongducheon Jungang".)
            _ = en
        }

        return issues.sorted { $0.koreanName < $1.koreanName }
    }

    #if DEBUG
    /// Fires an assertion failure in DEBUG builds if any station name fails
    /// validation. Call this once at app launch.
    static func assertStationNamesValid(file: StaticString = #file, line: UInt = #line) {
        let issues = validateStationNames()
        if !issues.isEmpty {
            let lines = issues.map { "  - \($0)" }.joined(separator: "\n")
            assertionFailure("\(issues.count) station name issue(s):\n\(lines)", file: file, line: line)
        }
    }
    #endif
}
