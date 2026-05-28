import Foundation
import CoreLocation

// MARK: - Place Model

struct Place: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var nameJP: String
    var category: PlaceCategory
    var address: String
    var addressJP: String
    var coordinate: Coordinate
    var openingHours: OpeningHours?
    var priceRange: PriceRange
    var nearestStation: String
    var tags: [String]
    var sourceURL: String?
    var imageURL: String?
    var waitMinutes: Int?
    var isOpen: Bool
    var savedAt: Date
    var phone: String?
    var kakaoMapURL: String?

    init(
        id: UUID = UUID(),
        name: String,
        nameJP: String,
        category: PlaceCategory,
        address: String,
        addressJP: String,
        coordinate: Coordinate,
        openingHours: OpeningHours? = nil,
        priceRange: PriceRange = .moderate,
        nearestStation: String = "",
        tags: [String] = [],
        sourceURL: String? = nil,
        imageURL: String? = nil,
        waitMinutes: Int? = nil,
        isOpen: Bool = true,
        savedAt: Date = Date(),
        phone: String? = nil,
        kakaoMapURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.nameJP = nameJP
        self.category = category
        self.address = address
        self.addressJP = addressJP
        self.coordinate = coordinate
        self.openingHours = openingHours
        self.priceRange = priceRange
        self.nearestStation = nearestStation
        self.tags = tags
        self.sourceURL = sourceURL
        self.imageURL = imageURL
        self.waitMinutes = waitMinutes
        self.isOpen = isOpen
        self.savedAt = savedAt
        self.phone = phone
        self.kakaoMapURL = kakaoMapURL
    }
}

extension Place {
    /// True when the place has real geographic coordinates (not the default 0,0).
    var hasLocation: Bool {
        coordinate.latitude != 0 || coordinate.longitude != 0
    }
}

// MARK: - Coordinate

struct Coordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double

    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Category

enum PlaceCategory: String, Codable, CaseIterable {
    case restaurant = "restaurant"
    case cafe = "cafe"
    case shopping = "shopping"
    case attraction = "attraction"
    case entertainment = "entertainment"
    case beauty = "beauty"

    var displayNameJP: String {
        switch self {
        case .restaurant:    return "レストラン"
        case .cafe:          return "カフェ"
        case .shopping:      return "ショッピング"
        case .attraction:    return "観光スポット"
        case .entertainment: return "エンタメ"
        case .beauty:        return "ビューティ"
        }
    }

    func displayName(language: StationLanguage) -> String {
        switch language {
        case .korean:
            switch self {
            case .restaurant:    return "음식점"
            case .cafe:          return "카페"
            case .shopping:      return "쇼핑"
            case .attraction:    return "관광명소"
            case .entertainment: return "엔터테인먼트"
            case .beauty:        return "뷰티"
            }
        case .japanese: return displayNameJP
        case .english:
            switch self {
            case .restaurant:    return "Restaurant"
            case .cafe:          return "Cafe"
            case .shopping:      return "Shopping"
            case .attraction:    return "Attraction"
            case .entertainment: return "Entertainment"
            case .beauty:        return "Beauty"
            }
        case .chinese:
            switch self {
            case .restaurant:    return "餐厅"
            case .cafe:          return "咖啡厅"
            case .shopping:      return "购物"
            case .attraction:    return "景点"
            case .entertainment: return "娱乐"
            case .beauty:        return "美容"
            }
        }
    }

    var systemImage: String {
        switch self {
        case .restaurant:   return "fork.knife"
        case .cafe:         return "cup.and.saucer.fill"
        case .shopping:     return "bag.fill"
        case .attraction:   return "camera.fill"
        case .entertainment: return "music.note"
        case .beauty:       return "sparkles"
        }
    }
}

// MARK: - Opening Hours

struct OpeningHours: Codable, Hashable {
    let open: String
    let close: String
    let closedDays: [String]

    var displayJP: String {
        "\(open) 〜 \(close)"
    }
}

// MARK: - Price Range

enum PriceRange: String, Codable, CaseIterable {
    case budget = "budget"
    case moderate = "moderate"
    case expensive = "expensive"

    var symbolJP: String {
        switch self {
        case .budget:    return "₩"
        case .moderate:  return "₩₩"
        case .expensive: return "₩₩₩"
        }
    }
}

