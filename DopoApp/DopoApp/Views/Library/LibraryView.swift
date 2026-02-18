import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var saves: [Save] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedPlatform = "all"
    @State private var selectedSave: Save?
    @State private var showDeleteConfirm = false
    @State private var saveToDelete: Save?
    @State private var searchHint: String?

    let platforms = ["all", "youtube", "instagram", "tiktok", "twitter", "facebook"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Platform filter bubbles with brand logos
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(platforms, id: \.self) { platform in
                            PlatformLogoPill(
                                platform: platform,
                                isSelected: selectedPlatform == platform
                            ) {
                                HapticManager.selection()
                                selectedPlatform = platform
                                Task { await loadSaves() }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                Divider().background(Color.dopoBorder)

                // Search context hint (shows what smart-search parsed)
                if let hint = searchHint, !searchText.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                            .foregroundColor(.dopoAccent)
                        Text(hint)
                            .font(.system(size: 11))
                            .foregroundColor(.dopoTextMuted)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.dopoSurface)
                }

                // Content
                if isLoading {
                    SkeletonGrid()
                } else if let errorMessage {
                    ErrorBanner(message: errorMessage) {
                        Task { await loadSaves() }
                    }
                } else if saves.isEmpty {
                    EmptyLibraryView(hasSearch: !searchText.isEmpty)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 160), spacing: 12)
                        ], spacing: 12) {
                            ForEach(saves) { save in
                                SaveCard(save: save, onTap: {
                                    HapticManager.impact(.light)
                                    selectedSave = save
                                }, onFavorite: {
                                    HapticManager.impact(.light)
                                    Task { await toggleFavorite(save) }
                                }, onDelete: {
                                    HapticManager.impact(.medium)
                                    saveToDelete = save
                                    showDeleteConfirm = true
                                })
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Color.dopoBg.ignoresSafeArea())
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("dopo")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.dopoAccent, Color(red: 1.0, green: 0.6, blue: 0.42)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            .searchable(text: $searchText, prompt: "Search your library...")
            .onChange(of: searchText) { _ in
                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    await loadSaves()
                }
            }
            .refreshable { await loadSaves() }
            .sheet(item: $selectedSave) { save in
                SaveDetailView(save: save)
            }
            .alert("Delete Save", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let save = saveToDelete {
                        Task { await deleteSave(save) }
                    }
                }
            } message: {
                Text("Remove \"\(saveToDelete?.displayTitle.prefix(50) ?? "")\" from your library? This also removes it from all collections.")
            }
            .task { await loadSaves() }
        }
    }

    private func loadSaves() async {
        guard let token = authManager.accessToken else { return }

        // Use smart-search when there's a search query, standard library otherwise
        if !searchText.isEmpty {
            await smartSearchSaves(token: token)
        } else {
            await fetchLibrarySaves(token: token)
        }
    }

    /// Standard library fetch (no search query)
    private func fetchLibrarySaves(token: String) async {
        do {
            searchHint = nil
            let response = try await APIClient.shared.fetchLibrary(
                token: token,
                platform: selectedPlatform == "all" ? nil : selectedPlatform
            )
            withAnimation(.easeInOut(duration: 0.2)) {
                saves = response.saves
                errorMessage = nil
                isLoading = false
            }
        } catch {
            withAnimation {
                if saves.isEmpty { errorMessage = error.localizedDescription }
                isLoading = false
            }
        }
    }

    /// AI-powered smart search with natural language understanding
    private func smartSearchSaves(token: String) async {
        do {
            let response = try await APIClient.shared.smartSearch(
                token: token,
                query: searchText,
                platform: selectedPlatform == "all" ? nil : selectedPlatform
            )

            // Build a human-readable hint from the parsed query
            var hints: [String] = []
            if let parsed = response.parsed {
                if let semantic = parsed.semanticQuery, !semantic.isEmpty {
                    hints.append("\"\(semantic)\"")
                }
                if let temporal = parsed.temporal {
                    hints.append(temporal)
                }
                if let platform = parsed.platform {
                    hints.append("on \(platform)")
                }
                if let contentType = parsed.contentType {
                    hints.append(contentType)
                }
            }
            let method = response.searchMethod == "hybrid" ? "AI search" : "keyword search"

            withAnimation(.easeInOut(duration: 0.2)) {
                saves = response.saves
                searchHint = hints.isEmpty ? nil : "\(method): \(hints.joined(separator: " · ")) — \(response.total) results"
                errorMessage = nil
                isLoading = false
            }
        } catch {
            // Fallback to standard library search if smart-search fails
            await fetchLibrarySaves(token: authManager.accessToken ?? "")
        }
    }

    private func toggleFavorite(_ save: Save) async {
        guard let token = authManager.accessToken else { return }
        let newState = !(save.isFavorite ?? false)
        if let idx = saves.firstIndex(where: { $0.id == save.id }) {
            saves[idx].isFavorite = newState
        }
        try? await APIClient.shared.toggleFavorite(token: token, saveId: save.id, isFavorite: newState)
    }

    private func deleteSave(_ save: Save) async {
        guard let token = authManager.accessToken else { return }
        withAnimation { saves.removeAll { $0.id == save.id } }
        HapticManager.notification(.success)
        try? await APIClient.shared.deleteSave(token: token, saveId: save.id)
    }
}

// MARK: - Platform Logo Pill (with brand logos)

struct PlatformLogoPill: View {
    let platform: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if platform != "all" {
                    PlatformLogo(platform, size: 18)
                }
                Text(platform == "all" ? "All" : PlatformTheme.from(platform).label)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.dopoAccentGlow : Color.dopoSurface)
            .foregroundColor(isSelected ? .dopoAccent : .dopoTextMuted)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.dopoAccent : Color.dopoBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Views

struct EmptyLibraryView: View {
    let hasSearch: Bool

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("📌")
                .font(.system(size: 48))
                .opacity(0.5)
            Text(hasSearch ? "No results" : "No saves yet")
                .font(.dopoHeading)
                .foregroundColor(.dopoTextMuted)
            Text(hasSearch ? "Try different search terms." : "Tap the Save tab to add content to your library.")
                .font(.dopoBody)
                .foregroundColor(.dopoTextDim)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

struct SkeletonGrid: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                ForEach(0..<6, id: \.self) { _ in
                    SkeletonCard()
                }
            }
            .padding(16)
        }
    }
}

struct SkeletonCard: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.dopoSurfaceHover)
                .frame(height: 120)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.dopoSurfaceHover)
                    .frame(width: 60, height: 10)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.dopoSurfaceHover)
                    .frame(height: 10)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.dopoSurfaceHover)
                    .frame(width: 100, height: 10)
            }
            .padding(12)
        }
        .background(Color.dopoSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dopoBorder, lineWidth: 1))
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }
}
