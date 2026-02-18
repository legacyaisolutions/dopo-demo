import Foundation
import SwiftUI

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var currentUser: AuthUser?
    @Published var error: String?
    @Published var sessionExpired = false

    private let tokenKey = "dopo_access_token"
    private let refreshTokenKey = "dopo_refresh_token"

    struct AuthUser: Codable {
        let id: String
        let email: String?
    }

    struct AuthResponse: Codable {
        let accessToken: String?
        let refreshToken: String?
        let user: AuthUser?
        let error: String?
        let errorDescription: String?
        let msg: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case user, error, msg
            case errorDescription = "error_description"
        }
    }

    var accessToken: String? {
        KeychainManager.retrieve(key: tokenKey)
    }

    private var refreshToken: String? {
        KeychainManager.retrieve(key: refreshTokenKey)
    }

    init() {
        // One-time migration from UserDefaults to Keychain (existing users)
        KeychainManager.migrateFromUserDefaults(tokenKey: tokenKey, refreshTokenKey: refreshTokenKey)

        // Wire up 401 handler so expired tokens auto-logout
        APIClient.shared.onUnauthorized = { [weak self] in
            Task { @MainActor in
                await self?.handleUnauthorized()
            }
        }
        Task { await checkSession() }
    }

    func checkSession() async {
        guard let token = accessToken else {
            isLoading = false
            return
        }
        do {
            var request = URLRequest(url: URL(string: "\(DopoConfig.authURL)/user")!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue(DopoConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                logout()
                return
            }

            if httpResponse.statusCode == 401 {
                // Try refreshing the token before giving up
                let refreshed = await attemptTokenRefresh()
                if !refreshed {
                    logout()
                }
                isLoading = false
                return
            }

            guard httpResponse.statusCode == 200 else {
                logout()
                return
            }

            let user = try JSONDecoder().decode(AuthUser.self, from: data)
            currentUser = user
            isAuthenticated = true
        } catch {
            logout()
        }
        isLoading = false
    }

    func signIn(email: String, password: String) async {
        error = nil
        do {
            let body = ["email": email, "password": password]
            var request = URLRequest(url: URL(string: "\(DopoConfig.authURL)/token?grant_type=password")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(DopoConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return }

            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            if httpResponse.statusCode != 200 {
                self.error = authResponse.errorDescription ?? authResponse.msg ?? authResponse.error ?? "Sign in failed"
                return
            }

            guard let token = authResponse.accessToken, let user = authResponse.user else {
                self.error = "Invalid response"
                return
            }

            try? KeychainManager.save(key: tokenKey, value: token)
            if let refresh = authResponse.refreshToken {
                try? KeychainManager.save(key: refreshTokenKey, value: refresh)
            }
            sessionExpired = false
            currentUser = user
            isAuthenticated = true
        } catch {
            self.error = "Network error: \(error.localizedDescription)"
        }
    }

    func signUp(email: String, password: String) async {
        self.error = nil
        do {
            let body = ["email": email, "password": password]
            var request = URLRequest(url: URL(string: "\(DopoConfig.authURL)/signup")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(DopoConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return }

            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            if httpResponse.statusCode >= 400 {
                self.error = authResponse.errorDescription ?? authResponse.msg ?? authResponse.error ?? "Sign up failed"
                return
            }

            if let token = authResponse.accessToken, let user = authResponse.user {
                try? KeychainManager.save(key: tokenKey, value: token)
                if let refresh = authResponse.refreshToken {
                    try? KeychainManager.save(key: refreshTokenKey, value: refresh)
                }
                currentUser = user
                isAuthenticated = true
            } else {
                self.error = "Account created! Check your email to confirm, then sign in."
            }
        } catch {
            self.error = "Network error: \(error.localizedDescription)"
        }
    }

    func logout() {
        KeychainManager.delete(key: tokenKey)
        KeychainManager.delete(key: refreshTokenKey)
        currentUser = nil
        isAuthenticated = false
        isLoading = false
    }

    // MARK: - Token Refresh

    private func attemptTokenRefresh() async -> Bool {
        guard let refresh = refreshToken else { return false }
        do {
            let body = ["refresh_token": refresh]
            var request = URLRequest(url: URL(string: "\(DopoConfig.authURL)/token?grant_type=refresh_token")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(DopoConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return false
            }

            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            guard let newToken = authResponse.accessToken, let user = authResponse.user else {
                return false
            }

            try? KeychainManager.save(key: tokenKey, value: newToken)
            if let newRefresh = authResponse.refreshToken {
                try? KeychainManager.save(key: refreshTokenKey, value: newRefresh)
            }
            currentUser = user
            isAuthenticated = true
            return true
        } catch {
            return false
        }
    }

    private func handleUnauthorized() async {
        let refreshed = await attemptTokenRefresh()
        if !refreshed {
            sessionExpired = true
            logout()
        }
    }
}
