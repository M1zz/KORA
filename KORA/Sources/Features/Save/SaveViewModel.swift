import SwiftUI
import Observation

@MainActor
@Observable
final class SaveViewModel {

    // MARK: URL Parse State
    var urlInput: String = ""
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var parsedPlace: Place? = nil
    var showClipboardPrompt: Bool = false
    var clipboardURL: String? = nil

    // MARK: Manual Name Prompt (Instagram can't be scraped)
    var showManualNamePrompt: Bool = false
    var manualNameInput: String = ""

    // MARK: Kakao Search State
    var searchQuery: String = ""
    var searchResults: [KakaoDocument] = []
    var isSearching: Bool = false
    var showSearchResults: Bool = false

    private let parser = LinkParserService()
    private let kakao  = KakaoLocalService()
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
        parsedPlace = nil

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
            searchResults = try await kakao.searchKeyword(query)
            showSearchResults = true
            // imageURL / sourceURL을 임시 저장해서 저장 시 사용
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

        // 2. Fallback for places outside the local table's coverage
        do {
            guard let doc = try await kakao.searchNearestSubway(
                latitude: place.coordinate.latitude,
                longitude: place.coordinate.longitude
            ) else { return }
            var updated = place
            updated.nearestStation = Self.normalizeStationName(doc.placeName)
            store.update(updated)
        } catch {
            // ignore — display will fall back to empty
        }
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

    // MARK: - Direct Save (기존 OG 파싱 결과 직접 저장)

    func confirmSave() {
        guard let place = parsedPlace else { return }
        store.add(place)
        parsedPlace = nil
        urlInput = ""
    }

    func dismissParsed() {
        parsedPlace = nil
        urlInput = ""
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

    // MARK: - Delete

    func delete(at offsets: IndexSet) { store.delete(at: offsets) }
    func delete(_ place: Place)       { store.delete(place) }

    // MARK: - Filter

    func places(for category: PlaceCategory?) -> [Place] {
        store.filtered(by: category)
    }

    // MARK: - Private

    private var pendingImageURL: String? = nil
    private var pendingSourceURL: String? = nil
}
