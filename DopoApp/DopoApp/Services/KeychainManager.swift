import Foundation
import Security

/// Secure token storage using iOS Keychain instead of UserDefaults.
/// UserDefaults is NOT encrypted and can be read from device backups.
/// Keychain data is encrypted at the hardware level and survives app reinstalls.
///
/// All items are written into the SHARED access group (`DopoKeychain.accessGroup`,
/// backed by the `group.app.dopo.shared` App Group) so the Share Extension's
/// `SharedKeychainManager` can read the same session tokens. The service and
/// access group MUST stay identical on both sides — both come from `DopoKeychain`.
enum KeychainManager {

    enum KeychainError: Error {
        case duplicateItem
        case unknown(OSStatus)
        case itemNotFound
    }

    /// Save a string value to the Keychain (in the shared access group)
    static func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else { return }

        // Delete any existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: DopoKeychain.service,
            kSecAttrAccessGroup as String: DopoKeychain.accessGroup,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: DopoKeychain.service,
            kSecAttrAccessGroup as String: DopoKeychain.accessGroup,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }

    /// Retrieve a string value from the Keychain (from the shared access group)
    static func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: DopoKeychain.service,
            kSecAttrAccessGroup as String: DopoKeychain.accessGroup,
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

    /// Delete a value from the Keychain (from the shared access group)
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: DopoKeychain.service,
            kSecAttrAccessGroup as String: DopoKeychain.accessGroup,
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

    /// Migrate tokens that an earlier build saved WITHOUT `kSecAttrAccessGroup`
    /// (i.e. into the app's private default access group) into the shared
    /// access group so the Share Extension can read them.
    ///
    /// Safe to call on every launch: if the token already lives in the shared
    /// group this is a no-op. If nothing is found anywhere, the user simply
    /// signs in again and tokens land in the shared group from then on.
    static func migrateToSharedAccessGroup(keys: [String]) {
        for key in keys {
            // Already in the shared group? Nothing to do.
            guard retrieve(key: key) == nil else { continue }

            // Query WITHOUT an access group: searches every group this app can
            // access, which is how we find items saved by older builds.
            let legacySearch: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecAttrService as String: DopoKeychain.service,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
            ]

            var result: AnyObject?
            let status = SecItemCopyMatching(legacySearch as CFDictionary, &result)
            guard status == errSecSuccess,
                  let data = result as? Data,
                  let value = String(data: data, encoding: .utf8) else {
                continue
            }

            // Remove the legacy copy first (un-scoped delete hits all groups we
            // can access; the shared group is empty for this key at this point),
            // then re-save into the shared group.
            let legacyDelete: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecAttrService as String: DopoKeychain.service,
            ]
            SecItemDelete(legacyDelete as CFDictionary)
            try? save(key: key, value: value)
        }
    }
}
