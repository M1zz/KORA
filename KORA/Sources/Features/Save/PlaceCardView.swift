import SwiftUI

// MARK: - Place Card (리스트용)

struct PlaceCardView: View {
    let place: Place
    var onDelete: (() -> Void)? = nil
    var onEdit:   (() -> Void)? = nil
    var onTap:    (() -> Void)? = nil

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

            imageHero

            VStack(alignment: .leading, spacing: 3) {
                Text(primaryName)
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(KORATheme.labelPrimary)
                    .lineLimit(2)

                if !secondaryName.isEmpty && secondaryName != primaryName {
                    Text(secondaryName)
                        .font(.subheadline)
                        .foregroundStyle(KORATheme.labelSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, KORATheme.spacing16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            footerRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KORATheme.background)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusLG))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: KORATheme.radiusLG))
        .onTapGesture { onTap?() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityCardLabel)
        .accessibilityHint(detailHint)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: Text(directionsLabel)) { routeTo() }
        .accessibilityActions {
            if let onEdit   { Button(editLabel,   action: onEdit) }
            if let onDelete { Button(deleteLabel, action: onDelete) }
            if let url = linkURL { Button(linkLabel) { openURL(url) } }
        }
    }

    // MARK: - Footer (station + directions + link)

    @ViewBuilder
    private var footerRow: some View {
        let resolvedStation = resolvedStationName
        let hasStation = !resolvedStation.isEmpty
        let canDirect  = hasStation || place.hasLocation || !place.address.isEmpty

        if hasStation || canDirect || linkURL != nil {
            Divider().padding(.horizontal, KORATheme.spacing16)

            VStack(alignment: .leading, spacing: 8) {
                if hasStation {
                    stationLine(resolvedStation)
                }

                HStack(spacing: 6) {
                    if canDirect {
                        Button {
                            routeTo()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "tram.fill")
                                    .font(.caption2)
                                Text(directionsLabel)
                                    .font(.caption).fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(KORATheme.accent)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 0)

                    if let url = linkURL {
                        Button {
                            openURL(url)
                        } label: {
                            Image(systemName: "arrow.up.right.square")
                                .font(.callout).fontWeight(.semibold)
                                .foregroundStyle(KORATheme.labelTertiary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(linkLabel))
                    }
                }
            }
            .padding(.horizontal, KORATheme.spacing16)
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private func stationLine(_ station: String) -> some View {
        let lines = MetroLineData.linesContaining(station)
        HStack(spacing: 5) {
            ForEach(lines, id: \.self) { num in
                Text(MetroLineData.lineBadgeText(num))
                    .font(.caption2).fontWeight(.black)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(MetroLineData.lineColor(num))
                    .clipShape(Capsule())
            }
            Text(stationDisplay(for: station))
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(KORATheme.labelSecondary)
                .lineLimit(1)
        }
    }

    // MARK: - Image Hero

    /// Photos available for the gallery — falls back to single `imageURL`
    /// for legacy saves where the backfill hasn't run yet.
    private var effectivePhotos: [String] {
        if let list = place.photoURLs, !list.isEmpty { return list }
        if let s = place.imageURL, !s.isEmpty { return [s] }
        return []
    }

    @ViewBuilder
    private var imageHero: some View {
        let photos = effectivePhotos
        if photos.isEmpty {
            placeholderHero
                .frame(height: 100).frame(maxWidth: .infinity)
                .accessibilityHidden(true)
        } else if photos.count == 1 {
            asyncImage(photos[0])
                .frame(height: 160).frame(maxWidth: .infinity)
                .clipped()
                .accessibilityHidden(true)
        } else {
            TabView {
                ForEach(photos.indices, id: \.self) { i in
                    asyncImage(photos[i])
                        .clipped()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func asyncImage(_ urlString: String) -> some View {
        if let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    placeholderHero
                case .empty:
                    placeholderHero.overlay(ProgressView().tint(KORATheme.labelTertiary))
                @unknown default:
                    placeholderHero
                }
            }
        } else {
            placeholderHero
        }
    }

    private var placeholderHero: some View {
        ZStack {
            KORATheme.categoryColor(place.category).opacity(0.18)
            Image(systemName: place.category.systemImage)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(KORATheme.categoryColor(place.category).opacity(0.7))
        }
    }

    // MARK: - Directions (in-app subway routing from current location)

    private var linkURL: URL? {
        guard let u = place.sourceURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !u.isEmpty else { return nil }
        return URL(string: u)
    }

    /// Best available destination station: prefer the stored `nearestStation`,
    /// otherwise compute from coordinates via the bundled metro table.
    private var resolvedStationName: String {
        if !place.nearestStation.isEmpty { return place.nearestStation }
        guard place.hasLocation,
              let local = MetroLineData.nearestStation(
                latitude: place.coordinate.latitude,
                longitude: place.coordinate.longitude
              )
        else { return "" }
        return local.name
    }

    private func routeTo() {
        let dest = resolvedStationName
        guard !dest.isEmpty else { return }
        NavigationCoordinator.shared.routeTo(station: dest)
    }

    // MARK: - Accessibility text

    private var accessibilityCardLabel: String {
        var parts: [String] = [primaryName]
        parts.append(place.category.displayName(language: lang))
        let station = resolvedStationName
        if !station.isEmpty {
            let lines = MetroLineData.linesContaining(station)
            let lineText = lines.map { "\($0)호선" }.joined(separator: " ")
            if !lineText.isEmpty { parts.append(lineText) }
            parts.append(stationDisplay(for: station))
        }
        return parts.joined(separator: ", ")
    }

    // MARK: - Computed labels

    private func stationDisplay(for station: String) -> String {
        let name = MetroLineData.displayName(for: station, language: lang)
        switch lang {
        case .korean:   return "\(name)역"
        case .japanese: return "\(name)駅"
        case .english:  return "\(name) Stn."
        case .chinese:  return "\(name)站"
        }
    }

    private var directionsLabel: String {
        switch lang {
        case .korean:   return "길찾기"
        case .japanese: return "経路案内"
        case .english:  return "Directions"
        case .chinese:  return "导航"
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

    private var detailHint: String {
        switch lang {
        case .korean:   return "두 번 탭하여 자세히 보기"
        case .japanese: return "ダブルタップで詳細を表示"
        case .english:  return "Double tap to view details"
        case .chinese:  return "双击查看详情"
        }
    }

    private var editLabel: String {
        switch lang {
        case .korean:   return "수정"
        case .japanese: return "編集"
        case .english:  return "Edit"
        case .chinese:  return "编辑"
        }
    }

    private var deleteLabel: String {
        switch lang {
        case .korean:   return "삭제"
        case .japanese: return "削除"
        case .english:  return "Delete"
        case .chinese:  return "删除"
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
