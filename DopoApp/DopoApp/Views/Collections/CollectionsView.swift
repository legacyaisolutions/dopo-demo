import SwiftUI

struct CollectionsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var collections: [DopoCollection] = []
    @State private var isLoading = true
    @State private var showCreateSheet = false
    @State private var selectedCollection: DopoCollection?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dopoBg.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.dopoAccent)
                } else if collections.isEmpty {
                    VStack(spacing: 12) {
                        Text("📁").font(.system(size: 48)).opacity(0.5)
                        Text("No collections yet")
                            .font(.dopoHeading)
                            .foregroundColor(.dopoTextMuted)
                        Text("Create a collection to organize your saves.")
                            .font(.dopoBody)
                            .foregroundColor(.dopoTextDim)
                    }
                } else {
                    List {
                        // Owned collections
                        let owned = collections.filter { $0.isOwner == true }
                        if !owned.isEmpty {
                            Section("My Collections") {
                                ForEach(owned) { coll in
                                    CollectionRow(collection: coll)
                                        .onTapGesture { selectedCollection = coll }
                                }
                            }
                        }

                        // Shared collections
                        let shared = collections.filter { $0.isOwner == false }
                        if !shared.isEmpty {
                            Section("Shared With Me") {
                                ForEach(shared) { coll in
                                    CollectionRow(collection: coll)
                                        .onTapGesture { selectedCollection = coll }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showCreateSheet = true }) {
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
                isLoading = false
            }
        } catch {
            isLoading = false
        }
    }
}

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
                    // Emoji picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(emojiOptions, id: \.self) { e in
                                Button(action: { emoji = e }) {
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

struct CollectionDetailView: View {
    @EnvironmentObject var authManager: AuthManager
    let collection: DopoCollection
    @State private var saves: [Save] = []
    @State private var isLoading = true
    @State private var selectedSave: Save?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dopoBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header info
                    VStack(spacing: 6) {
                        Text(collection.displayEmoji)
                            .font(.system(size: 44))
                        if let desc = collection.description, !desc.isEmpty {
                            Text(desc)
                                .font(.dopoBody)
                                .foregroundColor(.dopoTextMuted)
                        }
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
                    .padding(.vertical, 16)

                    Divider().background(Color.dopoBorder)

                    if isLoading {
                        Spacer()
                        ProgressView().tint(.dopoAccent)
                        Spacer()
                    } else if saves.isEmpty {
                        Spacer()
                        Text("No saves in this collection yet")
                            .foregroundColor(.dopoTextDim)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                                ForEach(saves) { save in
                                    SaveCard(save: save, onTap: {
                                        selectedSave = save
                                    }, onFavorite: {}, onDelete: {})
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
            .task { await loadSaves() }
        }
    }

    private func loadSaves() async {
        guard let token = authManager.accessToken else { return }
        do {
            let response = try await APIClient.shared.fetchLibrary(token: token, collectionId: collection.id)
            withAnimation {
                saves = response.saves
                isLoading = false
            }
        } catch {
            isLoading = false
        }
    }
}
