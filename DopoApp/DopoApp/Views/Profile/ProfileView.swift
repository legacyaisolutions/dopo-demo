import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var saveCount: Int = 0
    @State private var collectionCount: Int = 0
    @State private var userProfile: UserProfile? = nil
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showLogoutConfirm = false
    @State private var showAbout = false
    @State private var showNotifications = false
    @State private var showEditProfile = false

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
                                    Text(displayName)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.dopoText)

                                    if let username = userProfile?.username, !username.isEmpty {
                                        Text("@\(username)")
                                            .font(.dopoCaption)
                                            .foregroundColor(.dopoTextMuted)
                                    }

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
                                ProfileRow(icon: "person.crop.circle", label: "Edit Profile", color: .dopoAccent) {
                                    HapticManager.impact(.light)
                                    showEditProfile = true
                                }
                                Divider().background(Color.dopoBorder).padding(.leading, 52)
                                ProfileRow(icon: "bell.fill", label: "Notifications", color: .dopoAccent) {
                                    HapticManager.impact(.light)
                                    showNotifications = true
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
            .sheet(isPresented: $showNotifications) {
                NotificationListView()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(profile: userProfile) { updatedProfile in
                    userProfile = updatedProfile
                }
            }
            .task { await loadStats() }
        }
    }

    private var avatarInitial: String {
        if let profile = userProfile { return profile.avatarInitial }
        guard let email = authManager.currentUser?.email, let first = email.first else { return "?" }
        return String(first).uppercased()
    }

    private var displayName: String {
        if let profile = userProfile { return profile.displayTitle }
        return authManager.currentUser?.email ?? "User"
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
            if let profile = try? await APIClient.shared.fetchProfile(token: token) {
                withAnimation { userProfile = profile }
            }
        } catch {
            withAnimation {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    let profile: UserProfile?
    let onSave: (UserProfile) -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager

    @State private var displayName: String
    @State private var username: String
    @State private var bio: String
    @State private var websiteUrl: String
    @State private var isPublic: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(profile: UserProfile?, onSave: @escaping (UserProfile) -> Void) {
        self.profile = profile
        self.onSave = onSave
        _displayName = State(initialValue: profile?.displayName ?? "")
        _username = State(initialValue: profile?.username ?? "")
        _bio = State(initialValue: profile?.bio ?? "")
        _websiteUrl = State(initialValue: profile?.websiteUrl ?? "")
        _isPublic = State(initialValue: profile?.isPublic ?? false)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dopoBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.dopoError)
                                .cornerRadius(10)
                                .padding(.horizontal, 20)
                        }

                        VStack(spacing: 0) {
                            ProfileEditField(label: "Display Name", placeholder: "Your name", text: $displayName)
                            Divider().background(Color.dopoBorder)
                            HStack(spacing: 0) {
                                Text("@")
                                    .font(.system(size: 15))
                                    .foregroundColor(.dopoTextMuted)
                                    .padding(.leading, 16)
                                    .padding(.top, 12)
                                ProfileEditField(label: "", placeholder: "username", text: $username, showLabel: false)
                            }
                            Divider().background(Color.dopoBorder)
                            ProfileEditField(label: "Bio", placeholder: "Tell the world about yourself", text: $bio, multiline: true)
                            Divider().background(Color.dopoBorder)
                            ProfileEditField(label: "Website", placeholder: "https://", text: $websiteUrl, keyboardType: .URL)
                        }
                        .background(Color.dopoSurface)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.dopoBorder, lineWidth: 1))
                        .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Public profile")
                                        .font(.system(size: 15))
                                        .foregroundColor(.dopoText)
                                    Text("Others can find and view your profile")
                                        .font(.system(size: 12))
                                        .foregroundColor(.dopoTextDim)
                                }
                                Spacer()
                                Toggle("", isOn: $isPublic)
                                    .labelsHidden()
                                    .tint(.dopoAccent)
                            }
                            .padding(16)
                        }
                        .background(Color.dopoSurface)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.dopoBorder, lineWidth: 1))
                        .padding(.horizontal, 20)

                        Button(action: {
                            HapticManager.impact(.medium)
                            Task { await save() }
                        }) {
                            HStack(spacing: 8) {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                Text("Save Changes")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(isSaving ? Color.dopoTextDim : Color.dopoAccent)
                            .cornerRadius(12)
                        }
                        .disabled(isSaving)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.dopoTextMuted)
                }
            }
        }
    }

    private func save() async {
        guard let token = authManager.accessToken else { return }
        isSaving = true
        errorMessage = nil
        do {
            let updated = try await APIClient.shared.updateProfile(
                token: token,
                displayName: displayName.trimmingCharacters(in: .whitespaces),
                username: username.trimmingCharacters(in: .whitespaces).lowercased(),
                bio: bio.trimmingCharacters(in: .whitespaces),
                isPublic: isPublic,
                websiteUrl: websiteUrl.trimmingCharacters(in: .whitespaces)
            )
            HapticManager.notification(.success)
            onSave(updated)
            dismiss()
        } catch APIError.requestError(let message) {
            errorMessage = message
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

struct ProfileEditField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var multiline: Bool = false
    var showLabel: Bool = true
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if showLabel && !label.isEmpty {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.dopoTextDim)
                    .padding(.top, 12)
                    .padding(.horizontal, 16)
            }
            if multiline {
                TextField(placeholder, text: $text, axis: .vertical)
                    .lineLimit(3...6)
                    .font(.system(size: 15))
                    .foregroundColor(.dopoText)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .padding(.top, (showLabel && !label.isEmpty) ? 4 : 12)
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 15))
                    .foregroundColor(.dopoText)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .padding(.top, (showLabel && !label.isEmpty) ? 4 : 12)
            }
        }
    }
}

// MARK: - Reusable sub-views

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
