import SwiftUI
import MapKit

struct PlaceDetailSheet: View {
    let lang: StationLanguage
    let onUpdate: (Place) -> Void

    @State private var current: Place
    @State private var detail: KakaoPlaceDetail? = nil
    @State private var isFetchingBasic  = false
    @State private var isFetchingDetail = false

    private let search      = PlaceSearchService()
    private let detailSvc   = KakaoPlaceDetailService()

    init(place: Place, lang: StationLanguage, onUpdate: @escaping (Place) -> Void) {
        self.lang     = lang
        self.onUpdate = onUpdate
        _current = State(initialValue: place)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    photoSection
                    nameSection
                    Divider().padding(.horizontal, 20)
                    infoSection
                    hoursSection
                    buttonSection
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(closeLabel) { dismiss() }.foregroundStyle(.secondary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task { await fetchAll() }
    }

    // MARK: - Photo strip

    @ViewBuilder
    private var photoSection: some View {
        // Prefer the stored gallery (Kakao + Naver, populated at save time)
        // and fall back to the freshly-fetched Kakao-only photos for places
        // saved before the gallery field existed.
        let stored = current.photoURLs ?? []
        let photos = stored.isEmpty ? (detail?.photos ?? []) : stored
        if isFetchingDetail && photos.isEmpty {
            Rectangle()
                .fill(Color(UIColor.systemFill))
                .frame(maxWidth: .infinity).frame(height: 200)
                .overlay(ProgressView())
        } else if !photos.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(photos, id: \.self) { urlStr in
                        CachedAsyncImage(urlString: urlStr) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                                    .frame(width: photos.count == 1 ? UIScreen.main.bounds.width : 220, height: 200)
                                    .clipped()
                            case .failure:
                                EmptyView()
                            case .loading:
                                Rectangle()
                                    .fill(Color(UIColor.systemFill))
                                    .frame(width: 220, height: 200)
                                    .overlay(ProgressView().scaleEffect(0.7))
                            }
                        }
                    }
                }
            }
            .scrollClipDisabled(false)
        }
    }

    // MARK: - Name + category

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(primaryName)
                .font(.title3).fontWeight(.bold).foregroundStyle(.primary)
            if !secondaryName.isEmpty && secondaryName != primaryName {
                Text(secondaryName).font(.body).foregroundStyle(.secondary)
            }
            Text(current.category.displayName(language: lang))
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(KORATheme.categoryColor(current.category))
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(KORATheme.categoryColor(current.category).opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 14)
    }

    // MARK: - Info rows

    @ViewBuilder
    private var infoSection: some View {
        VStack(spacing: 0) {
            if !primaryAddress.isEmpty {
                infoRow(icon: "mappin.circle.fill", color: .red) {
                    Text(primaryAddress).font(.callout).foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            let phone = detail?.phone ?? current.phone
            if isFetchingDetail && phone == nil {
                infoRow(icon: "phone.circle.fill", color: .secondary) {
                    HStack(spacing: 8) {
                        ProgressView().scaleEffect(0.75)
                        Text(loadingLabel).font(.callout).foregroundStyle(.secondary)
                    }
                }
            } else if let p = phone, !p.isEmpty {
                infoRow(icon: "phone.circle.fill", color: Color(hex: "#1D9E75")) {
                    Text(p).font(.callout).foregroundStyle(.primary)
                }
            }

            if !current.nearestStation.isEmpty {
                infoRow(icon: "tram.circle.fill", color: KORATheme.accent) {
                    Text(stationDisplay).font(.callout).foregroundStyle(.primary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Hours

    @ViewBuilder
    private var hoursSection: some View {
        let hours = detail?.hours ?? []
        if !hours.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Divider().padding(.horizontal, 20)
                infoRow(icon: "clock.fill", color: .orange) {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(hours, id: \.days) { entry in
                            HStack(alignment: .top, spacing: 0) {
                                Text(entry.days.isEmpty ? hoursLabel : entry.days)
                                    .font(.callout).foregroundStyle(.secondary)
                                    .frame(minWidth: 80, alignment: .leading)
                                Text(entry.time)
                                    .font(.callout).foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Action buttons

    private var buttonSection: some View {
        VStack(spacing: 10) {
            if current.hasLocation || !current.name.isEmpty {
                Button { openInAppleMaps() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "map.fill").font(.body)
                        Text(appleMapLabel).font(.body).fontWeight(.bold)
                        Spacer()
                        Image(systemName: "arrow.up.right.square").font(.caption).fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18).padding(.vertical, 16)
                    .background(KORATheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }

            if let src = current.sourceURL,
               let trimmed = Optional(src.trimmingCharacters(in: .whitespacesAndNewlines)),
               !trimmed.isEmpty, let url = URL(string: trimmed) {
                Button { UIApplication.shared.open(url) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "safari.fill").font(.body)
                        Text(sourceLinkLabel).font(.body).fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "arrow.up.right").font(.caption).fontWeight(.semibold)
                    }
                    .foregroundStyle(KORATheme.accent)
                    .padding(.horizontal, 18).padding(.vertical, 16)
                    .background(KORATheme.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 40)
    }

    // MARK: - Row helper

    @ViewBuilder
    private func infoRow<C: View>(icon: String, color: Color, @ViewBuilder content: () -> C) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(color).frame(width: 26).padding(.top, 1)
            content()
            Spacer()
        }
        .padding(.horizontal, 20).padding(.vertical, 11)
    }

    // MARK: - Fetch chain

    private func fetchAll() async {
        // Step 1: ensure we have kakaoMapURL (keyword search fallback)
        if current.kakaoMapURL == nil {
            await fetchBasicInfo()
        }
        // Step 2: fetch rich detail (photos, hours) via internal API
        if let urlStr = current.kakaoMapURL {
            await fetchDetail(kakaoMapURL: urlStr)
        }
    }

    private func fetchBasicInfo() async {
        isFetchingBasic = true
        defer { isFetchingBasic = false }
        do {
            let docs: [KakaoDocument] = current.hasLocation
                ? try await search.searchKeyword(current.name, latitude: current.coordinate.latitude, longitude: current.coordinate.longitude, size: 5)
                : try await search.searchKeyword(current.name, size: 5)
            let best = docs.first { $0.placeName == current.name } ?? docs.first
            guard let doc = best else { return }
            var updated = current
            if updated.phone == nil,     !doc.phone.isEmpty    { updated.phone       = doc.phone }
            if updated.kakaoMapURL == nil, !doc.placeUrl.isEmpty { updated.kakaoMapURL = doc.placeUrl }
            if updated.address.isEmpty { updated.address = doc.displayAddress; updated.addressJP = doc.displayAddress }
            current = updated
            onUpdate(updated)
        } catch { /* silent */ }
    }

    private func fetchDetail(kakaoMapURL: String) async {
        isFetchingDetail = true
        defer { isFetchingDetail = false }
        do {
            let d = try await detailSvc.fetch(kakaoMapURL: kakaoMapURL)
            detail = d
            // Cache phone + photo if newly obtained
            var updated = current
            if updated.phone == nil, let p = d.phone { updated.phone = p }
            if updated.imageURL == nil, let photo = d.mainPhotoURL { updated.imageURL = photo }
            if updated != current { current = updated; onUpdate(updated) }
        } catch { /* silent */ }
    }

    // MARK: - Dismiss helper (NavigationStack wrapper means no @Environment available at outer scope)
    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed strings

    private var primaryName: String    { lang == .korean ? current.name    : current.nameJP }
    private var secondaryName: String  { lang == .korean ? current.nameJP  : current.name   }
    private var primaryAddress: String { lang == .korean ? current.address  : current.addressJP }

    private var stationDisplay: String {
        let n = MetroLineData.displayName(for: current.nearestStation, language: lang)
        switch lang {
        case .korean: return "\(n)역"; case .japanese: return "\(n)駅"
        case .english: return "\(n) Stn."; case .chinese: return "\(n)站"
        }
    }
    private var hoursLabel: String {
        switch lang {
        case .korean: return "영업시간"; case .japanese: return "営業時間"
        case .english: return "Hours"; case .chinese: return "营业时间"
        }
    }
    private var appleMapLabel: String {
        switch lang {
        case .korean: return "지도에서 보기"; case .japanese: return "マップで見る"
        case .english: return "Open in Maps"; case .chinese: return "在地图中查看"
        }
    }

    /// Hands the place off to Apple Maps. When we have real coordinates we
    /// hand over an `MKMapItem` (with the pin titled) for the most accurate
    /// drop; otherwise we fall back to a query URL so the Maps app at least
    /// runs a search for the name.
    private func openInAppleMaps() {
        if current.hasLocation {
            let coord = CLLocationCoordinate2D(
                latitude: current.coordinate.latitude,
                longitude: current.coordinate.longitude
            )
            let item = MKMapItem(placemark: MKPlacemark(coordinate: coord))
            item.name = current.name
            item.openInMaps()
            return
        }
        let q = current.name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard !q.isEmpty, let url = URL(string: "http://maps.apple.com/?q=\(q)") else { return }
        UIApplication.shared.open(url)
    }
    private var sourceLinkLabel: String {
        switch lang {
        case .korean: return "원본 링크 열기"; case .japanese: return "元のリンクを開く"
        case .english: return "Open original link"; case .chinese: return "打开原始链接"
        }
    }
    private var loadingLabel: String {
        switch lang {
        case .korean: return "정보 불러오는 중..."; case .japanese: return "情報を取得中..."
        case .english: return "Loading..."; case .chinese: return "加载中..."
        }
    }
    private var closeLabel: String {
        switch lang {
        case .korean: return "닫기"; case .japanese: return "閉じる"
        case .english: return "Close"; case .chinese: return "关闭"
        }
    }
}

// Equatable conformance for diff check in fetchDetail
extension Place: Equatable {
    static func == (lhs: Place, rhs: Place) -> Bool {
        lhs.id == rhs.id &&
        lhs.phone == rhs.phone &&
        lhs.imageURL == rhs.imageURL &&
        lhs.kakaoMapURL == rhs.kakaoMapURL
    }
}
