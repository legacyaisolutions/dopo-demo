import Foundation
import SwiftUI

/// Fetches and caches feature flags, design tokens, and app config from the server.
/// Both iOS and web call the same /config endpoint — this is the iOS implementation.
@MainActor
class ConfigManager: ObservableObject {
    static let shared = ConfigManager()

    @Published var features: [String: FeatureFlag] = [:]
    @Published var forceUpdate = false
    @Published var minimumVersion = "1.0.0"
    @Published var isLoaded = false

    // MARK: - Response Models

    struct ConfigResponse: Codable {
        let platform: String
        let appVersion: String?
        let forceUpdate: Bool
        let minimumVersion: String?
        let features: [String: FeatureFlag]
        let designTokens: DesignTokens?
        let apiVersion: APIVersionInfo?

        enum CodingKeys: String, CodingKey {
            case platform
            case appVersion = "app_version"
            case forceUpdate = "force_update"
            case minimumVersion = "minimum_version"
            case features
            case designTokens = "design_tokens"
            case apiVersion = "api_version"
        }
    }

    struct FeatureFlag: Codable {
        let enabled: Bool
        let rollout: Int
    }

    struct DesignTokens: Codable {
        let colors: [String: String]?
        let platformColors: [String: String]?
        let typography: [String: AnyCodable]?
        let spacing: [String: AnyCodable]?
    }

    struct APIVersionInfo: Codable {
        let current: String?
        let minimumSupported: String?
        let deprecated: [String]?

        enum CodingKeys: String, CodingKey {
            case current
            case minimumSupported = "minimum_supported"
            case deprecated
        }
    }

    // MARK: - Feature Flag Checks

    /// Check if a feature is enabled for this platform
    func isEnabled(_ key: String) -> Bool {
        return features[key]?.enabled ?? false
    }

    // MARK: - Fetch Config

    /// Call on app launch to load feature flags and config
    func fetchConfig() async {
        let urlString = "\(DopoConfig.supabaseURL)/functions/v1/config"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("ios", forHTTPHeaderField: "x-platform")
        request.setValue(DopoConfig.appVersion, forHTTPHeaderField: "x-app-version")
        request.setValue(DopoConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                // Config fetch failed — use defaults (features disabled)
                isLoaded = true
                return
            }

            let config = try JSONDecoder().decode(ConfigResponse.self, from: data)
            self.features = config.features
            self.forceUpdate = config.forceUpdate
            self.minimumVersion = config.minimumVersion ?? "1.0.0"
            self.isLoaded = true
        } catch {
            // Non-fatal — app continues with defaults
            print("[ConfigManager] Failed to fetch config: \(error)")
            isLoaded = true
        }
    }
}

// MARK: - AnyCodable helper for mixed-type JSON values

struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else {
            value = ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intVal = value as? Int {
            try container.encode(intVal)
        } else if let doubleVal = value as? Double {
            try container.encode(doubleVal)
        } else if let stringVal = value as? String {
            try container.encode(stringVal)
        } else if let boolVal = value as? Bool {
            try container.encode(boolVal)
        }
    }
}
