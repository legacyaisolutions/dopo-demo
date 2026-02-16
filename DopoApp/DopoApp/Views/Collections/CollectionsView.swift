import SwiftUI

struct CollectionsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var collections: [DopoCollection] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showCreateSheet = false
    @State private var selectedCollection: DopoCollection?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dopoBg.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.dopoAccent)
                } else if let errorMessage {
                    ErrorBanner(message: errorMessage) {
                        Task { await loadCollections() }
                    }
                } else if collections.isEmpty {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.dopoAccent.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "folder.fill.badge.plus")
                                .font(.system(size: 32))
                                .foregroundColor(.dopoAccent)
                        }
                        Text("No collections yet")
                            .font(.dopoHeading)
                            .foregroundColor(.dopoText)
                        Text("Create a collection to organize\nyour saves by theme or topic.")
                            .font(.dopoBody)
                            .foregroundColor(.dopoTextDim)
                            .multilineTextAlignment(.center)
                        Button(action: {
                            HapticManager.impact(.medium)
                            showCreateSheet = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                Text("New Collection")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.dopoAccent)
                            .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            let owned = collections.filter { $0.isOwner == true }
                            if !owned.isEmpty {
                                CollectionSection(title: "My Collections", collections: owned) { coll in
                                    HapticManager.impact(.light)
                                    selectedCollection = coll
                                }
                            }

                            let shared = collections.filter { $0.isOwner == false }
                            if !shared.isEmpty {
                                CollectionSection(title: "Shared With Me", collections: shared) { coll in
                                    HapticManager.impact(.light)
                                    selectedCollection = coll
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        HapticManager.impact(.medium)
                        showCreateSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.dopoAccent)
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateCollectionView {
                    Task { await loadCollections() }
                }
            }
            .sheet(item: $selectedCollection) { coll in
                CollectionDetailView(collection: coll)
            }
            .refreshable { await loadCollections() }
            .task { await loadCollections() }
        }
    }

    private func loadCollections() async {
        guard let token = authManager.accessToken else { return }
        do {
            let response = try await APIClient.shared.fetchCollections(token: token)
            withAnimation {
                collections = response.collections
                errorMessage = nil
                isLoading = false
            }
        } catch {
            withAnimation {
                if collections.isEmpty {
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        }
    }
}

// MARK: - Collection Section

struct CollectionSection: View {
    let title: String
    let collections: [DopoCollection]
    let onTap: (DopoCollection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.dopoTextDim)
                .tracking(1)
                .padding(.leading, 4)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(collections) { coll in
                    CollectionCard(collection: coll)
                        .onTapGesture { onTap(coll) }
                }
            }
        }
    }
}

// MARK: - Collection Card (visual upgrade)

struct CollectionCard: View {
    let collection: DopoCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(collection.displayEmoji)
                    .font(.system(size: 32))

                Spacer()

                // Badges
                VStack(alignment: .trailing, spacing: 4) {
                    if collection.isPublic == true {
                        HStack(spacing: 3) {
                            Image(systemName: "link")
                                .font(.system(size: 8))
                            Text("Public")
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(.dopoAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.dopoAccentGlow)
                        .cornerRadius(4)
                    }

                    if let isOwner = collection.isOwner, !isOwner {
                        HStack(spacing: 3) {
                            Image(systemName: collection.role == "editor" ? "pencil" : "eye")
                                .font(.system(size: 8))
                            Text(collection.role == "editor" ? "Editor" : "Viewer")
                                .font(.system(size: 9, weight: .medium))
                        }
                        .foregroundColor(.dopoTextDim)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.dopoSurfaceHover)
                        .cornerRadius(4)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(collection.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.dopoText)
                    .lineLimit(1)

                Text("\(collection.saveCount ?? 0) saves")
                    .font(.system(size: 12))
                    .foregroundColor(.dopoTextDim)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.dopoSurface)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.dopoBorder, lineWidth: 1)
        )
    }
}

// MARK: - Collection Row (kept for list fallback)

struct CollectionRow: View {
    let collection: DopoCollection

    var body: some View {
        HStack(spacing: 12) {
            Text(collection.displayEmoji)
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(collection.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.dopoText)

                    if collection.isPublic == true {
                        Image(systemName: "link")
                            .font(.system(size: 10))
                            .foregroundColor(.dopoAccent)
                    }

                    if let isOwner = collection.isOwner, !isOwner {
                        Image(systemName: collection.role == "editor" ? "pencil" : "eye")
                            .font(.system(size: 10))
                            .foregroundColor(.dopoTextDim)
                    }
                }

                Text("\(collection.saveCount ?? 0) saves")
                    .font(.dopoCaption)
                    .foregroundColor(.dopoTextDim)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.dopoTextDim)
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.dopoSurface)
    }
}

// MARK: - Create Collection

