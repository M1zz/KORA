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
        "강동구청", "부평구청", "부천시청", "하남시청"
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
