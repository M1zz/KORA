import Foundation

// MARK: - Place Search Service
// Tries Kakao Local first (richer data, location-biased), falls back to Naver
// when Kakao is unavailable (key disabled, network, etc).

final class PlaceSearchService {
    private let kakao  = KakaoLocalService()
    private let naver  = NaverLocalService()
    private let detail = KakaoPlaceDetailService()

    func searchKeyword(
        _ query: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        size: Int = 15
    ) async throws -> [KakaoDocument] {
        do {
            return try await kakao.searchKeyword(query, latitude: latitude, longitude: longitude, size: size)
        } catch {
            return try await naver.searchKeyword(query, latitude: latitude, longitude: longitude, size: size)
        }
    }

    /// Best-effort representative image lookup. Returns nil silently on failure
    /// so callers can fire-and-forget when enriching a saved place.
    func firstImageThumbnail(query: String) async -> String? {
        try? await naver.firstImageThumbnail(query: query)
    }

    /// Resolves a representative image for a saved place. Prefers Kakao's
    /// official place photo (stable, no ads, matches the venue) and only
    /// falls back to Naver image search when no Kakao photo exists — Naver
    /// results drift daily and sometimes pull in unrelated/promoted images.
    func bestImage(for place: Place) async -> String? {
        if let mapURL = place.kakaoMapURL, !mapURL.isEmpty,
           let det = try? await detail.fetch(kakaoMapURL: mapURL),
           let photo = det.mainPhotoURL, !photo.isEmpty {
            return photo
        }
        let query = place.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }
        return await firstImageThumbnail(query: query)
    }

    /// Full gallery for a saved place — Kakao official photos first (when
    /// the place has a `kakaoMapURL`), then Naver image-search results
    /// appended after dedup. We show both sources because Kakao's auto
    /// photo doesn't always match what users see on KakaoMap, so giving
    /// them several options is more honest than one mystery pick.
    func allPhotos(for place: Place) async -> [String] {
        var photos: [String] = []

        // 1. Kakao official photos (only if we have a place id to fetch)
        if let mapURL = place.kakaoMapURL, !mapURL.isEmpty,
           let det = try? await detail.fetch(kakaoMapURL: mapURL) {
            photos.append(contentsOf: det.photos.filter { !$0.isEmpty })
        }

        // 2. Naver image search — append additional photos (skip duplicates)
        let query = place.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty,
           let naverPhotos = try? await naver.imageThumbnails(query: query, display: 6) {
            for p in naverPhotos where !p.isEmpty && !photos.contains(p) {
                photos.append(p)
            }
        }

        return photos
    }

    /// Nearest subway station lookup — Kakao only (no Naver equivalent).
    /// Returns nil silently when Kakao is unavailable; callers fall back to
    /// the bundled `MetroLineData` table.
    func nearestSubway(latitude: Double, longitude: Double) async -> KakaoDocument? {
        try? await kakao.searchNearestSubway(latitude: latitude, longitude: longitude)
    }
}
