# Dopo Share Extension — Xcode Setup Guide

This guide walks through the Xcode steps needed to enable the iOS Share Extension so users can save links to Dopo directly from Instagram, Safari, YouTube, etc.

## What's Already Written

- `DopoShareExtension/ShareViewController.swift` — Full share extension UI and ingest logic
- `DopoShareExtension/Info.plist` — Extension activation rules (accepts URLs and text)

## Xcode Steps

### 1. Create the Share Extension Target

1. Open `DopoApp.xcodeproj` in Xcode
2. **File → New → Target**
3. Select **Share Extension** under iOS
4. Name it: `DopoShareExtension`
5. Bundle ID: `app.dopo.DopoApp.ShareExtension`
6. Language: Swift
7. Click **Finish**
8. When prompted "Activate DopoShareExtension scheme?", click **Activate**

### 2. Delete the Auto-Generated Files

Xcode creates a default `ShareViewController.swift` and storyboard. Delete them:

1. In the project navigator, expand the `DopoShareExtension` folder
2. Delete the auto-generated `ShareViewController.swift` (move to trash)
3. Delete `MainInterface.storyboard` (move to trash)
4. Drag in the files from the repo's `DopoShareExtension/` folder:
   - `ShareViewController.swift`
   - `Info.plist`

### 3. Configure App Groups

Both the main app and extension need a shared App Group for Keychain access:

1. Select the **DopoApp** target → Signing & Capabilities
2. Click **+ Capability** → select **App Groups**
3. Click the **+** under App Groups and add: `group.app.dopo.shared`
4. Now select the **DopoShareExtension** target → Signing & Capabilities
5. Add **App Groups** capability with the same group: `group.app.dopo.shared`

### 4. Configure Keychain Sharing

1. Select the **DopoApp** target → Signing & Capabilities
2. Click **+ Capability** → select **Keychain Sharing**
3. Add keychain group: `group.app.dopo.shared`
4. Repeat for the **DopoShareExtension** target

### 5. Update Main App's KeychainManager

The main app's `KeychainManager.swift` needs to write tokens to the shared access group so the extension can read them. Update all Keychain queries to include:

```swift
kSecAttrAccessGroup as String: "group.app.dopo.shared"
```

**Specifically, update these functions in `KeychainManager.swift`:**

#### `save(key:value:)` — add access group to both delete and add queries:
```swift
static func save(key: String, value: String) throws {
    guard let data = value.data(using: .utf8) else { return }

    let deleteQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecAttrService as String: "app.dopo.DopoApp",
        kSecAttrAccessGroup as String: "group.app.dopo.shared",  // ← ADD THIS
    ]
    SecItemDelete(deleteQuery as CFDictionary)

    let addQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecAttrService as String: "app.dopo.DopoApp",
        kSecAttrAccessGroup as String: "group.app.dopo.shared",  // ← ADD THIS
        kSecValueData as String: data,
        kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
    ]

    let status = SecItemAdd(addQuery as CFDictionary, nil)
    guard status == errSecSuccess else {
        throw KeychainError.unknown(status)
    }
}
```

#### `retrieve(key:)` — add access group:
```swift
static func retrieve(key: String) -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecAttrService as String: "app.dopo.DopoApp",
        kSecAttrAccessGroup as String: "group.app.dopo.shared",  // ← ADD THIS
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne,
    ]
    // ... rest unchanged
}
```

#### `delete(key:)` — add access group:
```swift
static func delete(key: String) {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecAttrService as String: "app.dopo.DopoApp",
        kSecAttrAccessGroup as String: "group.app.dopo.shared",  // ← ADD THIS
    ]
    SecItemDelete(query as CFDictionary)
}
```

### 6. Set Deployment Target

1. Select the **DopoShareExtension** target
2. Under **General → Minimum Deployments**, set iOS to match the main app (iOS 17.0)

### 7. Build & Test

1. Select the **DopoShareExtension** scheme
2. Run on a device or simulator
3. When prompted "Choose an app to run", select **Safari** or **Instagram**
4. Navigate to any post/page and tap the Share button
5. Look for **dopo** in the share sheet (you may need to scroll or tap "More")
6. The extension should show the dopo card, save the URL, and auto-dismiss

### Troubleshooting

- **"Not signed in"** → User needs to open the main dopo app and sign in first. The shared Keychain requires the main app to have written the token at least once with the `group.app.dopo.shared` access group.
- **Extension not appearing** → Make sure the activation rules in Info.plist match the content type. Instagram shares URLs, so `NSExtensionActivationSupportsWebURLWithMaxCount` should work.
- **"dopo" shows up but crashes** → Check that both targets have the same App Group and Keychain Sharing group configured identically.
- **Token migration** → After updating KeychainManager with the access group, existing users need to sign out and back in (or trigger the migration) so tokens get re-saved with the shared group.

## How It Works

1. User taps Share in Instagram/Safari/YouTube/etc
2. iOS loads the DopoShareExtension
3. Extension extracts the URL from `extensionContext.inputItems`
4. Reads the auth token from the shared Keychain (`group.app.dopo.shared`)
5. Calls `POST /functions/v1/ingest` with the URL
6. Shows success/error and auto-dismisses after 2 seconds
