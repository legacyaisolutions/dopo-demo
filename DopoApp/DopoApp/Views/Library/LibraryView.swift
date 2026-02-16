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

    let platforms = ["all", "youtube", "instagram", "tiktok", "twitter", "facebook"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Platform filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(platforms, id: \.self) { platform in
                            PlatformPill(
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
        do {
            let response = try await APIClient.shared.fetchLibrary(
                token: token,
                query: searchText.isEmpty ? nil : searchText,
                platform: selectedPlatform == "all" ? nil : selectedPlatform
            )
            withAnimation(.easeInOut(duration: 0.2)) {
                saves = response.saves
                errorMessage = nil
                isLoading = false
            }
        } catch {
            withAnimation {
                if saves.isEmpty {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
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
