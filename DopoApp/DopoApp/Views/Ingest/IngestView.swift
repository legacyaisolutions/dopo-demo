import SwiftUI
import UIKit

struct IngestView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var urlText = ""
    @State private var isIngesting = false
    @State private var result: IngestResult?
    @State private var errorMessage: String?
    @FocusState private var isURLFieldFocused: Bool

    // Collection picker state
    @State private var collections: [DopoCollection] = []
    @State private var selectedCollectionId: String?
    @State private var isLoadingCollections = false

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
                            Text("Paste a URL from YouTube, TikTok, Instagram, X, Facebook, or any website.")
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

                            // Add to Collection picker
                            VStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    Image("Icons/collections-icon")
                                        .renderingMode(.template)
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                        .foregroundColor(.dopoTextDim)

                                    Text("Add to Collection")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.dopoTextMuted)

                                    Spacer()
                                }

                                if isLoadingCollections {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .tint(.dopoAccent)
                                        Spacer()
                                    }
                                } else {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            // "None" option
                                            CollectionChip(
                                                emoji: nil,
                                                name: "None",
                                                isSelected: selectedCollectionId == nil
                                            ) {
                                                HapticManager.selection()
                                                selectedCollectionId = nil
                                            }

                                            ForEach(collections.filter { $0.isEditor }) { coll in
                                                CollectionChip(
                                                    emoji: coll.displayEmoji,
                                                    name: coll.name,
                                                    isSelected: selectedCollectionId == coll.id
                                                ) {
                                                    HapticManager.selection()
                                                    selectedCollectionId = coll.id
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.dopoSurface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedCollectionId != nil ? Color.dopoAccent.opacity(0.4) : Color.dopoBorder, lineWidth: 1)
                            )

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

                                if let collName = result.collectionName {
                                    HStack(spacing: 4) {
                                        Image("Icons/collections-icon")
                                            .renderingMode(.template)
                                            .resizable()
                                            .frame(width: 12, height: 12)
                                        Text("Added to \(collName)")
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .foregroundColor(.dopoAccent)
                                }

                                Button("Save Another") {
                                    withAnimation {
                                        self.result = nil
                                        urlText = ""
                                        selectedCollectionId = nil
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

                            HStack(spacing: 16) {
                                PlatformBrandBadge(platform: .youtube)
                                PlatformBrandBadge(platform: .tiktok)
                                PlatformBrandBadge(platform: .instagram)
                                PlatformBrandBadge(platform: .twitter)
                                PlatformBrandBadge(platform: .facebook)
                                PlatformBrandBadge(platform: .web)
                            }
                        }
                        .padding(.top, 12)

                        Spacer()
                    }
                }
            }
            .navigationTitle("Save")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadCollections() }
        }
    }

    private func pasteFromClipboard() {
        HapticManager.impact(.light)
        if let clipboardString = UIPasteboard.general.string {
            urlText = clipboardString
        }
    }

    private func loadCollections() async {
        guard let token = authManager.accessToken else { return }
        isLoadingCollections = true
        do {
            let response = try await APIClient.shared.fetchCollections(token: token)
            collections = response.collections
        } catch {
            // Silently fail — collections are optional
        }
        isLoadingCollections = false
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

            // If a collection was selected, add the save to it
            var collectionName: String?
            if let collId = selectedCollectionId, let saveId = response.save?.id {
                do {
                    try await APIClient.shared.addSaveToCollection(token: token, collectionId: collId, saveId: saveId)
                    collectionName = collections.first(where: { $0.id == collId })?.name
                } catch {
                    // Save succeeded but collection add failed — still show success
                }
            }

            withAnimation {
                result = IngestResult(
                    title: response.save?.displayTitle,
                    platform: response.save?.platform,
                    collectionName: collectionName
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
    let collectionName: String?
}

// MARK: - Collection Chip (for inline picker)

struct CollectionChip: View {
    let emoji: String?
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let emoji {
                    Text(emoji)
                        .font(.system(size: 14))
                }
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.dopoAccentGlow : Color.dopoSurfaceHover)
            .foregroundColor(isSelected ? .dopoAccent : .dopoTextMuted)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.dopoAccent : Color.dopoBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Platform Brand Badge (uses asset catalog logos)

struct PlatformBrandBadge: View {
    let platform: PlatformTheme

    var body: some View {
        VStack(spacing: 6) {
            PlatformLogo(platform, size: 22)
            Text(platform.label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.dopoTextDim)
        }
    }
}
