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

        isLoading = true
        errorMessage = nil
        parsedPlace = nil

        do {
            let place = try await parser.parse(urlString: url)
            // OG 파싱 성공 → 추출된 이름으로 Kakao 검색
            searchQuery = place.name
            await searchKakao(imageURLFallback: place.imageURL, sourceURL: url)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
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
