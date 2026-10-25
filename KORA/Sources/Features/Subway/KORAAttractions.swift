import SwiftUI

/// 명소 → 역. 여행자는 역 이름보다 가고 싶은 곳(코엑스, 경복궁 …)을 먼저 안다.
/// 명소를 찾으면 가까운 역, 출구, 걸리는 시간을 보여 주고 그 역을 바로 고르게 한다.
///
/// 원본은 `KORA/attractions.json` (명소마다 출처 URL 포함).
/// - 역 이름은 노선 데이터의 이름 그대로다(`시청(부산)` 처럼 권역 꼬리표까지). 시험이 지킨다.
/// - 출구·도보 시간은 공식 안내(장소의 '오시는 길', 관광공사, 서울교통공사 역세권 현황)에 적힌 것만 넣는다.
///   확인하지 못한 값은 null 이다 — 추측한 출구로 사람을 보내지 않는다.
/// - 이름은 역 이름 표와 같은 다섯 벌(ko/ja/en/zh-Hans/zh-Hant). 그 밖의 언어는 역 이름처럼 영어 표기를 쓴다.
struct Attraction: Identifiable, Decodable, Hashable {
    let id: String
    let category: Category
    let region: MetroCategory
    let name: [String: String]
    let aliases: [String]
    let lat: Double
    let lng: Double
    let stations: [Access]
    let sources: [String]

    /// 명소에서 역으로 가는 길 한 줄.
    struct Access: Decodable, Hashable {
        let station: String
        /// 출구 번호("5", "3-1"). 확인하지 못했으면 nil.
        let exits: [String]?
        /// 걸어서 몇 분. 출처에 적혀 있을 때만.
        let walk: Int?
    }

    enum Category: String, Decodable {
        case palace, temple, museum, landmark, market, shopping, street, park, beach, entertainment, stadium

        var symbol: String {
            switch self {
            case .palace:        return "crown.fill"
            case .temple:        return "bell.fill"
            case .museum:        return "building.columns.fill"
            case .landmark:      return "binoculars.fill"
            case .market:        return "basket.fill"
            case .shopping:      return "bag.fill"
            case .street:        return "figure.walk"
            case .park:          return "tree.fill"
            case .beach:         return "beach.umbrella.fill"
            case .entertainment: return "sparkles"
            case .stadium:       return "sportscourt.fill"
            }
        }
    }

    /// 화면 언어의 이름. 역 이름과 같은 규칙: 표지판에 없는 언어는 영어 표기.
    func displayName(_ lang: StationLanguage) -> String {
        let key: String
        switch lang.stationNames {
        case .korean:             key = "ko"
        case .japanese:           key = "ja"
        case .chinese:            key = "zh-Hans"
        case .chineseTraditional: key = "zh-Hant"
        default:                  key = "en"
        }
        return name[key] ?? name["en"] ?? id
    }

    /// 한국어가 아닐 때 함께 보여 줄 한글 이름 — 길에서 묻거나 표지판과 맞춰 볼 때.
    func koreanSubtitle(_ lang: StationLanguage) -> String? {
        guard lang != .korean, let ko = name["ko"], ko != displayName(lang) else { return nil }
        return ko
    }
}

enum KORAAttractions {
    static let all: [Attraction] = {
        guard let url = Bundle.main.url(forResource: "attractions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([Attraction].self, from: data)
        else {
            assertionFailure("attractions.json 을 읽지 못했다")
            return []
        }
        return list
    }()

    /// 검색어에 맞는 명소. 이름·별칭 어디든 들어 있으면 맞고, 앞부분이 맞는 것을 먼저 준다.
    /// 라틴 문자 한 글자("a")는 거의 모든 이름에 들어 있어 명소는 건너뛴다.
    static func search(_ query: String, limit: Int = 6) -> [Attraction] {
        let q = normalize(query)
        guard !q.isEmpty, !(q.count < 2 && q.allSatisfy(\.isASCII)) else { return [] }
        var prefix: [Attraction] = []
        var inside: [Attraction] = []
        for attraction in all {
            let keys = (Array(attraction.name.values) + attraction.aliases).map(normalize)
            if keys.contains(where: { $0.hasPrefix(q) }) {
                prefix.append(attraction)
            } else if keys.contains(where: { $0.contains(q) }) {
                inside.append(attraction)
            }
        }
        return Array((prefix + inside).prefix(limit))
    }

    /// 대소문자·띄어쓰기·가운뎃점·하이픈·악센트를 무시한다 ("N 서울타워" = "n서울타워", "Myeong-dong" = "myeongdong").
    static func normalize(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
            .filter { !$0.isWhitespace && !"-·・.'’&".contains($0) }
    }
}

// MARK: - 명소 한 칸 (검색 결과 · 지도 카드 공용)

/// 명소 이름 아래에 가까운 역을 한 줄씩. 역 줄을 누르면 그 역을 고른다.
struct AttractionCard: View {
    let attraction: Attraction
    let lang: StationLanguage
    /// 고를 수 없는 역(이미 반대편에 고른 역).
    let excluding: String?
    let onPick: (String) -> Void

    private var accesses: [Attraction.Access] {
        attraction.stations.filter { $0.station != excluding }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: attraction.category.symbol)
                    .font(.footnote).fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(KORATheme.accent, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(attraction.displayName(lang))
                        .font(.body).fontWeight(.semibold)
                        .foregroundStyle(KORATheme.labelPrimary)
                    if let ko = attraction.koreanSubtitle(lang) {
                        Text(ko)
                            .font(.subheadline)
                            .foregroundStyle(KORATheme.labelSecondary)
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            ForEach(accesses, id: \.station) { access in
                Button { onPick(access.station) } label: { accessRow(access) }
                    .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private func accessRow(_ access: Attraction.Access) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                ForEach(MetroLineData.linesContaining(access.station), id: \.self) { num in
                    Text(MetroLineData.lineBadgeText(num))
                        .font(.caption).fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .frame(minWidth: 20, minHeight: 18)
                        .background(MetroLineData.lineColor(num))
                        .clipShape(Capsule())
                }
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(MetroLineData.displayName(for: access.station, language: lang))
                    .font(.body).fontWeight(.medium)
                    .foregroundStyle(KORATheme.labelPrimary)
                if let detail = Self.detail(access, lang) {
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(KORATheme.labelSecondary)
                }
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.footnote).fontWeight(.semibold)
                .foregroundStyle(KORATheme.labelTertiary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(KORATheme.surface, in: RoundedRectangle(cornerRadius: KORATheme.radiusMD))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    /// "5·6번 출구 · 도보 약 3분" — 아는 것만.
    static func detail(_ access: Attraction.Access, _ lang: StationLanguage) -> String? {
        var parts: [String] = []
        if let exits = access.exits, !exits.isEmpty {
            let numbers = exits.joined(separator: "·")
            parts.append(exits.count == 1 ? NavLoc.exitNumber.fill(lang, numbers)
                                          : NavLoc.exitNumbers.fill(lang, numbers))
        }
        if let walk = access.walk {
            parts.append(NavLoc.walkAboutMinutes.fill(lang, "\(walk)"))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
