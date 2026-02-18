import SwiftUI
import UIKit

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var configManager: ConfigManager
    @State private var showSplash = true
    @State private var splashScale: CGFloat = 0.8
    @State private var splashOpacity: Double = 0
    @State private var taglineOpacity: Double = 0

    var body: some View {
        ZStack {
            // Main content (behind splash)
            Group {
                if configManager.forceUpdate {
                    ForceUpdateView()
                } else if authManager.isAuthenticated {
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
                        Text("YOUR BEST FINDS, ALL IN ONE PLACE")
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

// MARK: - Force Update Screen

/// Shown when the server requires a newer app version than what's installed.
/// This prevents users on old versions from hitting deprecated APIs.
struct ForceUpdateView: View {
    var body: some View {
        ZStack {
            Color.dopoBg.ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.dopoAccent)

                Text("Update Required")
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.dopoText)

                Text("A new version of dopo is available with important updates. Please update to continue.")
                    .font(.dopoBody)
                    .foregroundColor(.dopoTextMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button(action: {
                    // Opens App Store page (replace with actual App Store URL when published)
                    if let url = URL(string: "https://apps.apple.com/app/dopo") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Update Now")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.dopoAccent)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
        }
    }
}
