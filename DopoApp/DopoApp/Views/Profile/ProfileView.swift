import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var saveCount: Int = 0
    @State private var collectionCount: Int = 0
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showLogoutConfirm = false
    @State private var showAbout = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dopoBg.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(.dopoAccent)
                } else if let errorMessage {
                    ErrorBanner(message: errorMessage) {
                        Task { await loadStats() }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            VStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.dopoAccent, Color(red: 1.0, green: 0.6, blue: 0.3)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 80, height: 80)

                                    Text(avatarInitial)
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                VStack(spacing: 4) {
                                    Text(authManager.currentUser?.email ?? "User")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.dopoText)

                                    Text("dopo member")
                                        .font(.dopoCaption)
                                        .foregroundColor(.dopoTextDim)
                                        .textCase(.uppercase)
                                }
                            }
                            .padding(.top, 20)

                            HStack(spacing: 0) {
                                StatBlock(value: "\(saveCount)", label: "Saves")
                                Divider()
                                    .frame(height: 40)
                                    .background(Color.dopoBorder)
                                StatBlock(value: "\(collectionCount)", label: "Collections")
                            }
                            .padding(.vertical, 16)
                            .background(Color.dopoSurface)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.dopoBorder, lineWidth: 1)
                            )
                            .padding(.horizontal, 20)

                            VStack(spacing: 0) {
                                ProfileRow(icon: "bell.fill", label: "Notifications", color: .dopoAccent, comingSoon: true) {
                                    HapticManager.impact(.light)
                                }
                                Divider().background(Color.dopoBorder).padding(.leading, 52)
                                ProfileRow(icon: "paintbrush.fill", label: "Appearance", color: .purple, comingSoon: true) {
                                    HapticManager.impact(.light)
                                }
                                Divider().background(Color.dopoBorder).padding(.leading, 52)
                                ProfileRow(icon: "questionmark.circle.fill", label: "Help & Support", color: .blue, comingSoon: true) {
                                    HapticManager.impact(.light)
                                }
                                Divider().background(Color.dopoBorder).padding(.leading, 52)
                                ProfileRow(icon: "info.circle.fill", label: "About Dopo", color: .dopoTextMuted) {
                                    HapticManager.impact(.light)
                                    showAbout = true
                                }
                            }
                            .background(Color.dopoSurface)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.dopoBorder, lineWidth: 1)
                            )
                            .padding(.horizontal, 20)

                            Button(action: {
                                HapticManager.impact(.medium)
                                showLogoutConfirm = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                }
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.dopoError)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.dopoError.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.dopoError.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, 20)

                            Text("dopo v1.0.0 beta")
                                .font(.system(size: 11))
                                .foregroundColor(.dopoTextDim)
                                .padding(.top, 8)

                            Spacer()
                        }
                    }
                    .refreshable { await loadStats() }
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showLogoutConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("About Dopo", isPresented: $showAbout) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("dopo v1.0.0 beta\n\nYour best finds, all in one place.\n\nBuilt with love by Legacy AI Solutions.")
            }
            .task { await loadStats() }
        }
    }

    private var avatarInitial: String {
        guard let email = authManager.currentUser?.email,
              let first = email.first else { return "?" }
        return String(first).uppercased()
    }

    private func loadStats() async {
        guard let token = authManager.accessToken else {
            isLoading = false
            return
        }
        do {
            async let libraryResponse = APIClient.shared.fetchLibrary(token: token, limit: 1)
            async let collectionsResponse = APIClient.shared.fetchCollections(token: token)

            let (library, collections) = try await (libraryResponse, collectionsResponse)
            withAnimation {
                saveCount = library.total ?? library.saves.count
                collectionCount = collections.collections.count
                errorMessage = nil
                isLoading = false
            }
        } catch {
            withAnimation {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

struct StatBlock: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.dopoText)
            Text(label)
                .font(.dopoCaption)
                .foregroundColor(.dopoTextDim)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileRow: View {
    let icon: String
    let label: String
    let color: Color
    var comingSoon: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 28)

                Text(label)
                    .font(.system(size: 15))
                    .foregroundColor(.dopoText)

                Spacer()

                if comingSoon {
                    Text("Coming Soon")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.dopoTextDim)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.dopoSurfaceHover)
                        .cornerRadius(4)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.dopoTextDim)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}
