import SwiftUI
import MapKit

// MARK: - Place Map View

struct PlaceMapView: View {
    let places: [Place]
    @Binding var selectedPlace: Place?
    /// Called when user taps "저장" on a Kakao search result pin.
    var onSaveDoc: ((KakaoDocument) -> Void)? = nil

    // MARK: Map state
    @State private var cameraPosition: MapCameraPosition
    @State private var mapSelection: String? = nil

    // MARK: Search state
    @State private var searchText: String = ""
    @State private var searchResults: [KakaoDocument] = []
    @State private var isSearching: Bool = false
    @State private var searchBarExpanded: Bool = false
    @FocusState private var searchFocused: Bool

    private let search = PlaceSearchService()
    private var locatablePlaces: [Place] { places.filter { $0.hasLocation } }

    // Decode which type is selected from the prefixed String tag
    private var selectedSavedPlace: Place? {
        guard let sel = mapSelection, sel.hasPrefix("p:") else { return nil }
        let id = String(sel.dropFirst(2))
        return locatablePlaces.first { $0.id.uuidString == id }
    }
    private var selectedSearchDoc: KakaoDocument? {
        guard let sel = mapSelection, sel.hasPrefix("k:") else { return nil }
        let id = String(sel.dropFirst(2))
        return searchResults.first { $0.id == id }
    }

