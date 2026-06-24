import Foundation

struct UserProfile: Codable {
    let id: String
    let username: String?
    let displayName: String?
    let bio: String?
    let avatarUrl: String?
    let websiteUrl: String?
    let isPublic: Bool?
    let plan: String?
    let savesCount: Int?
    let createdAt: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case id, username, bio, plan, email
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case websiteUrl = "website_url"
        case isPublic = "is_public"
        case savesCount = "saves_count"
        case createdAt = "created_at"
    }

    var displayTitle: String {
        if let displayName, !displayName.isEmpty { return displayName }
        if let username, !username.isEmpty { return "@\(username)" }
        return email?.components(separatedBy: "@").first ?? "User"
    }

    var avatarInitial: String {
        if let displayName, !displayName.isEmpty, let first = displayName.first {
            return String(first).uppercased()
        }
        if let email, let first = email.first {
            return String(first).uppercased()
        }
        return "?"
    }
}

struct ProfileResponse: Codable {
    let profile: UserProfile
}

struct UserSearchResult: Codable, Identifiable {
    let id: String
    let username: String?
    let displayName: String?
    let avatarUrl: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case id, username, email
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }

    var displayLabel: String {
        if let displayName, !displayName.isEmpty { return displayName }
        if let username, !username.isEmpty { return "@\(username)" }
        return email ?? "Unknown"
    }

    var subtitleLabel: String? {
        if let username, !username.isEmpty { return "@\(username)" }
        return nil
    }

    var avatarInitial: String {
        String(displayLabel.first ?? "?").uppercased()
    }
}

struct UserSearchResponse: Codable {
    let users: [UserSearchResult]
}
