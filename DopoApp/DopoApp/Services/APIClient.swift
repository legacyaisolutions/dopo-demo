import Foundation

class APIClient {
    static let shared = APIClient()

    private func authHeaders(_ token: String) -> [String: String] {
        [
            "Authorization": "Bearer \(token)",
            "apikey": DopoConfig.supabaseAnonKey,
            "Content-Type": "application/json"
        ]
    }

    // MARK: - Library

    func fetchLibrary(
        token: String,
        query: String? = nil,
        platform: String? = nil,
        collectionId: String? = nil,
        limit: Int = 50,
        offset: Int = 0
    ) async throws -> LibraryResponse {
        var components = URLComponents(string: DopoConfig.libraryURL)!
        var queryItems = [URLQueryItem(name: "limit", value: "\(limit)"), URLQueryItem(name: "offset", value: "\(offset)")]
        if let query, !query.isEmpty { queryItems.append(URLQueryItem(name: "q", value: query)) }
        if let platform, platform != "all" { queryItems.append(URLQueryItem(name: "platform", value: platform)) }
        if let collectionId, !collectionId.isEmpty { queryItems.append(URLQueryItem(name: "collection", value: collectionId)) }
        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        request.allHTTPHeaderFields = authHeaders(token)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(LibraryResponse.self, from: data)
    }

    // MARK: - Ingest

    func ingestURL(token: String, urlString: String) async throws -> IngestResponse {
        var request = URLRequest(url: URL(string: DopoConfig.ingestURL)!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = authHeaders(token)
        request.httpBody = try JSONEncoder().encode(["url": urlString])
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(IngestResponse.self, from: data)
    }

    // MARK: - Toggle Favorite

    func toggleFavorite(token: String, saveId: String, isFavorite: Bool) async throws {
        var request = URLRequest(url: URL(string: DopoConfig.libraryURL)!)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = authHeaders(token)
        let body: [String: Any] = ["id": saveId, "is_favorite": isFavorite]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let _ = try await URLSession.shared.data(for: request)
    }

    // MARK: - Delete Save

    func deleteSave(token: String, saveId: String) async throws {
        var components = URLComponents(string: DopoConfig.libraryURL)!
        components.queryItems = [URLQueryItem(name: "id", value: saveId)]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = authHeaders(token)
        let _ = try await URLSession.shared.data(for: request)
    }

    // MARK: - Collections

    func fetchCollections(token: String) async throws -> CollectionsResponse {
        var request = URLRequest(url: URL(string: "\(DopoConfig.libraryURL)/collections")!)
        request.allHTTPHeaderFields = authHeaders(token)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(CollectionsResponse.self, from: data)
    }

    func createCollection(token: String, name: String, emoji: String) async throws {
        var request = URLRequest(url: URL(string: "\(DopoConfig.libraryURL)/collections")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = authHeaders(token)
        let body: [String: String] = ["name": name, "emoji": emoji]
        request.httpBody = try JSONEncoder().encode(body)
        let _ = try await URLSession.shared.data(for: request)
    }

    func deleteCollection(token: String, collectionId: String) async throws {
        var components = URLComponents(string: "\(DopoConfig.libraryURL)/collections")!
        components.queryItems = [URLQueryItem(name: "id", value: collectionId)]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = authHeaders(token)
        let _ = try await URLSession.shared.data(for: request)
    }

    func addSaveToCollection(token: String, collectionId: String, saveId: String) async throws {
        var request = URLRequest(url: URL(string: "\(DopoConfig.libraryURL)/collections")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = authHeaders(token)
        let body: [String: String] = ["action": "add_save", "collection_id": collectionId, "save_id": saveId]
        request.httpBody = try JSONEncoder().encode(body)
        let _ = try await URLSession.shared.data(for: request)
    }

    func removeSaveFromCollection(token: String, collectionId: String, saveId: String) async throws {
        var request = URLRequest(url: URL(string: "\(DopoConfig.libraryURL)/collections")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = authHeaders(token)
        let body: [String: String] = ["action": "remove_save", "collection_id": collectionId, "save_id": saveId]
        request.httpBody = try JSONEncoder().encode(body)
        let _ = try await URLSession.shared.data(for: request)
    }
}