    init(places: [Place], selectedPlace: Binding<Place?>, onSaveDoc: ((KakaoDocument) -> Void)? = nil) {
        self.places = places
        self._selectedPlace = selectedPlace
        self.onSaveDoc = onSaveDoc

        let saved = places.filter { $0.hasLocation }
        if saved.isEmpty {
            _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
            )))
        } else {
            let lats = saved.map(\.coordinate.latitude)
            let lons = saved.map(\.coordinate.longitude)
            let center = CLLocationCoordinate2D(
                latitude: (lats.min()! + lats.max()!) / 2,
                longitude: (lons.min()! + lons.max()!) / 2
            )
            let span = MKCoordinateSpan(
                latitudeDelta: max(0.06, (lats.max()! - lats.min()!) * 1.6),
                longitudeDelta: max(0.06, (lons.max()! - lons.min()!) * 1.6)
            )
            _cameraPosition = State(initialValue: .region(MKCoordinateRegion(center: center, span: span)))
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            // MARK: Map
            Map(position: $cameraPosition, selection: $mapSelection) {
                // Saved places — category-colored circular pins
                ForEach(locatablePlaces) { place in
                    Annotation(place.name, coordinate: place.coordinate.clLocation, anchor: .bottom) {
                        PlaceMapPin(
                            category: place.category,
                            isSelected: selectedSavedPlace?.id == place.id
                        )
                    }
                    .tag("p:\(place.id.uuidString)")
                }
                // Kakao search results — accent-colored map pins
                ForEach(searchResults) { doc in
                    Annotation(doc.placeName, coordinate: doc.coordinate.clLocation, anchor: .bottom) {
                        SearchResultPin(isSelected: selectedSearchDoc?.id == doc.id)
                    }
                    .tag("k:\(doc.id)")
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea(.all)  // map extends edge-to-edge; overlays below respect insets
            .onChange(of: mapSelection) { _, sel in
                if let sel, sel.hasPrefix("p:") {
                    let id = String(sel.dropFirst(2))
                    withAnimation(.spring(response: 0.35)) {
                        selectedPlace = locatablePlaces.first { $0.id.uuidString == id }
                    }
                } else if sel == nil || sel?.hasPrefix("k:") == true {
                    withAnimation { selectedPlace = nil }
                }
            }

            // MARK: Floating Search Bar
            floatingSearchBar
                .padding(.horizontal, 12)
                .padding(.top, 8)

            // MARK: Search result count badge
            if !searchResults.isEmpty && !searchFocused {
                VStack {
                    Spacer().frame(height: 64)
                    HStack {
                        Text("\(searchResults.count)개 결과")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(KORATheme.accent)
                            .clipShape(Capsule())
                            .shadow(color: KORATheme.accent.opacity(0.4), radius: 6, y: 2)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    Spacer()
                }
            }

            // MARK: Bottom Card — search result or saved place
            VStack {
                Spacer()
                if let doc = selectedSearchDoc {
                    searchResultCard(doc)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if let place = selectedSavedPlace ?? selectedPlace {
                    savedPlaceCard(place)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: mapSelection)
        }
    }

    // MARK: - Floating Search Bar (collapsible)

    @ViewBuilder
    private var floatingSearchBar: some View {
        if searchBarExpanded {
            HStack(spacing: 8) {
                expandedSearchField
                Button("취소") {
                    searchFocused = false
                    withAnimation(.spring(response: 0.3)) {
                        searchBarExpanded = false
                    }
                    clearSearch()
                }
                .font(.body)
                .foregroundStyle(KORATheme.accent)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        } else {
            HStack {
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        searchBarExpanded = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        searchFocused = true
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.body).fontWeight(.semibold)
                        .foregroundStyle(KORATheme.labelPrimary)
                        .frame(width: 44, height: 44)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
                }
                .accessibilityLabel("검색")
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var expandedSearchField: some View {
        HStack(spacing: 8) {
            if isSearching {
                ProgressView()
                    .scaleEffect(0.8)
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: searchResults.isEmpty ? "magnifyingglass" : "magnifyingglass.circle.fill")
                    .font(.body)
                    .foregroundStyle(searchResults.isEmpty ? KORATheme.labelTertiary : KORATheme.accent)
            }

            TextField("성심당, 홍대 카페, 경복궁...", text: $searchText)
                .font(.body)
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit { Task { await performSearch() } }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                    mapSelection = nil
                    selectedPlace = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(KORATheme.labelTertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
    }

    // MARK: - Search Result Bottom Card

    @ViewBuilder
    private func searchResultCard(_ doc: KakaoDocument) -> some View {
        let cat = PlaceCategory.from(kakaoCode: doc.categoryGroupCode)
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 40, height: 4)
                .padding(.top, 10)

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(KORATheme.categoryColor(cat).opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: cat.systemImage)
                        .font(.title3)
                        .foregroundStyle(KORATheme.categoryColor(cat))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(doc.placeName)
                        .font(.body).fontWeight(.semibold)
                        .foregroundStyle(KORATheme.labelPrimary)
                    Text(doc.displayAddress)
                        .font(.body)
                        .foregroundStyle(KORATheme.labelSecondary)
                        .lineLimit(1)
                    if !doc.categoryName.isEmpty {
                        Text(doc.categoryName.components(separatedBy: " > ").last ?? doc.categoryName)
                            .font(.caption)
                            .foregroundStyle(KORATheme.labelTertiary)
                    }
                }

                Spacer()

                // Save button
                Button {
                    onSaveDoc?(doc)
                    withAnimation { mapSelection = nil }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: "bookmark.fill")
                            .font(.body)
                        Text("저장")
                            .font(.caption2).fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(KORATheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(onSaveDoc == nil)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 16, y: -2)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Saved Place Bottom Card

    @ViewBuilder
    private func savedPlaceCard(_ place: Place) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 40, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 4)
            PlaceCardView(place: place)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 16, y: -2)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Search Actions

    private func performSearch() async {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        isSearching = true
        searchFocused = false
        mapSelection = nil
        defer { isSearching = false }

        if let docs = try? await search.searchKeyword(q, size: 15) {
            withAnimation {
                searchResults = docs
                if let first = docs.first {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: first.coordinate.clLocation,
                        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                    ))
                }
            }
        }
    }

    private func clearSearch() {
        searchText = ""
        searchResults = []
        mapSelection = nil
        selectedPlace = nil
    }
}

// MARK: - Search Result Map Pin (accent color)

struct SearchResultPin: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(KORATheme.accent.opacity(0.2))
                    .frame(width: 52, height: 52)
            }
            Circle()
                .fill(KORATheme.accent)
                .frame(width: isSelected ? 38 : 30, height: isSelected ? 38 : 30)
                .shadow(color: KORATheme.accent.opacity(0.5), radius: isSelected ? 8 : 4)
            Image(systemName: "mappin")
                .font(.system(size: isSelected ? 16 : 13, weight: .semibold))
                .foregroundStyle(.white)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Saved Place Map Pin (category color, unchanged)

struct PlaceMapPin: View {
    let category: PlaceCategory
    let isSelected: Bool

    var body: some View {
        ZStack {
            if isSelected {
                Circle()
                    .fill(KORATheme.categoryColor(category).opacity(0.25))
                    .frame(width: 56, height: 56)
            }
            Circle()
                .fill(KORATheme.categoryColor(category))
                .frame(width: isSelected ? 42 : 34, height: isSelected ? 42 : 34)
                .shadow(
                    color: KORATheme.categoryColor(category).opacity(0.5),
                    radius: isSelected ? 8 : 4
                )
            Image(systemName: category.systemImage)
                .font(.system(size: isSelected ? 18 : 15, weight: .semibold))
                .foregroundStyle(.white)
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
}
