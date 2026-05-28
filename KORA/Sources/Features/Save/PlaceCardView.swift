import SwiftUI

// MARK: - Place Card (리스트용)

struct PlaceCardView: View {
    let place: Place
    var onDelete: (() -> Void)? = nil
    var onRoute: ((Place) -> Void)? = nil
    var onTap: (() -> Void)? = nil

    @Environment(\.openURL) private var openURL
    @AppStorage("kora.display_language") private var languagePref: String = ""

    private var lang: StationLanguage {
        guard !languagePref.isEmpty, let e = StationLanguage(rawValue: languagePref)
        else { return StationLanguage.resolveFromSystemLocale() }
        return e
    }

    private var primaryName: String    { lang == .korean ? place.name   : place.nameJP }
    private var secondaryName: String  { lang == .korean ? place.nameJP : place.name   }
    private var primaryAddress: String { lang == .korean ? place.address : place.addressJP }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: Name row
            VStack(alignment: .leading, spacing: 3) {
                Text(primaryName)
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(KORATheme.labelPrimary)

                if !secondaryName.isEmpty && secondaryName != primaryName {
                    Text(secondaryName)
                        .font(.subheadline)
                        .foregroundStyle(KORATheme.labelSecondary)
                }
            }
            .padding(.horizontal, KORATheme.spacing16)
            .padding(.top, 14)
            .padding(.bottom, 6)

            // MARK: Address
            if !primaryAddress.isEmpty {
                Text(primaryAddress)
                    .font(.subheadline)
                    .foregroundStyle(KORATheme.labelSecondary)
                    .lineLimit(2)
                    .padding(.horizontal, KORATheme.spacing16)
                    .padding(.bottom, 12)
            }

            // MARK: Bottom row: station + route + link
            let hasStation = !place.nearestStation.isEmpty
            let linkURL: URL? = {
                guard let u = place.sourceURL,
                      let trimmed = Optional(u.trimmingCharacters(in: .whitespacesAndNewlines)),
                      !trimmed.isEmpty else { return nil }
                return URL(string: trimmed)
            }()

            if hasStation || linkURL != nil {
                Divider().padding(.horizontal, KORATheme.spacing16)

                HStack(spacing: 8) {
                    if hasStation {
                        Label {
                            Text(stationDisplay)
                                .font(.caption).fontWeight(.medium)
                        } icon: {
                            Image(systemName: "tram.fill")
                                .font(.caption2)
                        }
                        .foregroundStyle(KORATheme.labelSecondary)
                        .lineLimit(1)

                        if let route = onRoute {
                            Button {
                                route(place)
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                        .font(.caption2)
                                    Text(routeLabel)
                                        .font(.caption2).fontWeight(.semibold)
                                }
                                .foregroundStyle(KORATheme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(KORATheme.accent.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                    }

                    Spacer()

                    if let url = linkURL {
                        Button {
                            openURL(url)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption2).fontWeight(.semibold)
                                Text(linkLabel)
                                    .font(.caption2).fontWeight(.semibold)
                            }
                            .foregroundStyle(KORATheme.labelTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, KORATheme.spacing16)
                .padding(.vertical, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KORATheme.background)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusLG))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: KORATheme.radiusLG))
        .onTapGesture { onTap?() }
    }

    // MARK: - Computed

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

    private var routeLabel: String {
        switch lang {
        case .korean:   return "경로"
        case .japanese: return "経路"
        case .english:  return "Route"
        case .chinese:  return "路线"
        }
    }

    private var linkLabel: String {
        switch lang {
        case .korean:   return "링크"
        case .japanese: return "リンク"
        case .english:  return "Link"
        case .chinese:  return "链接"
        }
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
