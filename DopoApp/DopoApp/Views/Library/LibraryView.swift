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
    @State private var addToCollSave: Save?

    // Batch mode state
    @State private var batchMode = false
    @State private var selectedIds: Set<String> = []
    @State private var showBatchDeleteConfirm = false
    @State private var showBatchCollectionPicker = false
    @State private var batchCollections: [DopoCollection] = []

    let platforms = ["all", "youtube", "instagram", "tiktok", "twitter", "facebook"]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
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
                                    SaveCard(
                                        save: save,
                                        onTap: {
                                            if batchMode {
                                                HapticManager.impact(.light)
                                                toggleSelection(save.id)
                                            } else {
                                                HapticManager.impact(.light)
                                                selectedSave = save
                                            }
                                        },
                                        onFavorite: {
                                            if batchMode {
                                                toggleSelection(save.id)
                                            } else {
                                                HapticManager.impact(.light)
                                                Task { await toggleFavorite(save) }
                                            }
                                        },
                                        onDelete: {
                                            if batchMode {
                                                toggleSelection(save.id)
                                            } else {
                                                HapticManager.impact(.medium)
                                                saveToDelete = save
                                                showDeleteConfirm = true
                                            }
                                        },
                                        onAddToCollection: batchMode ? nil : {
                                            HapticManager.impact(.light)
                                            addToCollSave = save
                                        },
                                        isSelectMode: batchMode,
                                        isSelected: selectedIds.contains(save.id)
                                    )
                                }
                            }
                            .padding(16)
                            .padding(.bottom, batchMode ? 80 : 0)
                        }
                    }
                }
                .background(Color.dopoBg.ignoresSafeArea())

                // Batch action bar
                if batchMode {
                    BatchActionBar(
                        selectedCount: selectedIds.count,
                        totalCount: saves.count,
                        onSelectAll: {
                            HapticManager.impact(.light)
                            if selectedIds.count == saves.count {
                                selectedIds.removeAll()
                            } else {
                                selectedIds = Set(saves.map { $0.id })
                            }
                        },
                        onAddToCollection: {
                            HapticManager.impact(.light)
                            Task { await loadCollectionsForBatch() }
                        },
                        onFavorite: {
                            HapticManager.impact(.light)
                            Task { await batchFavorite() }
                        },
                        onDelete: {
                            HapticManager.impact(.medium)
                            showBatchDeleteConfirm = true
                        },
                        onCancel: {
                            exitBatchMode()
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: batchMode)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        HapticManager.selection()
                        withAnimation { batchMode.toggle() }
                        if !batchMode { selectedIds.removeAll() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: batchMode ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.system(size: 15))
                            Text(batchMode ? "Done" : "Select")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(batchMode ? .dopoAccent : .dopoTextMuted)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NotificationBellView()
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
            .sheet(item: $addToCollSave) { save in
                AddToCollectionSheet(saveId: save.id)
            }
            .sheet(isPresented: $showBatchCollectionPicker) {
                BatchCollectionPickerSheet(
                    collections: batchCollections,
                    selectedCount: selectedIds.count,
                    onSelect: { collectionId in
                        showBatchCollectionPicker = false
                        Task { await executeBatchAddToCollection(collectionId) }
                    }
                )
                .presentationDetents([.medium, .large])
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
            .alert("Delete \(selectedIds.count) Save\(selectedIds.count == 1 ? "" : "s")", isPresented: $showBatchDeleteConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Delete \(selectedIds.count)", role: .destructive) {
                    Task { await executeBatchDelete() }
                }
            } message: {
                Text("Permanently remove \(selectedIds.count) save\(selectedIds.count == 1 ? "" : "s") from your library? This also removes them from all collections.")
            }
            .task { await loadSaves() }
        }
    }

    // MARK: - Batch Mode Helpers

    private func toggleSelection(_ id: String) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }

    private func exitBatchMode() {
        withAnimation {
            batchMode = false
            selectedIds.removeAll()
        }
    }

    private func loadCollectionsForBatch() async {
        guard let token = authManager.accessToken else { return }
        do {
            let response = try await APIClient.shared.fetchCollections(token: token)
            batchCollections = response.collections.filter { $0.isOwner == true }
            showBatchCollectionPicker = true
        } catch {
            // Silently fail — user can retry
        }
    }

    private func executeBatchAddToCollection(_ collectionId: String) async {
        guard let token = authManager.accessToken else { return }
        let ids = Array(selectedIds)
        do {
            try await APIClient.shared.batchAddToCollection(token: token, collectionId: collectionId, saveIds: ids)
            HapticManager.notification(.success)
            exitBatchMode()
        } catch {
            // Silently fail
        }
    }

    private func batchFavorite() async {
        guard let token = authManager.accessToken else { return }
        let ids = Array(selectedIds)
        // Optimistic update
        for id in ids {
            if let idx = saves.firstIndex(where: { $0.id == id }) {
                saves[idx].isFavorite = true
            }
        }
        do {
            try await APIClient.shared.batchFavorite(token: token, saveIds: ids, isFavorite: true)
            HapticManager.notification(.success)
            exitBatchMode()
        } catch {
            // Revert on error
            await loadSaves()
        }
    }

    private func executeBatchDelete() async {
        guard let token = authManager.accessToken else { return }
        let ids = Array(selectedIds)
        // Optimistic update
        withAnimation { saves.removeAll { ids.contains($0.id) } }
        HapticManager.notification(.success)
        exitBatchMode()
        try? await APIClient.shared.batchDelete(token: token, saveIds: ids)
        await loadSaves()
    }

    // MARK: - Data Loading

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

// MARK: - Batch Action Bar

struct BatchActionBar: View {
    let selectedCount: Int
    let totalCount: Int
    let onSelectAll: () -> Void
    let onAddToCollection: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(selectedCount) selected")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.dopoText)
                    Button(action: onSelectAll) {
                        Text(selectedCount == totalCount ? "Deselect all" : "Select all")
                            .font(.system(size: 12))
                            .foregroundColor(.dopoAccent)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    BatchActionButton(icon: "folder.badge.plus", label: "Collection", action: onAddToCollection, disabled: selectedCount == 0)
                    BatchActionButton(icon: "star.fill", label: "Favorite", action: onFavorite, disabled: selectedCount == 0)
                    BatchActionButton(icon: "trash", label: "Delete", action: onDelete, disabled: selectedCount == 0, isDanger: true)
                }

                Button("Cancel", action: onCancel)
                    .font(.system(size: 13))
                    .foregroundColor(.dopoTextDim)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }
}

struct BatchActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    var disabled: Bool = false
    var isDanger: Bool = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 9))
            }
            .foregroundColor(disabled ? .dopoTextDim.opacity(0.4) : (isDanger ? .dopoError : .dopoTextMuted))
            .frame(width: 52, height: 40)
        }
        .disabled(disabled)
        .buttonStyle(.plain)
    }
}

// MARK: - Batch Collection Picker Sheet

struct BatchCollectionPickerSheet: View {
    let collections: [DopoCollection]
    let selectedCount: Int
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(collections) { collection in
                        Button {
                            onSelect(collection.id)
                        } label: {
                            HStack {
                                Text(collection.emoji ?? "📁")
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(collection.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.dopoText)
                                    Text("\(collection.saveCount ?? 0) saves")
                                        .font(.system(size: 12))
                                        .foregroundColor(.dopoTextDim)
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.dopoAccent)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Add \(selectedCount) save\(selectedCount == 1 ? "" : "s") to:")
                }
            }
            .navigationTitle("Choose Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
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
