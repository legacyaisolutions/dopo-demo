import SwiftUI

@main
struct DopoApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var configManager = ConfigManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(configManager)
                .preferredColorScheme(.dark)
                .task {
                    // Fetch feature flags and config on launch
                    await configManager.fetchConfig()
                }
        }
    }
}
