import Foundation

// MARK: - Response Models

struct KakaoSearchResponse: Decodable {
    let documents: [KakaoDocument]
}

struct KakaoDocument: Decodable, Identifiable {
    let id: String
    let placeName: String
    let categoryName: String
    let categoryGroupCode: String
    let phone: String
    let addressName: String
    let roadAddressName: String
    let x: String   // 경도 (longitude)
    let y: String   // 위도 (latitude)
    let placeUrl: String
    let distance: String

    enum CodingKeys: String, CodingKey {
        case id
        case placeName        = "place_name"
        case categoryName     = "category_name"
        case categoryGroupCode = "category_group_code"
        case phone
        case addressName      = "address_name"
        case roadAddressName  = "road_address_name"
        case x, y
        case placeUrl         = "place_url"
        case distance
    }

    var coordinate: Coordinate {
        Coordinate(latitude: Double(y) ?? 0, longitude: Double(x) ?? 0)
    }

    var displayAddress: String {
        roadAddressName.isEmpty ? addressName : roadAddressName
    }

    func toPlace(sourceURL: String? = nil, imageURL: String? = nil) -> Place {
        Place(
            name:      placeName,
            nameJP:    placeName,
            category:  PlaceCategory.from(kakaoCode: categoryGroupCode),
            address:   displayAddress,
            addressJP: displayAddress,
            coordinate: coordinate,
            nearestStation: "",
            sourceURL: sourceURL,
            imageURL:  imageURL
        )
    }
}

// MARK: - Kakao Category → PlaceCategory

extension PlaceCategory {
    static func from(kakaoCode: String) -> PlaceCategory {
        switch kakaoCode {
        case "FD6": return .restaurant    // 음식점
        case "CE7": return .cafe          // 카페
        case "MT1", "CS2": return .shopping // 마트, 편의점
        case "AT4": return .attraction    // 관광명소
        case "CT1": return .entertainment // 문화시설
        default:    return .attraction
        }
    }
}

// MARK: - Service

final class KakaoLocalService {

    enum ServiceError: LocalizedError {
        case apiKeyNotSet
        case network(String)

        var errorDescription: String? {
            switch self {
            case .apiKeyNotSet: return "Kakao API キーが未設定です (KakaoConfig.swift を確認)"
            case .network(let m): return m
            }
        }
    }

    private let base = "https://dapi.kakao.com/v2/local"

    // MARK: - 키워드 검색

    func searchKeyword(
        _ query: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        size: Int = 15
    ) async throws -> [KakaoDocument] {
        try checkKey()

        var items: [URLQueryItem] = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "size", value: "\(size)")
        ]
        if let lat = latitude, let lng = longitude {
            items += [
                URLQueryItem(name: "y", value: "\(lat)"),
                URLQueryItem(name: "x", value: "\(lng)"),
                URLQueryItem(name: "sort", value: "distance")
            ]
        }
        return try await fetch(path: "search/keyword.json", queryItems: items)
    }

    // MARK: - 카테고리 주변 검색

    func searchNearby(
        latitude: Double,
        longitude: Double,
        radius: Int = 1000,
        categoryCodes: [String] = ["FD6", "CE7", "AT4", "CT1"]
    ) async throws -> [KakaoDocument] {
        try checkKey()

        var all: [KakaoDocument] = []
        for code in categoryCodes {
            let items: [URLQueryItem] = [
                URLQueryItem(name: "category_group_code", value: code),
                URLQueryItem(name: "x", value: "\(longitude)"),
                URLQueryItem(name: "y", value: "\(latitude)"),
                URLQueryItem(name: "radius", value: "\(radius)"),
                URLQueryItem(name: "size", value: "5")
            ]
            if let docs = try? await fetch(path: "search/category.json", queryItems: items) {
                all += docs
            }
        }
        return all
    }

    // MARK: - Private

    private func checkKey() throws {
        guard KakaoConfig.restAPIKey != "YOUR_KAKAO_REST_API_KEY",
              !KakaoConfig.restAPIKey.isEmpty
        else { throw ServiceError.apiKeyNotSet }
    }

    private func fetch(path: String, queryItems: [URLQueryItem]) async throws -> [KakaoDocument] {
        var comps = URLComponents(string: "\(base)/\(path)")!
        comps.queryItems = queryItems
        guard let url = comps.url else { throw ServiceError.network(String(localized: "URLの生成に失敗しました")) }

        var req = URLRequest(url: url)
        req.setValue("KakaoAK \(KakaoConfig.restAPIKey)", forHTTPHeaderField: "Authorization")
        req.setValue("sdk/2.22.0 os/ios-17.0 sdk_type/swift origin/com.kora.leeo", forHTTPHeaderField: "KA")
        req.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                throw ServiceError.network(String(localized: "不正なレスポンス"))
            }
            guard (200..<300).contains(http.statusCode) else {
                throw ServiceError.network("HTTP \(http.statusCode)")
            }
            return try JSONDecoder().decode(KakaoSearchResponse.self, from: data).documents
        } catch let e as ServiceError { throw e
        } catch { throw ServiceError.network(error.localizedDescription) }
    }
}
