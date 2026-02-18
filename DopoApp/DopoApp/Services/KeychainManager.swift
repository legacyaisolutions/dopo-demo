import Foundation
import Security

/// Secure token storage using iOS Keychain instead of UserDefaults.
/// UserDefaults is NOT encrypted and can be read from device backups.
/// Keychain data is encrypted at the hardware level and survives app reinstalls.
enum KeychainManager {

    enum KeychainError: Error {
        case duplicateItem
        case unknown(OSStatus)
        case itemNotFound
    }

    /// Save a string value to the Keychain
    static func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else { return }

        // Delete any existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "app.dopo.DopoApp",
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "app.dopo.DopoApp",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }

    /// Retrieve a string value from the Keychain
    static func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "app.dopo.DopoApp",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    /// Delete a value from the Keychain
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "app.dopo.DopoApp",
        ]
        SecItemDelete(query as CFDictionary)
    }

    /// Migrate tokens from UserDefaults to Keychain (one-time migration)
    static func migrateFromUserDefaults(tokenKey: String, refreshTokenKey: String) {
        // Check if migration already happened
        let migrationKey = "dopo_keychain_migrated"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        // Move access token
        if let token = UserDefaults.standard.string(forKey: tokenKey) {
            try? save(key: tokenKey, value: token)
            UserDefaults.standard.removeObject(forKey: tokenKey)
        }

        // Move refresh token
        if let refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey) {
            try? save(key: refreshTokenKey, value: refreshToken)
            UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        }

        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
