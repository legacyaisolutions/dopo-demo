import SwiftUI

@main
struct DopoApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var configManager = ConfigManager.shared
    @StateObject private var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(configManager)
                .environmentObject(notificationManager)
                .preferredColorScheme(.dark)
                .task {
                    // Fetch feature flags and config on launch
                    await configManager.fetchConfig()
                }
                .onChange(of: authManager.isAuthenticated) { isAuthenticated in
                    if isAuthenticated, let token = authManager.accessToken {
                        notificationManager.start(token: token)
                    } else {
                        notificationManager.stop()
                    }
                }
                .onAppear {
                    // Start notifications if already authenticated on launch
                    if authManager.isAuthenticated, let token = authManager.accessToken {
                        notificationManager.start(token: token)
                    }
                }
        }
    }
}
