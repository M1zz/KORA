import SwiftUI
import MapKit

/// 지도에서 역 고르기. 역 고르기 화면(`StationSearchSheet`)의 지도 단추로 들어온다.
///
/// - 역은 노선 색 점, 갈아타는 역은 흰 점에 검은 테두리(노선도와 같은 약속).
///   멀리서 보면 점이 겹쳐 읽을 수 없으니 확대 정도에 따라 줄인다:
///   아주 멀면 명소만, 도시 하나쯤이면 갈아타는 역만, 동네 크기면 모든 역, 더 가까우면 역 이름까지.
/// - 명소는 빨간 동그라미. 누르면 가까운 역과 출구가 나오고, 그 역을 바로 고른다.
/// - 좌표는 앱의 역 좌표 표(`MetroLineData.stationCoordinates`)를 그대로 쓴다.
struct StationMapPicker: View {
    let excluding: String?
    let lang: StationLanguage
    let category: MetroCategory
    /// 출발역을 고를 때는 지금 있는 곳에서 시작한다.
    var startsAtUserLocation: Bool = false
    let onPick: (String) -> Void

    private enum Pick: Hashable {
        case station(String)
        case attraction(Attraction)
    }

    @State private var position: MapCameraPosition
    @State private var visible: MKCoordinateRegion
    @State private var pick: Pick?
    private let locationService = LocationService()

    init(excluding: String?, lang: StationLanguage, category: MetroCategory,
         startsAtUserLocation: Bool = false, onPick: @escaping (String) -> Void) {
        self.excluding = excluding
        self.lang = lang
        self.category = category
        self.startsAtUserLocation = startsAtUserLocation
        self.onPick = onPick
        let start = Self.startRegion(for: category)
        _position = State(initialValue: .region(start))
        _visible = State(initialValue: start)
    }

