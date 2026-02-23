import Foundation

struct DopoNotification: Codable, Identifiable {
    let id: String
    let userId: String
    let type: String
    let actorId: String?
    let collectionId: String?
    let saveId: String?
    let title: String
    let body: String?
    let isRead: Bool
    let readAt: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case actorId = "actor_id"
        case collectionId = "collection_id"
        case saveId = "save_id"
        case title, body
        case isRead = "is_read"
        case readAt = "read_at"
        case createdAt = "created_at"
    }

    var icon: String {
        switch type {
        case "collection_save_added": return "📥"
        case "collaborator_invited": return "🤝"
        case "collaborator_accepted": return "✅"
        default: return "🔔"
        }
    }

    var timeAgo: String {
        guard let date = ISO8601DateFormatter().date(from: createdAt) else { return "" }
        let diff = Date().timeIntervalSince(date)
        let mins = Int(diff / 60)
        if mins < 1 { return "just now" }
        if mins < 60 { return "\(mins)m ago" }
        let hrs = mins / 60
        if hrs < 24 { return "\(hrs)h ago" }
        let days = hrs / 24
        if days < 7 { return "\(days)d ago" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct NotificationsResponse: Codable {
    let notifications: [DopoNotification]
    let total: Int
    let unreadCount: Int

    enum CodingKeys: String, CodingKey {
        case notifications, total
        case unreadCount = "unread_count"
    }
}
