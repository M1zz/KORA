import Foundation

// MARK: - Review Model

struct Review: Identifiable, Codable {
    let id: UUID
    let placeID: UUID
    let authorName: String
    let authorRegion: String  // 출신지 (ex: 東京, 大阪)
    let rating: Double        // 1.0 ~ 5.0
    let body: String          // 일본어 리뷰 본문
    let visitDate: Date
    let tags: [ReviewTag]
    let isVerified: Bool      // 실제 방문 인증 여부
    let helpfulCount: Int
    let photoURLs: [String]

    init(
        id: UUID = UUID(),
        placeID: UUID,
        authorName: String,
        authorRegion: String,
        rating: Double,
        body: String,
        visitDate: Date = Date(),
        tags: [ReviewTag] = [],
        isVerified: Bool = false,
        helpfulCount: Int = 0,
        photoURLs: [String] = []
    ) {
        self.id = id
        self.placeID = placeID
        self.authorName = authorName
        self.authorRegion = authorRegion
        self.rating = rating
        self.body = body
        self.visitDate = visitDate
        self.tags = tags
        self.isVerified = isVerified
        self.helpfulCount = helpfulCount
        self.photoURLs = photoURLs
    }
}

// MARK: - Review Tag

enum ReviewTag: String, Codable, CaseIterable {
    case spiciness     = "辛さ注意"
    case noQueue       = "並ばずOK"
    case longQueue     = "並び必須"
    case cashOnly      = "現金のみ"
    case cardOK        = "カード可"
    case english       = "英語OK"
    case japanese      = "日本語少し可"
    case photoFriendly = "写真映え"
    case soloOK        = "一人でも◎"
    case groupFriendly = "グループ向き"
    case cheapEats     = "コスパ良し"
    case mustVisit     = "絶対行くべき"

    var emoji: String {
        switch self {
        case .spiciness:     return "🌶️"
        case .noQueue:       return "✅"
        case .longQueue:     return "⏳"
        case .cashOnly:      return "💴"
        case .cardOK:        return "💳"
        case .english:       return "🇺🇸"
        case .japanese:      return "🇯🇵"
        case .photoFriendly: return "📸"
        case .soloOK:        return "🙋"
        case .groupFriendly: return "👥"
        case .cheapEats:     return "💰"
        case .mustVisit:     return "⭐"
        }
    }
}

