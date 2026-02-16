import SwiftUI

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showSplash = true
    @State private var splashScale: CGFloat = 0.8
    @State private var splashOpacity: Double = 0
    @State private var taglineOpacity: Double = 0

    var body: some View {
        ZStack {
            // Main content (behind splash)
            Group {
                if authManager.isAuthenticated {
                    MainTabView()
                } else if !authManager.isLoading {
                    AuthView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)

            // Splash overlay
            if showSplash {
                ZStack {
                    Color.dopoBg.ignoresSafeArea()

                    VStack(spacing: 16) {
                        // Logo with scale animation
                        Text("dopo")
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.dopoAccent, Color(red: 1.0, green: 0.6, blue: 0.42)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(splashScale)
                            .opacity(splashOpacity)

                        // Tagline fades in slightly after
                        Text("YOUR CONTENT LIBRARY")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.dopoTextDim)
                            .tracking(3)
                            .opacity(taglineOpacity)

                        // Loading indicator
                        if authManager.isLoading {
                            ProgressView()
                                .tint(.dopoAccent)
                                .scaleEffect(0.8)
                                .padding(.top, 20)
                                .opacity(taglineOpacity)
                        }
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            }

            // Session expired overlay
            if authManager.sessionExpired && !authManager.isAuthenticated {
                Color.black.opacity(0.01) // tap target
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 28))
                                .foregroundColor(.dopoAccent)
                            Text("Session expired")
                                .font(.dopoHeading)
                                .foregroundColor(.dopoText)
                            Text("Please sign in again to continue.")
                                .font(.dopoBody)
                                .foregroundColor(.dopoTextMuted)
                        }
                        .padding(24)
                        .background(Color.dopoSurface)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.dopoBorder, lineWidth: 1)
                        )
                        .padding(40)
                    )
            }
        }
        .onAppear { animateSplash() }
        .onChange(of: authManager.isLoading) { _ in
            // Once loading is done, dismiss splash after brief delay
            if !authManager.isLoading {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
            }
        }
    }

    private func animateSplash() {
        // Logo scales up and fades in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            splashScale = 1.0
            splashOpacity = 1.0
        }
        // Tagline fades in slightly delayed
        withAnimation(.easeIn(duration: 0.4).delay(0.3)) {
            taglineOpacity = 1.0
        }
    }
}
