import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case serverError(Int)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Session expired. Please sign in again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again."
        case .networkError:
            return "Couldn't connect. Check your internet and try again."
        case .decodingError:
            return "Something went wrong. Please try again."
        }
    }
}

class APIClient {
    static let shared = APIClient()

    /// Callback for 401s — AuthManager sets this to trigger logout
    var onUnauthorized: (() -> Void)?

    private func authHeaders(_ token: String) -> [String: String] {
        [
            "Authorization": "Bearer \(token)",
            "apikey": DopoConfig.supabaseAnonKey,
            "Content-Type": "application/json",
            "x-platform": DopoConfig.platform,
            "x-app-version": DopoConfig.appVersion,
        ]
    }

    /// Centralized request method with error handling and 401 detection
    private func performRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.serverError(0)
        }

        if httpResponse.statusCode == 401 {
            await MainActor.run { onUnauthorized?() }
            throw APIError.unauthorized
        }

        if httpResponse.statusCode >= 500 {
            throw APIError.serverError(httpResponse.statusCode)
        }

        return (data, httpResponse)
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
        let (data, _) = try await performRequest(request)
        do {
            return try JSONDecoder().decode(LibraryResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Smart Search (AI-powered natural language search)

    func smartSearch(
        token: String,
        query: String,
        platform: String? = nil,
        limit: Int = 30
    ) async throws -> SmartSearchResponse {
        var request = URLRequest(url: URL(string: DopoConfig.smartSearchURL)!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = authHeaders(token)
        var body: [String: Any] = ["q": query, "limit": limit]
        if let platform, !platform.isEmpty, platform != "all" {
            body["platform"] = platform
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await performRequest(request)
        do {
            return try JSONDecoder().decode(SmartSearchResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Ingest

    func ingestURL(token: String, urlString: String) async throws -> IngestResponse {
        var request = URLRequest(url: URL(string: DopoConfig.ingestURL)!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = authHeaders(token)
        request.httpBody = try JSONEncoder().encode(["url": urlString])
        let (data, _) = try await performRequest(request)
        do {
            return try JSONDecoder().decode(IngestResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Toggle Favorite

    func toggleFavorite(token: String, saveId: String, isFavorite: Bool) async throws {
        var request = URLRequest(url: URL(string: DopoConfig.libraryURL)!)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = authHeaders(token)
        let body: [String: Any] = ["id": saveId, "is_favorite": isFavorite]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let _ = try await performRequest(request)
    }

    // MARK: - Delete Save

    func deleteSave(token: String, saveId: String) async throws {
        var components = URLComponents(string: DopoConfig.libraryURL)!
        components.queryItems = [URLQueryItem(name: "id", value: saveId)]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = authHeaders(token)
        let _ = try await performRequest(request)
    }

    // MARK: - Collections

    func fetchCollections(token: String) async throws -> CollectionsResponse {
        var request = URLRequest(url: URL(string: "\(DopoConfig.libraryURL)/collections")!)
        request.allHTTPHeaderFields = authHeaders(token)
        let (data, _) = try await performRequest(request)
        do {
            return try JSONDecoder().decode(CollectionsResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func createCollection(token: String, name: String, emoji: String) async throws {
        var request = URLRequest(url: URL(string: "\(DopoConfig.libraryURL)/collections")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = authHeaders(token)
        let body: [String: String] = ["name": name, "emoji": emoji]
        request.httpBody = try JSONEncoder().encode(body)
        let _ = try await performRequest(request)
    }

    func renameCollection(token: String, collectionId: String, name: String, emoji: String? = nil) async throws {
        var request = URLRequest(url: URL(string: "\(DopoConfig.libraryURL)/collections")!)
        request.httpMethod = "PATCH"
        request.allHTTPHeaderFields = authHeaders(token)
        var body: [String: String] = ["id": collectionId, "name": name]
        if let emoji { body["emoji"] = emoji }
        request.httpBody = try JSONEncoder().encode(body)
        let _ = try await performRequest(request)
    }

    func deleteCollection(token: String, collectionId: String) async throws {
        var components = URLComponents(string: "\(DopoConfig.libraryURL)/collections")!
        components.queryItems = [URLQueryItem(name: "id", value: collectionId)]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = authHeaders(token)
        let _ = try await performRequest(request)
    }

    func addSaveToCollection(token: String, collectionId: String, saveId: String) async throws {
        var request = URLRequest(url: URL(string: "\(DopoConfig.libraryURL)/collections")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = authHeaders(token)
        let body: [String: String] = ["action": "add_save", "collection_id": collectionId, "save_id": saveId]
        request.httpBody = try JSONEncoder().encode(body)
        let _ = try await performRequest(request)
    }

    func removeSaveFromCollection(token: String, collectionId: String, saveId: String) async throws {
        var request = URLRequest(url: URL(string: "\(DopoConfig.libraryURL)/collections")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = authHeaders(token)
        let body: [String: String] = ["action": "remove_save", "collection_id": collectionId, "save_id": saveId]
        request.httpBody = try JSONEncoder().encode(body)
        let _ = try await performRequest(request)
    }

    // MARK: - Collection Sharing

    func toggleCollectionShare(token: String, collectionId: String) async throws -> DopoCollection {
        var request = URLRequest(url: URL(string: "\(DopoConfig.libraryURL)/collections")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = authHeaders(token)
        let body: [String: String] = ["action": "toggle_share", "collection_id": collectionId]
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await performRequest(request)
        do {
            return try JSONDecoder().decode(DopoCollection.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Collaborators

    func fetchCollaborators(token: String, collectionId: String) async throws -> CollaboratorsResponse {
        var components = URLComponents(string: "\(DopoConfig.libraryURL)/collaborators")!
        components.queryItems = [URLQueryItem(name: "collection_id", value: collectionId)]
        var request = URLRequest(url: components.url!)
        request.allHTTPHeaderFields = authHeaders(token)
        let (data, _) = try await performRequest(request)
        do {
            return try JSONDecoder().decode(CollaboratorsResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func inviteCollaborator(token: String, collectionId: String, email: String, role: String) async throws {
        var request = URLRequest(url: URL(string: "\(DopoConfig.libraryURL)/collaborators")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = authHeaders(token)
        let body: [String: String] = ["collection_id": collectionId, "email": email, "role": role]
        request.httpBody = try JSONEncoder().encode(body)
        let _ = try await performRequest(request)
    }

    func removeCollaborator(token: String, collaboratorId: String) async throws {
        var components = URLComponents(string: "\(DopoConfig.libraryURL)/collaborators")!
        components.queryItems = [URLQueryItem(name: "id", value: collaboratorId)]
        var request = URLRequest(url: components.url!)
        request.httpMethod = "DELETE"
        request.allHTTPHeaderFields = authHeaders(token)
        let _ = try await performRequest(request)
    }
}
