import Foundation

// MARK: - Naver Local Search Service
// Adapts Naver's response shape to `KakaoDocument` so the rest of the app
// (which already speaks "KakaoDocument") works unchanged.

final class NaverLocalService {

    enum ServiceError: LocalizedError {
        case keysNotSet
        case network(String)

        var errorDescription: String? {
            switch self {
            case .keysNotSet:    return "Naver API キーが未設定です (NaverConfig.swift を確認)"
            case .network(let m): return m
            }
        }
    }

    private let localBase = "https://openapi.naver.com/v1/search/local.json"
    private let imageBase = "https://openapi.naver.com/v1/search/image.json"

    // MARK: - Keyword Search → KakaoDocument

    /// Naver Local Search caps `display` at 5, so `size` is clamped. Location
    /// arguments are accepted for signature parity with Kakao but ignored —
    /// Naver's local endpoint has no location-bias parameter.
    func searchKeyword(
        _ query: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        size: Int = 5
    ) async throws -> [KakaoDocument] {
        try checkKeys()

        let display = max(1, min(size, 5))
        let items: [URLQueryItem] = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "display", value: "\(display)"),
            URLQueryItem(name: "sort", value: "random")
        ]

        let raw: NaverLocalResponse = try await fetch(base: localBase, queryItems: items)
        return raw.items.map { $0.toKakaoDocument() }
    }

    // MARK: - First Image Thumbnail

    /// Returns the URL of the first image search result for the given query,
    /// or nil if Naver has nothing usable. Used to enrich saved places with
    /// a representative image.
    func firstImageThumbnail(query: String) async throws -> String? {
        try await imageThumbnails(query: query, display: 1).first
    }

    /// Returns up to `display` (max 10) image search thumbnails for the
    /// given query. Used to power the multi-photo gallery on saved places
    /// when Kakao has no official photos to show.
    func imageThumbnails(query: String, display: Int = 5) async throws -> [String] {
        try checkKeys()
        let clamped = max(1, min(display, 10))
        let items: [URLQueryItem] = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "display", value: "\(clamped)"),
            URLQueryItem(name: "sort", value: "sim"),
            URLQueryItem(name: "filter", value: "medium")
        ]
        let raw: NaverImageResponse = try await fetch(base: imageBase, queryItems: items)
        return raw.items.map { $0.thumbnail }
    }

    // MARK: - Private

    private func checkKeys() throws {
        guard NaverConfig.clientID != "YOUR_NAVER_CLIENT_ID",
              !NaverConfig.clientID.isEmpty,
              NaverConfig.clientSecret != "YOUR_NAVER_CLIENT_SECRET",
              !NaverConfig.clientSecret.isEmpty
        else { throw ServiceError.keysNotSet }
    }

    private func fetch<T: Decodable>(base: String, queryItems: [URLQueryItem]) async throws -> T {
        var comps = URLComponents(string: base)!
        comps.queryItems = queryItems
        guard let url = comps.url else { throw ServiceError.network("URL 생성 실패") }

        var req = URLRequest(url: url)
        req.setValue(NaverConfig.clientID,     forHTTPHeaderField: "X-Naver-Client-Id")
        req.setValue(NaverConfig.clientSecret, forHTTPHeaderField: "X-Naver-Client-Secret")
        req.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                throw ServiceError.network("Invalid response")
            }
            guard (200..<300).contains(http.statusCode) else {
                throw ServiceError.network("Naver HTTP \(http.statusCode)")
            }
            return try JSONDecoder().decode(T.self, from: data)
        } catch let e as ServiceError { throw e
        } catch { throw ServiceError.network(error.localizedDescription) }
    }
}

// MARK: - Naver Response Types

private struct NaverLocalResponse: Decodable {
    let items: [NaverLocalItem]
}

private struct NaverLocalItem: Decodable {
    let title: String
    let link: String
    let category: String
    let telephone: String
    let address: String
    let roadAddress: String
    let mapx: String   // longitude * 10_000_000
    let mapy: String   // latitude * 10_000_000

    func toKakaoDocument() -> KakaoDocument {
        let cleanedName = NaverLocalItem.stripHTML(title)
        let lng = (Double(mapx) ?? 0) / 10_000_000.0
        let lat = (Double(mapy) ?? 0) / 10_000_000.0
        // Naver has no stable id; derive a deterministic one so re-saving the
        // same place doesn't churn the Identifiable hash.
        let derivedID = "naver:\(cleanedName)|\(roadAddress.isEmpty ? address : roadAddress)"

        return KakaoDocument(
            id: derivedID,
            placeName: cleanedName,
            categoryName: category,
            categoryGroupCode: NaverLocalItem.mapCategoryCode(from: category),
            phone: telephone,
            addressName: address,
            roadAddressName: roadAddress,
            x: String(lng),
            y: String(lat),
            placeUrl: link,
            distance: ""
        )
    }

    static func stripHTML(_ s: String) -> String {
        s.replacingOccurrences(of: "<b>",  with: "")
         .replacingOccurrences(of: "</b>", with: "")
         .replacingOccurrences(of: "&amp;",  with: "&")
         .replacingOccurrences(of: "&lt;",   with: "<")
         .replacingOccurrences(of: "&gt;",   with: ">")
         .replacingOccurrences(of: "&quot;", with: "\"")
    }

    /// Coarse mapping of Naver's slash-separated category strings to the
    /// Kakao category codes the rest of the app understands.
    static func mapCategoryCode(from category: String) -> String {
        if category.contains("카페")                          { return "CE7" }
        if category.contains("음식") || category.contains("맛집") { return "FD6" }
        if category.contains("마트") || category.contains("편의점") || category.contains("쇼핑") { return "MT1" }
        if category.contains("관광") || category.contains("여행") || category.contains("공원") || category.contains("박물관") { return "AT4" }
        if category.contains("문화") || category.contains("공연") || category.contains("영화") { return "CT1" }
        return ""
    }
}

private struct NaverImageResponse: Decodable {
    let items: [NaverImageItem]
}

private struct NaverImageItem: Decodable {
    let thumbnail: String
}
