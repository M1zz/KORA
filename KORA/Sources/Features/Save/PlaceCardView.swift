import SwiftUI

// MARK: - Place Card (리스트용)

struct PlaceCardView: View {
    let place: Place
    var onDelete: (() -> Void)? = nil
    var onRoute: ((Place) -> Void)? = nil

    @AppStorage("kora.display_language") private var languagePref: String = ""

    private var lang: StationLanguage {
        guard !languagePref.isEmpty, let e = StationLanguage(rawValue: languagePref)
        else { return StationLanguage.resolveFromSystemLocale() }
        return e
    }

    private var primaryName: String  { lang == .korean ? place.name   : place.nameJP }
    private var secondaryName: String { lang == .korean ? place.nameJP : place.name  }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 상단: 카테고리 + 이름 + 상태
            HStack(alignment: .top, spacing: 12) {
                categoryIcon

                VStack(alignment: .leading, spacing: 3) {
                    Text(primaryName)
                        .font(.body).fontWeight(.semibold)
                        .foregroundStyle(KORATheme.labelPrimary)

                    if !secondaryName.isEmpty && secondaryName != primaryName {
                        Text(secondaryName)
                            .font(.body)
                            .foregroundStyle(KORATheme.labelSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    openStatusBadge
                    Text(place.priceRange.symbolJP)
                        .font(.body).fontWeight(.medium)
                        .foregroundStyle(KORATheme.labelTertiary)
                }
            }
            .padding(KORATheme.spacing16)

            Divider()
                .padding(.horizontal, KORATheme.spacing16)

            // 하단: 위치 + 대기시간
            HStack(spacing: KORATheme.spacing16) {
                if !place.nearestStation.isEmpty {
                    Label {
                        Text(stationDisplay)
                            .font(.body).fontWeight(.medium)
                        + Text("  \(place.nearestStation)")
                            .font(.body)
                            .foregroundColor(KORATheme.labelTertiary)
                    } icon: {
                        Image(systemName: "tram.fill")
                    }
                    .foregroundStyle(KORATheme.labelSecondary)
                    .lineLimit(1)
                } else {
                    Label(analyzingStation, systemImage: "tram.fill")
                        .font(.body)
                        .foregroundStyle(KORATheme.labelTertiary)
                        .lineLimit(1)
                }

                if let wait = place.waitMinutes {
                    Spacer()
                    Label(waitLabel(wait), systemImage: "clock")
                        .font(.body).fontWeight(.medium)
                        .foregroundStyle(wait > 20 ? Color(hex: "#BA7517") : Color(hex: "#1D9E75"))
                }
            }
            .padding(.horizontal, KORATheme.spacing16)
            .padding(.vertical, KORATheme.spacing12)

            // Route CTA
            if !place.nearestStation.isEmpty {
                Divider().padding(.horizontal, KORATheme.spacing16)
                Button {
                    onRoute?(place)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "tram.tunnel.fill")
                            .font(.body).fontWeight(.semibold)
                        Text(routeButtonLabel)
                            .font(.body).fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.body).fontWeight(.semibold)
                            .foregroundStyle(KORATheme.accent.opacity(0.7))
                    }
                    .foregroundStyle(KORATheme.accent)
                    .padding(.horizontal, KORATheme.spacing16)
                    .padding(.vertical, 10)
                }
            } else if let urlString = place.sourceURL,
                      !urlString.isEmpty,
                      let linkURL = URL(string: urlString) {
                Divider().padding(.horizontal, KORATheme.spacing16)
                Link(destination: linkURL) {
                    HStack(spacing: 6) {
                        Image(systemName: "safari.fill")
                            .font(.body).fontWeight(.semibold)
                        Text(openLinkLabel)
                            .font(.body).fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.body).fontWeight(.semibold)
                            .foregroundStyle(KORATheme.accent.opacity(0.7))
                    }
                    .foregroundStyle(KORATheme.accent)
                    .padding(.horizontal, KORATheme.spacing16)
                    .padding(.vertical, 10)
                }
            }

            // 태그
            if !place.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(place.tags, id: \.self) { tag in
                            KORATagChip(
                                text: tag,
                                color: KORATheme.categoryColor(place.category)
                            )
                        }
                    }
                    .padding(.horizontal, KORATheme.spacing16)
                    .padding(.bottom, KORATheme.spacing12)
                }
            }
        }
        .background(KORATheme.background)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusLG))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Computed (language-aware)

    private var stationDisplay: String {
        guard !place.nearestStation.isEmpty else { return "" }
        let name = MetroLineData.displayName(for: place.nearestStation, language: lang)
        switch lang {
        case .korean:   return "\(name)역"
        case .japanese: return "\(name)駅"
        case .english:  return "\(name) Stn."
        case .chinese:  return "\(name)站"
        }
    }

    private var analyzingStation: String {
        switch lang {
        case .korean:   return "가까운 역 찾는 중…"
        case .japanese: return "最寄り駅を解析中…"
        case .english:  return "Finding nearest station…"
        case .chinese:  return "正在查找最近车站…"
        }
    }

    private func waitLabel(_ minutes: Int) -> String {
        switch lang {
        case .korean:   return "\(minutes)분 대기"
        case .japanese: return "\(minutes)分待ち"
        case .english:  return "\(minutes) min wait"
        case .chinese:  return "等候\(minutes)分钟"
        }
    }

    private var routeButtonLabel: String {
        switch lang {
        case .korean:   return "여기로 가기"
        case .japanese: return "ここへ向かう"
        case .english:  return "Head there"
        case .chinese:  return "前往这里"
        }
    }

    private var openLinkLabel: String {
        switch lang {
        case .korean:   return "링크 열기"
        case .japanese: return "リンクを開く"
        case .english:  return "Open link"
        case .chinese:  return "打开链接"
        }
    }

    // MARK: - Subviews

    private var categoryIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(KORATheme.categoryColor(place.category).opacity(0.12))
                .frame(width: 44, height: 44)
            Image(systemName: place.category.systemImage)
                .font(.title3)
                .foregroundStyle(KORATheme.categoryColor(place.category))
        }
    }

    private var openStatusBadge: some View {
        let label: String
        switch lang {
        case .korean:   label = place.isOpen ? "영업 중"  : "준비 중"
        case .japanese: label = place.isOpen ? "営業中"   : "準備中"
        case .english:  label = place.isOpen ? "Open"     : "Closed"
        case .chinese:  label = place.isOpen ? "营业中"   : "准备中"
        }
        return Text(label)
            .font(.body).fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(place.isOpen
                ? Color(hex: "#1D9E75").opacity(0.12)
                : Color(hex: "#888780").opacity(0.12)
            )
            .foregroundStyle(place.isOpen
                ? Color(hex: "#1D9E75")
                : Color(hex: "#888780")
            )
            .clipShape(Capsule())
    }
}

#Preview {
    PlaceCardView(place: Place(
        name: "성심당",
        nameJP: "ソンシムダン",
        category: .cafe,
        address: "대전광역시 중구 대종로 480",
        addressJP: "大田広域市 中区 テジョンロ 480",
        coordinate: Coordinate(latitude: 36.3268, longitude: 127.4272),
        nearestStation: "大田駅",
        sourceURL: "https://instagram.com/p/sample"
    ))
    .padding()
    .background(Color(UIColor.systemGroupedBackground))
}
