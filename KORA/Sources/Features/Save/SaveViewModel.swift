import SwiftUI
import Observation

@MainActor
@Observable
final class SaveViewModel {

    // MARK: URL Parse State
    var urlInput: String = ""
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var showClipboardPrompt: Bool = false
    var clipboardURL: String? = nil

    // MARK: Manual Name Prompt (Instagram can't be scraped)
    var showManualNamePrompt: Bool = false
    var manualNameInput: String = ""
    /// Caption text received from Share Extension — shown as suggestion chips
    var pendingCaptionText: String? = nil

    // MARK: Kakao Search State
    var searchQuery: String = ""
    var searchResults: [KakaoDocument] = []
    var isSearching: Bool = false
    var showSearchResults: Bool = false

    private let parser = LinkParserService()
    private let search = PlaceSearchService()
    private let store  = PlaceStore.shared

    // MARK: - Computed

    var savedPlaces: [Place] { store.places }

    // MARK: - URL Parse → Kakao Search

    func parseURL() async {
        let url = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else { return }

        // Instagram blocks server-side scraping — skip OG fetch entirely
        // and ask the user to type the place name so we can search Kakao.
        let isInstagram = url.contains("instagram.com") || url.contains("instagr.am")
        if isInstagram {
            pendingSourceURL = url
            showManualNamePrompt = true
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let place = try await parser.parse(urlString: url)
            searchQuery = place.name
            await searchKakao(imageURLFallback: place.imageURL, sourceURL: url)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Manual Name Entry (after Instagram URL detection)

    func submitManualName() async {
        let name = manualNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        searchQuery = name
        manualNameInput = ""
        showManualNamePrompt = false
        await searchKakao(sourceURL: pendingSourceURL)
    }

    /// Saves the Instagram URL immediately without coordinates — just a named bookmark.
    func saveQuickLink(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let place = Place(
            name: trimmed,
            nameJP: trimmed,
            category: .attraction,
            address: "",
            addressJP: "",
            coordinate: Coordinate(latitude: 0, longitude: 0),
            nearestStation: "",
            sourceURL: pendingSourceURL
        )
        store.add(place)
        manualNameInput = ""
        showManualNamePrompt = false
        pendingSourceURL = nil
        urlInput = ""
    }

    func dismissManualPrompt() {
        showManualNamePrompt = false
        manualNameInput = ""
        pendingSourceURL = nil
        urlInput = ""
    }

    // MARK: - Kakao Keyword Search

    func searchKakao(imageURLFallback: String? = nil, sourceURL: String? = nil) async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isSearching = true
        errorMessage = nil

        do {
            searchResults = try await search.searchKeyword(query)
            showSearchResults = true
            pendingImageURL = imageURLFallback
            pendingSourceURL = sourceURL
        } catch {
            errorMessage = error.localizedDescription
        }

        isSearching = false
    }

    func saveFromKakao(_ doc: KakaoDocument) {
        let place = doc.toPlace(sourceURL: pendingSourceURL, imageURL: pendingImageURL)
        store.add(place)
        dismissSearch()
        urlInput = ""
        Task { await self.attachNearestStation(for: place) }
        Task { await self.attachPhotos(for: place) }
    }

    /// Fetches the full photo gallery (Kakao official photos + Naver image
    /// search) and stores it on the place. Also sets `imageURL` (the cover)
    /// to the first photo when it isn't already set. Silent on failure.
    private func attachPhotos(for place: Place) async {
        if let list = place.photoURLs, !list.isEmpty { return }
        let photos = await search.allPhotos(for: place)
        guard !photos.isEmpty else { return }
        guard let stillCurrent = store.places.first(where: { $0.id == place.id }) else { return }
        var updated = stillCurrent
        updated.photoURLs = photos
        if updated.imageURL == nil || updated.imageURL?.isEmpty == true {
            updated.imageURL = photos.first
        }
        store.update(updated)
    }

    /// One-shot: for every saved place missing a gallery, fetch one in the
    /// background. Staggered so we don't hit Naver's rate limit.
    func backfillMissingImages() {
        let candidates = store.places.filter { ($0.photoURLs ?? []).isEmpty }
        guard !candidates.isEmpty else { return }
        Task {
            for place in candidates {
                await self.attachPhotos(for: place)
                try? await Task.sleep(for: .milliseconds(300))
            }
        }
    }

    /// Resolves coordinates / address / Kakao Map URL for places that were
    /// saved without them (typically Instagram quick-links). One-shot Kakao
    /// keyword search: name (+ nearestStation if set) → first hit. Silent
    /// on no match. Side effect: also computes nearestStation if it's empty
    /// once coords are in place.
    private func attachCoordinatesIfMissing(for place: Place) async {
        guard !place.hasLocation else { return }
        let name = place.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            debugLog("[CoordBackfill] skip '\(place.name)' — no name to search")
            return
        }

        // Fold the user-tagged station into the query when present —
        // "가게이름 청담" is far more specific than the bare name and avoids
        // matching a same-named venue in a different neighborhood.
        let parts = [name, place.nearestStation.trimmingCharacters(in: .whitespacesAndNewlines)]
        let query = parts.filter { !$0.isEmpty }.joined(separator: " ")
        debugLog("[CoordBackfill] searching '\(query)' for place id=\(place.id.uuidString.prefix(8))")

        let docs = (try? await search.searchKeyword(query, size: 5)) ?? []
        debugLog("[CoordBackfill] got \(docs.count) results")
        guard let best = docs.first else {
            debugLog("[CoordBackfill] no result for '\(query)' — exit info will stay unavailable")
            return
        }
        guard best.coordinate.latitude != 0 || best.coordinate.longitude != 0 else {
            debugLog("[CoordBackfill] first result has empty coords — skip")
            return
        }

        guard let current = store.places.first(where: { $0.id == place.id }) else { return }
        var updated = current
        updated.coordinate = best.coordinate
        debugLog("[CoordBackfill] backfilled '\(name)' → (\(best.coordinate.latitude),\(best.coordinate.longitude)) station=\(updated.nearestStation)")
        if updated.address.isEmpty {
            updated.address = best.displayAddress
            updated.addressJP = best.displayAddress
        }
        if updated.kakaoMapURL == nil, !best.placeUrl.isEmpty {
            updated.kakaoMapURL = best.placeUrl
        }
        store.update(updated)

        if updated.nearestStation.isEmpty {
            await attachNearestStation(for: updated)
        }
    }

