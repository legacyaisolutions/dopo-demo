import Foundation

struct Save: Codable, Identifiable, Hashable {
    let id: String
    let userId: String?
    let url: String
    let canonicalUrl: String?
    let platform: String
    let contentType: String?
    let title: String?
    let creatorName: String?
    let creatorHandle: String?
    let thumbnailUrl: String?
    let aiTags: [String]?
    let aiSummary: String?
    let category: String?
    let savedAt: String?
    var isFavorite: Bool?
    let userNote: String?
    let tags: [String]?
    let enrichmentStatus: String?
    var collectionIds: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case url
        case canonicalUrl = "canonical_url"
        case platform
        case contentType = "content_type"
        case title
        case creatorName = "creator_name"
        case creatorHandle = "creator_handle"
        case thumbnailUrl = "thumbnail_url"
        case aiTags = "ai_tags"
        case aiSummary = "ai_summary"
        case category
        case savedAt = "saved_at"
        case isFavorite = "is_favorite"
        case userNote = "user_note"
        case tags
        case enrichmentStatus = "enrichment_status"
        case collectionIds = "collection_ids"
    }

    var displayTitle: String {
        title ?? canonicalUrl ?? url
    }

    var displayDate: String {
        guard let savedAt else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: savedAt) {
            let display = DateFormatter()
            display.dateFormat = "MMM d"
            return display.string(from: date)
        }
        return ""
    }

    var platformColor: PlatformTheme {
        PlatformTheme.from(platform)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Save, rhs: Save) -> Bool {
        lhs.id == rhs.id
    }
}

struct LibraryResponse: Codable {
    let saves: [Save]
    let total: Int?
    let query: String?
    let collectionId: String?

    enum CodingKeys: String, CodingKey {
        case saves, total, query
        case collectionId = "collection_id"
    }
}

struct IngestResponse: Codable {
    let save: Save?
    let error: String?
}

struct SmartSearchResponse: Codable {
    let saves: [Save]
    let total: Int
    let query: String
    let parsed: SearchParsed?
    let searchMethod: String?

    enum CodingKeys: String, CodingKey {
        case saves, total, query, parsed
        case searchMethod = "search_method"
    }
}

struct SearchParsed: Codable {
    let semanticQuery: String?
    let platform: String?
    let contentType: String?
    let temporal: String?

    enum CodingKeys: String, CodingKey {
        case semanticQuery = "semantic_query"
        case platform
        case contentType = "content_type"
        case temporal
    }
}

enum PlatformTheme {
    case youtube, instagram, tiktok, twitter, facebook, other

    static func from(_ platform: String) -> PlatformTheme {
        switch platform.lowercased() {
        case "youtube": return .youtube
        case "instagram": return .instagram
        case "tiktok": return .tiktok
        case "twitter": return .twitter
        case "facebook": return .facebook
        default: return .other
        }
    }

    var label: String {
        switch self {
        case .youtube: return "YouTube"
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        case .twitter: return "X"
        case .facebook: return "Facebook"
        case .other: return "Other"
        }
    }

    var iconName: String {
        switch self {
        case .youtube: return "play.rectangle.fill"
        case .instagram: return "camera.fill"
        case .tiktok: return "music.note"
        case .twitter: return "xmark"
        case .facebook: return "person.2.fill"
        case .other: return "link"
        }
    }
}
