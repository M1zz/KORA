import SwiftUI

// MARK: - Place Card (리스트용)

struct PlaceCardView: View {
    let place: Place
    var onDelete: (() -> Void)? = nil
    var onRoute: ((Place) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 상단: 카테고리 + 이름 + 상태
            HStack(alignment: .top, spacing: 12) {
                categoryIcon

                VStack(alignment: .leading, spacing: 3) {
                    Text(place.nameJP)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(KORATheme.labelPrimary)

                    Text(place.name)
                        .font(.system(size: 13))
                        .foregroundStyle(KORATheme.labelSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    openStatusBadge
                    Text(place.priceRange.symbolJP)
                        .font(.system(size: 12, weight: .medium))
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
                        Text(stationDisplayJa)
                            .font(.system(size: 12, weight: .medium))
                        + Text("  \(place.nearestStation)")
                            .font(.system(size: 11))
                            .foregroundColor(KORATheme.labelTertiary)
                    } icon: {
                        Image(systemName: "tram.fill")
                    }
                    .foregroundStyle(KORATheme.labelSecondary)
                    .lineLimit(1)
                } else {
                    Label("最寄り駅を解析中…", systemImage: "tram.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(KORATheme.labelTertiary)
                        .lineLimit(1)
                }

                if let wait = place.waitMinutes {
                    Spacer()
                    Label("\(wait)分待ち", systemImage: "clock")
                        .font(.system(size: 12, weight: .medium))
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
                            .font(.system(size: 13, weight: .semibold))
                        Text("ここへ向かう")
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
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

    // MARK: - Computed

    private var stationDisplayJa: String {
        guard !place.nearestStation.isEmpty else { return "" }
        let ja = MetroLineData.displayName(for: place.nearestStation, language: .japanese)
        return "\(ja)駅"
    }

    // MARK: - Subviews

    private var categoryIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(KORATheme.categoryColor(place.category).opacity(0.12))
                .frame(width: 44, height: 44)
            Image(systemName: place.category.systemImage)
                .font(.system(size: 18))
                .foregroundStyle(KORATheme.categoryColor(place.category))
        }
    }

    private var openStatusBadge: some View {
        (place.isOpen ? Text("営業中") : Text("準備中"))
            .font(.system(size: 11, weight: .semibold))
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
