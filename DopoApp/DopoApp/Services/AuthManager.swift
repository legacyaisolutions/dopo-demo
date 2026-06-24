import Foundation
import SwiftUI

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = true
    @Published var currentUser: AuthUser?
    @Published var error: String?
    @Published var sessionExpired = false

    private let tokenKey = DopoKeychain.accessTokenKey
    private let refreshTokenKey = DopoKeychain.refreshTokenKey

    // Serializes concurrent refresh attempts so only one runs at a time.
    // Subsequent 401s wait on this task instead of starting a new refresh
    // (which would try the already-rotated refresh token and fail).
    private var activeRefreshTask: Task<RefreshOutcome, Never>?

    private enum RefreshOutcome {
        case success
        case definiteFailure  // server explicitly rejected the token
        case networkError     // could not reach server; token may still be valid
    }

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

        // Move tokens saved by older builds (no kSecAttrAccessGroup) into the
        // shared access group so the Share Extension can read the session.
        KeychainManager.migrateToSharedAccessGroup(keys: [tokenKey, refreshTokenKey])

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
                // Non-HTTP response — keep existing session alive
                isAuthenticated = true
                isLoading = false
                return
            }

            if httpResponse.statusCode == 401 {
                // Token expired — try to refresh before giving up
                let outcome = await performRefresh()
                switch outcome {
                case .success: break
                case .definiteFailure: logout()
                case .networkError:
                    // Can't reach server to refresh — keep the session alive.
                    // The next API call will retry if still offline.
                    isAuthenticated = true
                }
                isLoading = false
                return
            }

            guard httpResponse.statusCode == 200 else {
                // Server error (5xx, 429, etc.) — don't destroy the session.
                isAuthenticated = true
                isLoading = false
                return
            }

            let user = try JSONDecoder().decode(AuthUser.self, from: data)
            currentUser = user
            isAuthenticated = true
        } catch {
            // Network error at launch — keep the stored token alive.
            // A real 401 from the next API call will trigger handleUnauthorized().
            isAuthenticated = true
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

    // Serialized entry point — if a refresh is already in-flight, callers await
    // the same Task instead of starting a second one (which would use the
    // already-rotated refresh token and always fail).
    private func performRefresh() async -> RefreshOutcome {
        if let existing = activeRefreshTask {
            return await existing.value
        }
        let task = Task<RefreshOutcome, Never> { [weak self] in
            await self?.attemptTokenRefresh() ?? .definiteFailure
        }
        activeRefreshTask = task
        let outcome = await task.value
        activeRefreshTask = nil
        return outcome
    }

    private func attemptTokenRefresh() async -> RefreshOutcome {
        guard let refresh = refreshToken else { return .definiteFailure }
        do {
            let body = ["refresh_token": refresh]
            var request = URLRequest(url: URL(string: "\(DopoConfig.authURL)/token?grant_type=refresh_token")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(DopoConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return .networkError }
            guard httpResponse.statusCode == 200 else { return .definiteFailure }

            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            guard let newToken = authResponse.accessToken, let user = authResponse.user else {
                return .definiteFailure
            }

            try? KeychainManager.save(key: tokenKey, value: newToken)
            if let newRefresh = authResponse.refreshToken {
                try? KeychainManager.save(key: refreshTokenKey, value: newRefresh)
            }
            currentUser = user
            isAuthenticated = true
            return .success
        } catch {
            return .networkError
        }
    }

    private func handleUnauthorized() async {
        let outcome = await performRefresh()
        switch outcome {
        case .success: break
        case .definiteFailure:
            sessionExpired = true
            logout()
        case .networkError:
            // Can't reach the server right now — don't destroy the session.
            // The user can keep working; the next successful API call will
            // confirm whether the token is still valid.
            break
        }
    }
}