    /// One-shot: for every saved place with a name but no GPS coords, try
    /// to resolve them via Kakao so exit recommendations / map pins work.
    /// Staggered to stay within rate limits.
    func backfillMissingCoordinates() {
        let candidates = store.places.filter { !$0.hasLocation && !$0.name.isEmpty }
        debugLog("[CoordBackfill] running — \(candidates.count) candidate(s)")
        guard !candidates.isEmpty else { return }
        Task {
            for place in candidates {
                await self.attachCoordinatesIfMissing(for: place)
                try? await Task.sleep(for: .milliseconds(400))
            }
        }
    }

    /// Resolves the closest subway station and updates the Place in the store.
    /// Tries the bundled local coordinate table first (instant, offline) and
    /// falls back to Kakao SW8 search only when nothing's nearby locally.
    /// Silent on failure — `nearestStation` simply stays empty.
    private func attachNearestStation(for place: Place) async {
        // 1. Local hardcoded coordinates (covers all known stations)
        if let local = MetroLineData.nearestStation(
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude
        ) {
            var updated = place
            updated.nearestStation = local.name
            store.update(updated)
            return
        }

        // 2. Fallback for places outside the local table's coverage.
        // Silent on Kakao failure (e.g., service disabled) — station stays empty.
        guard let doc = await search.nearestSubway(
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude
        ) else { return }
        var updated = place
        updated.nearestStation = Self.normalizeStationName(doc.placeName)
        store.update(updated)
    }

    /// Kakao returns names like "강남역", "잠실(송파구청)역". Strip the trailing
    /// "역" and any parenthetical so we get the canonical name used in
    /// `MetroLineData` (e.g., "강남", "잠실").
    static func normalizeStationName(_ raw: String) -> String {
        var name = raw
        if let paren = name.firstIndex(of: "(") {
            name = String(name[..<paren])
        }
        name = name.trimmingCharacters(in: .whitespaces)
        if name.hasSuffix("역") {
            name = String(name.dropLast())
        }
        return name
    }

    func dismissSearch() {
        showSearchResults = false
        searchResults = []
        pendingImageURL = nil
        pendingSourceURL = nil
    }

    // MARK: - Clipboard

    func checkClipboard() {
        guard let url = parser.detectFromClipboard() else { return }
        clipboardURL = url
        showClipboardPrompt = true
    }

    func acceptClipboardURL() {
        guard let url = clipboardURL else { return }
        urlInput = url
        showClipboardPrompt = false
        clipboardURL = nil
        Task { await parseURL() }
    }

    func dismissClipboard() {
        showClipboardPrompt = false
        clipboardURL = nil
    }

    // MARK: - Delete / Update

    func delete(at offsets: IndexSet) { store.delete(at: offsets) }
    func delete(_ place: Place)       { store.delete(place) }
    func update(_ place: Place)       { store.update(place) }

    // MARK: - Filter

    func places(for category: PlaceCategory?) -> [Place] {
        store.filtered(by: category)
    }

    /// Groups places by category for the list view. Within each category,
    /// places are ordered by most-recently saved first.
    func placesGroupedByCategory(filter: String = "") -> [(category: PlaceCategory, places: [Place])] {
        var base = store.places
        if !filter.isEmpty {
            base = base.filter {
                $0.name.localizedCaseInsensitiveContains(filter) ||
                $0.address.localizedCaseInsensitiveContains(filter) ||
                $0.nearestStation.localizedCaseInsensitiveContains(filter)
            }
        }
        var groups: [PlaceCategory: [Place]] = [:]
        for place in base { groups[place.category, default: []].append(place) }
        return PlaceCategory.allCases.compactMap { cat in
            guard let list = groups[cat], !list.isEmpty else { return nil }
            return (cat, list.sorted { $0.savedAt > $1.savedAt })
        }
    }

    // MARK: - Private

    private var pendingImageURL: String? = nil
    private var pendingSourceURL: String? = nil
}
