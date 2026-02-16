import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isLoading {
                ZStack {
                    Color.dopoBg.ignoresSafeArea()
                    VStack(spacing: 12) {
                        Text("dopo")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.dopoAccent, Color(red: 1.0, green: 0.6, blue: 0.42)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        ProgressView()
                            .tint(.dopoAccent)
                    }
                }
            } else if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authManager.isLoading)
    }
}