    var body: some View {
        Map(position: $position) {
            UserAnnotation()
            ForEach(visibleStations, id: \.self) { name in
                Annotation(MetroLineData.displayName(for: name, language: lang), coordinate: Self.coordinate(name)) {
                    stationDot(name)
                }
                .annotationTitles(detail == .labelled ? .automatic : .hidden)
            }
            ForEach(visibleAttractions) { attraction in
                Annotation(attraction.displayName(lang),
                           coordinate: CLLocationCoordinate2D(latitude: attraction.lat, longitude: attraction.lng)) {
                    attractionPin(attraction)
                }
                .annotationTitles(detail == .all || detail == .labelled ? .automatic : .hidden)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onMapCameraChange(frequency: .onEnd) { visible = $0.region }
        .overlay(alignment: .top) { zoomHint }
        .overlay(alignment: .bottom) { pickCard }
        .animation(.easeOut(duration: 0.2), value: pick)
        .navigationTitle(NavLoc.pickOnMap.resolved(lang))
        .navigationBarTitleDisplayMode(.inline)
        .task { if startsAtUserLocation { await moveToUser() } }
    }

    // MARK: - 확대 정도

    private enum Detail { case attractionsOnly, transfersOnly, all, labelled }

    private var detail: Detail {
        switch visible.span.latitudeDelta {
        case ..<0.025: return .labelled
        case ..<0.09:  return .all
        case ..<0.3:   return .transfersOnly
        default:       return .attractionsOnly
        }
    }

    private var visibleStations: [String] {
        guard detail != .attractionsOnly else { return selectedStation.map { [$0] } ?? [] }
        let inView = Self.mapStations.filter { name in
            name != excluding
                && MetroLineData.stationCoordinates[name].map { contains($0.lat, $0.lng) } == true
        }
        let shown = detail == .transfersOnly ? inView.filter { Self.isTransfer($0) } : inView
        if let s = selectedStation, !shown.contains(s) { return shown + [s] }
        return shown
    }

    private var visibleAttractions: [Attraction] {
        KORAAttractions.all.filter { contains($0.lat, $0.lng) }
    }

    private var selectedStation: String? {
        if case .station(let s) = pick { return s }
        return nil
    }

    private func contains(_ lat: Double, _ lng: Double) -> Bool {
        // 화면 가장자리에서 점이 갑자기 생기지 않게 조금 넉넉하게.
        abs(lat - visible.center.latitude) <= visible.span.latitudeDelta * 0.6
            && abs(lng - visible.center.longitude) <= visible.span.longitudeDelta * 0.6
    }

    @ViewBuilder private var zoomHint: some View {
        if detail == .attractionsOnly {
            Text(NavLoc.zoomInForStations.resolved(lang))
                .font(.footnote).fontWeight(.semibold)
                .foregroundStyle(KORATheme.labelPrimary)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
                .padding(.top, 10)
        }
    }

    // MARK: - 표시

    private func stationDot(_ name: String) -> some View {
        let lines = Self.stationLines[name] ?? []
        let transfer = lines.count > 1
        let selected = selectedStation == name
        let size: CGFloat = (transfer ? 14 : 12) * (selected ? 1.5 : 1)
        return Button {
            pick = selected ? nil : .station(name)
        } label: {
            Circle()
                .fill(transfer ? Color.white : MetroLineData.lineColor(lines.first ?? 0))
                .overlay(Circle().stroke(transfer ? Color.black : Color.white, lineWidth: transfer ? 2.5 : 2))
                .frame(width: size, height: size)
                .overlay {
                    if selected {
                        Circle().stroke(KORATheme.accent, lineWidth: 3).frame(width: size + 8, height: size + 8)
                    }
                }
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MetroLineData.displayName(for: name, language: lang))
    }

    private func attractionPin(_ attraction: Attraction) -> some View {
        let selected = pick == .attraction(attraction)
        return Button {
            pick = selected ? nil : .attraction(attraction)
        } label: {
            Image(systemName: attraction.category.symbol)
                .font(.caption).fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: selected ? 34 : 26, height: selected ? 34 : 26)
                .background(KORATheme.accent, in: Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(attraction.displayName(lang))
    }

    @ViewBuilder private var pickCard: some View {
        if let pick {
            Group {
                switch pick {
                case .station(let name): stationCard(name)
                case .attraction(let attraction):
                    AttractionCard(attraction: attraction, lang: lang, excluding: excluding, onPick: onPick)
                }
            }
            .padding(16)
            .frame(maxWidth: 560)
            .background(KORATheme.background, in: RoundedRectangle(cornerRadius: KORATheme.radiusXL))
            .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func stationCard(_ name: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(Self.stationLines[name] ?? [], id: \.self) { num in
                    Text(MetroLineData.lineBadgeText(num))
                        .font(.caption).fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .frame(minWidth: 22, minHeight: 20)
                        .background(MetroLineData.lineColor(num), in: Capsule())
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(MetroLineData.displayName(for: name, language: lang))
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(KORATheme.labelPrimary)
                    if let sub = MetroLineData.subtitle(for: name, language: lang) {
                        Text(sub)
                            .font(.subheadline)
                            .foregroundStyle(KORATheme.labelSecondary)
                    }
                }
            }
            Button { onPick(name) } label: {
                Text(NavLoc.chooseThisStation.resolved(lang))
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(KORATheme.accent, in: RoundedRectangle(cornerRadius: KORATheme.radiusMD))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 위치

    private func moveToUser() async {
        guard let coord = try? await locationService.requestOnce() else { return }
        // 한국 밖(여행 전 집에서 열어 본 경우)이면 권역 지도를 그대로 둔다.
        guard (33...39).contains(coord.latitude), (124...132).contains(coord.longitude) else { return }
        let region = MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
        position = .region(region)
        visible = region
    }

    /// 권역마다 한가운데 역에서 시작한다.
    private static func startRegion(for category: MetroCategory) -> MKCoordinateRegion {
        let hub: String
        switch category {
        case .seoulGyeonggi: hub = "시청"
        case .incheon:       hub = "인천시청"
        case .busan:         hub = "서면"
        case .daegu:         hub = "반월당"
        case .gwangju:       hub = "문화전당"
        case .daejeon:       hub = "시청(대전)"
        }
        let c = MetroLineData.stationCoordinates[hub] ?? (lat: 37.5663, lng: 126.9779)
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: c.lat, longitude: c.lng),
                                  span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06))
    }

    // MARK: - 역 → 노선 (한 번만 만든다)

    /// 좌표가 있는 모든 역의 노선 번호.
    private static let stationLines: [String: [Int]] = {
        var map: [String: [Int]] = [:]
        for line in MetroLineData.seoulLines {
            for route in line.routes {
                for s in route.stations where MetroLineData.stationCoordinates[s] != nil {
                    if !(map[s]?.contains(line.number) ?? false) { map[s, default: []].append(line.number) }
                }
            }
        }
        return map
    }()

    /// 그리는 순서가 매번 같도록 이름 순으로.
    private static let mapStations: [String] = stationLines.keys.sorted()

    private static func coordinate(_ name: String) -> CLLocationCoordinate2D {
        let c = MetroLineData.stationCoordinates[name] ?? (lat: 0, lng: 0)
        return CLLocationCoordinate2D(latitude: c.lat, longitude: c.lng)
    }

    private static func isTransfer(_ name: String) -> Bool { (stationLines[name]?.count ?? 0) > 1 }
}
