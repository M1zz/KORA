import SwiftUI

struct NowView: View {
    @State private var viewModel = NowViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // 위치 상태 배너
                    locationBanner
                        .padding(.horizontal)

                    // 지금 이벤트
                    eventsSection

                    // 주변 장소 (영업중)
                    nearbySection
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Now")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Location Banner

    private var locationBanner: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(KORATheme.accentLight)
                    .frame(width: 40, height: 40)
                Image(systemName: "location.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(KORATheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("弘大エリア付近")
                    .font(.system(size: 15, weight: .semibold))
                Text("周辺 2km 以内のスポットとイベントを表示中")
                    .font(.system(size: 12))
                    .foregroundStyle(KORATheme.labelSecondary)
            }

            Spacer()

            Button("更新") {
                viewModel.requestLocation()
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(KORATheme.accent)
        }
        .padding(KORATheme.spacing16)
        .background(KORATheme.background)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusLG))
    }

    // MARK: - Events Section

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日のイベント")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Text("\(viewModel.events.count)") + Text("件")
                    .font(.system(size: 13))
                    .foregroundStyle(KORATheme.labelSecondary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.events) { event in
                        EventCard(event: event)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Nearby Section

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今すぐ行ける")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Text("営業中のみ")
                    .font(.system(size: 13))
                    .foregroundStyle(KORATheme.labelSecondary)
            }
            .padding(.horizontal)

            LazyVStack(spacing: 10) {
                ForEach(viewModel.nearbyPlaces.filter { $0.isOpen }) { place in
                    NearbyPlaceRow(place: place)
                        .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Event Card

struct EventCard: View {
    let event: NowEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(LocalizedStringKey(event.category.rawValue))
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: event.category.color).opacity(0.15))
                    .foregroundStyle(Color(hex: event.category.color))
                    .clipShape(Capsule())

                Spacer()

                Text("\(event.distanceM)m")
                    .font(.system(size: 12))
                    .foregroundStyle(KORATheme.labelTertiary)
            }

            Text(event.titleJP)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(KORATheme.labelPrimary)
                .lineLimit(2)

            Text(event.locationJP)
                .font(.system(size: 13))
                .foregroundStyle(KORATheme.labelSecondary)
                .lineLimit(1)

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                Text(event.startTime) + Text("〜") + Text(event.endTime)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(KORATheme.accent)
        }
        .padding(KORATheme.spacing16)
        .frame(width: 200)
        .background(KORATheme.background)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusLG))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Nearby Place Row

struct NearbyPlaceRow: View {
    let place: Place

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(KORATheme.categoryColor(place.category).opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: place.category.systemImage)
                    .font(.system(size: 18))
                    .foregroundStyle(KORATheme.categoryColor(place.category))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(place.nameJP)
                    .font(.system(size: 15, weight: .semibold))
                Text(place.nearestStation)
                    .font(.system(size: 12))
                    .foregroundStyle(KORATheme.labelSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let wait = place.waitMinutes {
                    Group {
                        if wait > 0 {
                            Text("\(wait)") + Text("分待ち")
                        } else {
                            Text("待ちなし")
                        }
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(wait > 20 ? Color(hex: "#BA7517") : Color(hex: "#1D9E75"))
                }
                Text(place.priceRange.symbolJP)
                    .font(.system(size: 12))
                    .foregroundStyle(KORATheme.labelTertiary)
            }
        }
        .padding(KORATheme.spacing12)
        .background(KORATheme.background)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusMD))
    }
}

#Preview {
    NowView()
}
