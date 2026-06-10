import Foundation

/// Keychain constants shared between the main app and the Share Extension.
///
/// This file is compiled into BOTH targets (see `project.yml`) so the
/// service + access group strings can never drift apart. The whole point of
/// the shared keychain is that the Share Extension can read the auth token
/// the main app wrote — that only works when `kSecAttrService` AND
/// `kSecAttrAccessGroup` match EXACTLY on both sides.
enum DopoKeychain {

    /// Logical shared group name. Mirrors the team-prefixed entry in both
    /// targets' entitlements: `$(AppIdentifierPrefix)app.dopo.shared`.
    static let sharedGroupName = "app.dopo.shared"

    /// App Group identifier, declared under `com.apple.security.application-groups`
    /// in BOTH `DopoApp.entitlements` and `DopoShareExtension.entitlements`.
    static let appGroup = "group." + sharedGroupName // "group.app.dopo.shared"

    /// The keychain access group used for every token read/write.
    ///
    /// On iOS an App Group identifier is also a valid keychain access group
    /// and — unlike `keychain-access-groups` entries — it is NOT prefixed
    /// with the Team ID. Using it means neither target needs to know the
    /// Team ID at runtime. (See SHARE_EXTENSION_SETUP.md.)
    static let accessGroup = appGroup

    /// `kSecAttrService` for all Dopo keychain items (same as the main app's
    /// bundle identifier).
    static let service = "app.dopo.DopoApp"

    /// Keychain account keys for the Supabase session tokens.
    static let accessTokenKey = "dopo_access_token"
    static let refreshTokenKey = "dopo_refresh_token"
}