struct CreateCollectionView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var emoji = "📁"
    @State private var isCreating = false
    let onCreated: () -> Void

    let emojiOptions = ["📁", "🎬", "🎵", "📚", "💡", "🏋️", "🍳", "🎮", "✈️", "💼", "🎨", "❤️"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dopoBg.ignoresSafeArea()

                VStack(spacing: 20) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(emojiOptions, id: \.self) { e in
                                Button(action: {
                                    HapticManager.selection()
                                    emoji = e
                                }) {
                                    Text(e)
                                        .font(.system(size: 28))
                                        .padding(8)
                                        .background(emoji == e ? Color.dopoAccentGlow : Color.dopoSurface)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(emoji == e ? Color.dopoAccent : Color.dopoBorder, lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    TextField("Collection name", text: $name)
                        .textFieldStyle(DopoTextFieldStyle())
                        .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.dopoTextMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        isCreating = true
                        HapticManager.notification(.success)
                        Task {
                            guard let token = authManager.accessToken else { return }
                            try? await APIClient.shared.createCollection(token: token, name: name, emoji: emoji)
                            onCreated()
                            dismiss()
                        }
                    }
                    .foregroundColor(.dopoAccent)
                    .disabled(name.isEmpty || isCreating)
                }
            }
        }
    }
}

// MARK: - Collection Detail

struct CollectionDetailView: View {
    @EnvironmentObject var authManager: AuthManager
    let collection: DopoCollection
    @State private var saves: [Save] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedSave: Save?
    @State private var showActionSheet = false
    @State private var actionSave: Save?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dopoBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 6) {
                        Text(collection.displayEmoji)
                            .font(.system(size: 44))
                        if let desc = collection.description, !desc.isEmpty {
                            Text(desc)
                                .font(.dopoBody)
                                .foregroundColor(.dopoTextMuted)
                        }
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 10))
                                Text("\(saves.count) saves")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.dopoTextDim)

                            if collection.isViewOnly {
                                HStack(spacing: 4) {
                                    Image(systemName: "eye")
                                    Text("View only")
                                }
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.dopoTextDim)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.dopoSurfaceHover)
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 16)

                    Divider().background(Color.dopoBorder)

                    if isLoading {
                        Spacer()
                        ProgressView().tint(.dopoAccent)
                        Spacer()
                    } else if let errorMessage {
                        ErrorBanner(message: errorMessage) {
                            Task { await loadSaves() }
                        }
                    } else if saves.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 28))
                                .foregroundColor(.dopoTextDim)
                            Text("No saves in this collection yet")
                                .foregroundColor(.dopoTextDim)
                                .font(.dopoBody)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                                ForEach(saves) { save in
                                    SaveCard(save: save, onTap: {
                                        HapticManager.impact(.light)
                                        selectedSave = save
                                    }, onFavorite: {
                                        HapticManager.impact(.light)
                                        Task { await toggleFavorite(save) }
                                    }, onDelete: {
                                        HapticManager.impact(.medium)
                                        actionSave = save
                                        showActionSheet = true
                                    })
                                }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .navigationTitle(collection.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.dopoAccent)
                }
            }
            .sheet(item: $selectedSave) { save in
                SaveDetailView(save: save)
            }
            .confirmationDialog(
                "What would you like to do?",
                isPresented: $showActionSheet,
                titleVisibility: .visible
            ) {
                Button("Remove from \(collection.name)") {
                    if let save = actionSave {
                        Task { await removeFromCollection(save) }
                    }
                }
                Button("Delete from Library", role: .destructive) {
                    if let save = actionSave {
                        Task { await deleteFromLibrary(save) }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("\"\(actionSave?.displayTitle.prefix(50) ?? "")\"")
            }
            .task { await loadSaves() }
        }
    }

    private func loadSaves() async {
        guard let token = authManager.accessToken else { return }
        do {
            let response = try await APIClient.shared.fetchLibrary(token: token, collectionId: collection.id)
            withAnimation {
                saves = response.saves
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

    private func toggleFavorite(_ save: Save) async {
        guard let token = authManager.accessToken else { return }
        let newState = !(save.isFavorite ?? false)
        if let idx = saves.firstIndex(where: { $0.id == save.id }) {
            saves[idx].isFavorite = newState
        }
        try? await APIClient.shared.toggleFavorite(token: token, saveId: save.id, isFavorite: newState)
    }

    /// Removes the save from THIS collection only — save stays in the library
    private func removeFromCollection(_ save: Save) async {
        withAnimation { saves.removeAll { $0.id == save.id } }
        HapticManager.notification(.success)
        guard let token = authManager.accessToken else { return }
        try? await APIClient.shared.removeSaveFromCollection(
            token: token, collectionId: collection.id, saveId: save.id
        )
    }

    /// Permanently deletes the save from the entire library (and all collections)
    private func deleteFromLibrary(_ save: Save) async {
        withAnimation { saves.removeAll { $0.id == save.id } }
        HapticManager.notification(.warning)
        guard let token = authManager.accessToken else { return }
        try? await APIClient.shared.deleteSave(token: token, saveId: save.id)
    }
}
