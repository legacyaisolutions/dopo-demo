import SwiftUI
import UIKit

struct IngestView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var urlText = ""
    @State private var isIngesting = false
    @State private var result: IngestResult?
    @State private var errorMessage: String?
    @FocusState private var isURLFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dopoBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Hero section
                        VStack(spacing: 12) {
                            Text("🔗")
                                .font(.system(size: 56))
                            Text("Save anything")
                                .font(.dopoHeading)
                                .foregroundColor(.dopoText)
                            Text("Paste a URL from YouTube, TikTok, Instagram, Twitter, or any website.")
                                .font(.dopoBody)
                                .foregroundColor(.dopoTextMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.top, 40)

                        // URL Input
                        VStack(spacing: 16) {
                            HStack(spacing: 10) {
                                Image(systemName: "link")
                                    .foregroundColor(.dopoTextDim)

                                TextField("Paste a URL...", text: $urlText)
                                    .keyboardType(.URL)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .foregroundColor(.dopoText)
                                    .focused($isURLFieldFocused)

                                if !urlText.isEmpty {
                                    Button(action: { urlText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.dopoTextDim)
                                    }
                                }
                            }
                            .padding(14)
                            .background(Color.dopoSurface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isURLFieldFocused ? Color.dopoAccent : Color.dopoBorder, lineWidth: 1)
                            )

                            // Paste from clipboard button
                            Button(action: pasteFromClipboard) {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.clipboard")
                                    Text("Paste from Clipboard")
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.dopoAccent)
                            }

                            // Save button
                            Button(action: { Task { await ingestURL() } }) {
                                HStack(spacing: 8) {
                                    if isIngesting {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.down.circle.fill")
                                    }
                                    Text(isIngesting ? "Saving..." : "Save It")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    urlText.isEmpty || isIngesting
                                        ? Color.dopoAccent.opacity(0.4)
                                        : Color.dopoAccent
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(urlText.isEmpty || isIngesting)
                        }
                        .padding(.horizontal, 20)

                        // Result display
                        if let result = result {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.dopoSuccess)

                                Text("Saved!")
                                    .font(.dopoHeading)
                                    .foregroundColor(.dopoText)

                                if let title = result.title {
                                    Text(title)
                                        .font(.dopoBody)
                                        .foregroundColor(.dopoTextMuted)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }

                                if let platform = result.platform {
                                    Text(platform.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .tracking(1)
                                        .foregroundColor(Color.platformColor(platform))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.platformColor(platform).opacity(0.15))
                                        .cornerRadius(6)
                                }

                                Button("Save Another") {
                                    withAnimation {
                                        self.result = nil
                                        urlText = ""
                                    }
                                }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.dopoAccent)
                                .padding(.top, 8)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity)
                            .background(Color.dopoSurface)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.dopoSuccess.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                            .transition(.scale.combined(with: .opacity))
                        }

                        // Error display
                        if let errorMessage = errorMessage {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.dopoError)
                                Text(errorMessage)
                                    .font(.dopoBody)
                                    .foregroundColor(.dopoError)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.dopoError.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }

                        // Supported platforms
                        VStack(spacing: 12) {
                            Text("SUPPORTED PLATFORMS")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.dopoTextDim)
                                .tracking(1)

                            HStack(spacing: 20) {
                                PlatformBadge(name: "YouTube", icon: "play.rectangle.fill", color: Color(red: 1.0, green: 0.0, blue: 0.2))
                                PlatformBadge(name: "TikTok", icon: "music.note", color: Color(red: 0.0, green: 0.95, blue: 0.92))
                                PlatformBadge(name: "Instagram", icon: "camera.fill", color: Color(red: 0.88, green: 0.19, blue: 0.42))
                                PlatformBadge(name: "Twitter", icon: "bubble.left.fill", color: Color(red: 0.11, green: 0.61, blue: 0.94))
                            }
                        }
                        .padding(.top, 12)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Save")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func pasteFromClipboard() {
        HapticManager.impact(.light)
        if let clipboardString = UIPasteboard.general.string {
            urlText = clipboardString
        }
    }

    private func ingestURL() async {
        guard let token = authManager.accessToken else { return }
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isIngesting = true
        errorMessage = nil
        result = nil

        do {
            let response = try await APIClient.shared.ingestURL(token: token, urlString: trimmed)
            HapticManager.notification(.success)
            withAnimation {
                result = IngestResult(
                    title: response.save?.displayTitle,
                    platform: response.save?.platform
                )
                isIngesting = false
            }
        } catch {
            HapticManager.notification(.error)
            withAnimation {
                errorMessage = error.localizedDescription
                isIngesting = false
            }
        }
    }
}

struct IngestResult {
    let title: String?
    let platform: String?
}

struct PlatformBadge: View {
    let name: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(name)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.dopoTextDim)
        }
    }
}
