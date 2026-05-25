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
        savedAt: Date = Date()
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
        case .restaurant:  return "レストラン"
        case .cafe:        return "カフェ"
        case .shopping:    return "ショッピング"
        case .attraction:  return "観光スポット"
        case .entertainment: return "エンタメ"
        case .beauty:      return "ビューティ"
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

