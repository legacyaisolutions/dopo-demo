import SwiftUI

struct AddToCollectionSheet: View {
    let saveId: String
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var collections: [DopoCollection] = []
    @State private var membershipIds: Set<String> = []
    @State private var isLoading = true
    @State private var showCreateNew = false
    @State private var newName = ""
    @State private var newEmoji = "📁"
    @State private var isCreating = false

    let emojiOptions = ["📁", "🎬", "🎵", "📚", "💡", "🏋️", "🍳", "🎮", "✈️", "💼", "🎨", "❤️"]

    var editableCollections: [DopoCollection] {
        collections.filter { $0.isEditor }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dopoBg.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(.dopoAccent)
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Create New button or inline form
                            if showCreateNew {
                                createNewForm
                            } else {
                                Button {
                                    HapticManager.impact(.light)
                                    withAnimation(.easeOut(duration: 0.2)) { showCreateNew = true }
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Create new collection")
                                            .font(.system(size: 14, weight: .medium))
                                        Spacer()
                                    }
                                    .foregroundColor(.dopoAccent)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                            .foregroundColor(.dopoBorder)
                                    )
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                            }

                            // Collection list
                            if editableCollections.isEmpty && !showCreateNew {
                                VStack(spacing: 8) {
                                    Text("No collections yet")
                                        .font(.system(size: 14))
                                        .foregroundColor(.dopoTextMuted)
                                    Text("Create one above to get started")
                                        .font(.system(size: 12))
                                        .foregroundColor(.dopoTextDim)
                                }
                                .padding(.top, 40)
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(editableCollections) { coll in
                                        CollectionToggleRow(
                                            collection: coll,
                                            isMember: membershipIds.contains(coll.id)
                                        ) {
                                            Task { await toggleMembership(coll) }
                                        }
                                        Divider().background(Color.dopoBorder).padding(.leading, 56)
                                    }
                                }
                                .padding(.top, 12)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.dopoAccent)
                }
            }
            .task { await loadData() }
        }
    }

    // MARK: - Inline Create Form

    private var createNewForm: some View {
        VStack(spacing: 12) {
            // Emoji picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(emojiOptions, id: \.self) { emoji in
                        Button {
                            newEmoji = emoji
                            HapticManager.selection()
                        } label: {
                            Text(emoji)
                                .font(.system(size: 24))
                                .frame(width: 40, height: 40)
                                .background(newEmoji == emoji ? Color.dopoAccentGlow : Color.dopoSurface)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(newEmoji == emoji ? Color.dopoAccent : Color.dopoBorder, lineWidth: 1)
                                )
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                TextField("Collection name", text: $newName)
                    .font(.system(size: 14))
                    .padding(10)
                    .background(Color.dopoSurface)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.dopoBorder, lineWidth: 1))
                    .foregroundColor(.dopoText)
                    .submitLabel(.done)
                    .onSubmit { Task { await createAndAdd() } }

                Button {
                    Task { await createAndAdd() }
                } label: {
                    Text(isCreating ? "..." : "Create")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(newName.isEmpty ? Color.dopoTextDim : Color.dopoAccent)
                        .cornerRadius(8)
                }
                .disabled(newName.isEmpty || isCreating)
            }
        }
        .padding(14)
        .background(Color.dopoAccent.opacity(0.05))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dopoAccent.opacity(0.15), lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Data

    private func loadData() async {
        guard let token = authManager.accessToken else { return }
        do {
            let collResponse = try await APIClient.shared.fetchCollections(token: token)
            collections = collResponse.collections

            // Get current save's collection memberships
            let libResponse = try await APIClient.shared.fetchLibrary(token: token, limit: 1)
            // We need the save's collection_ids — fetch the full save
            let saveResponse = try await APIClient.shared.fetchLibrary(token: token, limit: 50)
            if let save = saveResponse.saves.first(where: { $0.id == saveId }) {
                membershipIds = Set(save.collectionIds ?? [])
            }
        } catch {
            // Show empty state
        }
        isLoading = false
    }

    private func toggleMembership(_ collection: DopoCollection) async {
        guard let token = authManager.accessToken else { return }
        let isMember = membershipIds.contains(collection.id)
        HapticManager.impact(.light)

        // Optimistic update
        if isMember {
            membershipIds.remove(collection.id)
        } else {
            membershipIds.insert(collection.id)
        }

        do {
            if isMember {
                try await APIClient.shared.removeSaveFromCollection(token: token, collectionId: collection.id, saveId: saveId)
            } else {
                try await APIClient.shared.addSaveToCollection(token: token, collectionId: collection.id, saveId: saveId)
            }
        } catch {
            // Revert on failure
            if isMember {
                membershipIds.insert(collection.id)
            } else {
                membershipIds.remove(collection.id)
            }
        }
    }

    private func createAndAdd() async {
        guard let token = authManager.accessToken, !newName.isEmpty else { return }
        isCreating = true
        HapticManager.impact(.medium)

        do {
            let newCollection = try await APIClient.shared.createCollectionAndAddSave(
                token: token, name: newName, emoji: newEmoji, saveId: saveId
            )
            collections.insert(newCollection, at: 0)
            membershipIds.insert(newCollection.id)
            newName = ""
            showCreateNew = false
            HapticManager.notification(.success)
        } catch {
            HapticManager.notification(.error)
        }
        isCreating = false
    }
}

// MARK: - Row

struct CollectionToggleRow: View {
    let collection: DopoCollection
    let isMember: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(collection.displayEmoji)
                    .font(.system(size: 22))
                    .frame(width: 36, height: 36)
                    .background(Color.dopoSurface)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(collection.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.dopoText)

                    if let count = collection.saveCount {
                        Text("\(count) saves")
                            .font(.system(size: 11))
                            .foregroundColor(.dopoTextDim)
                    }
                }

                Spacer()

                Image(systemName: isMember ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isMember ? .dopoAccent : .dopoTextDim)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}
