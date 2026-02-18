import Foundation

struct DopoCollection: Codable, Identifiable, Hashable {
    let id: String
    let userId: String?
    let name: String
    let emoji: String?
    let description: String?
    let isPublic: Bool?
    let shareToken: String?
    let sortOrder: Int?
    let createdAt: String?
    let saveCount: Int?
    let isOwner: Bool?
    let role: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name, emoji, description
        case isPublic = "is_public"
        case shareToken = "share_token"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case saveCount = "save_count"
        case isOwner = "is_owner"
        case role
    }

    var displayEmoji: String { emoji ?? "📁" }

    var isViewOnly: Bool {
        guard let isOwner, !isOwner else { return false }
        return role == "viewer"
    }

    var isEditor: Bool {
        guard let isOwner else { return true }
        if isOwner { return true }
        return role == "editor"
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: DopoCollection, rhs: DopoCollection) -> Bool { lhs.id == rhs.id }
}

struct CollectionsResponse: Codable {
    let collections: [DopoCollection]
}

struct Collaborator: Codable, Identifiable {
    let id: String
    let collectionId: String?
    let userId: String?
    let role: String
    let accepted: Bool
    let email: String?
    let invitedEmail: String?

    enum CodingKeys: String, CodingKey {
        case id
        case collectionId = "collection_id"
        case userId = "user_id"
        case role, accepted, email
        case invitedEmail = "invited_email"
    }

    var displayEmail: String { email ?? invitedEmail ?? "unknown" }
}

struct CollaboratorsResponse: Codable {
    let collaborators: [Collaborator]
    let isOwner: Bool?

    enum CodingKeys: String, CodingKey {
        case collaborators
        case isOwner = "is_owner"
    }
}
