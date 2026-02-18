import SwiftUI
import UIKit

// MARK: - Collections Main View

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
                    CollectionsSkeletonView()
                } else if let errorMessage {
                    ErrorBanner(message: errorMessage) {
                        Task { await loadCollections() }
                    }
                } else if collections.isEmpty {
                    EmptyCollectionsView {
                        HapticManager.impact(.medium)
                        showCreateSheet = true
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // "All Saves" hero card at top
                            AllSavesCard()
                                .onTapGesture {
                                    HapticManager.impact(.light)
                                    // Could navigate to full library
                                }

                            let owned = collections.filter { $0.isOwner != false }
                            let shared = collections.filter { $0.isOwner == false }

                            if !owned.isEmpty {
                                CollectionSection(
                                    title: "My Collections",
                                    collections: owned,
                                    token: authManager.accessToken
                                ) { coll in
                                    HapticManager.impact(.light)
                                    selectedCollection = coll
                                }
                            }

                            if !shared.isEmpty {
                                CollectionSection(
                                    title: "Shared With Me",
                                    collections: shared,
                                    token: authManager.accessToken
                                ) { coll in
                                    HapticManager.impact(.light)
                                    selectedCollection = coll
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
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
                            .font(.system(size: 16, weight: .semibold))
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
            withAnimation(.easeInOut(duration: 0.3)) {
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

// MARK: - All Saves Hero Card

struct AllSavesCard: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color.dopoAccent.opacity(0.3),
                    Color.dopoAccent.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative grid dots
            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { col in
                            Circle()
                                .fill(Color.dopoAccent.opacity(Double.random(in: 0.05...0.2)))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.dopoAccent)
                    .padding(.bottom, 4)
                Text("All Saves")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.dopoText)
                Text("Your entire library")
                    .font(.system(size: 12))
                    .foregroundColor(.dopoTextMuted)
            }
            .padding(16)
        }
        .frame(height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.dopoAccent.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Collection Section

struct CollectionSection: View {
    let title: String
    let collections: [DopoCollection]
    let token: String?
    let onTap: (DopoCollection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.dopoTextDim)
                    .tracking(1.5)

                Spacer()

                Text("\(collections.count)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.dopoTextDim)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.dopoSurfaceHover)
                    .cornerRadius(6)
            }
            .padding(.horizontal, 4)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(collections) { coll in
                    InstaCollectionCard(collection: coll, token: token)
                        .onTapGesture { onTap(coll) }
                }
            }
        }
    }
}

// MARK: - Instagram-Style Collection Card

struct InstaCollectionCard: View {
    let collection: DopoCollection
    let token: String?
    @State private var thumbnails: [String] = []
    @State private var hasLoaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Mosaic thumbnail area
            GeometryReader { geo in
                let size = geo.size.width

                ZStack {
                    // Base gradient per-collection for visual variety
                    collectionGradient
                        .frame(width: size, height: size)

                    if thumbnails.count >= 4 {
                        // 2x2 mosaic
                        mosaicGrid(size: size, urls: Array(thumbnails.prefix(4)))
                    } else if thumbnails.count >= 2 {
                        // 1 big + 2 small
                        splitLayout(size: size, urls: thumbnails)
                    } else if thumbnails.count == 1 {
                        // Single large thumbnail
                        AsyncImage(url: URL(string: thumbnails[0])) { phase in
                            if case .success(let image) = phase {
                                image.resizable().aspectRatio(contentMode: .fill)
                            }
                        }
                        .frame(width: size, height: size)
                        .clipped()
                    } else if !hasLoaded {
                        // Loading shimmer
                        ShimmerView()
                            .frame(width: size, height: size)
                    } else {
                        // Empty — show stylized placeholder
                        emptyPlaceholder(size: size)
                    }

                    // Dark gradient overlay for text legibility
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [.clear, .clear, Color.black.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: size * 0.55)
                    }

                    // Collection name overlay
                    VStack(alignment: .leading, spacing: 2) {
                        Spacer()

                        Text(collection.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

                        HStack(spacing: 6) {
                            Text("\(collection.saveCount ?? 0) saves")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))

                            if collection.isPublic == true {
                                HStack(spacing: 2) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 8))
                                    Text("Public")
                                        .font(.system(size: 9, weight: .medium))
                                }
                                .foregroundColor(.dopoAccent)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(4)
                            }

                            if let isOwner = collection.isOwner, !isOwner {
                                HStack(spacing: 2) {
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 8))
                                    Text("Shared")
                                        .font(.system(size: 9, weight: .medium))
                                }
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(4)
                            }
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(width: size, height: size)
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.dopoBorder.opacity(0.6), lineWidth: 0.5)
            )
        }
        .task {
            await loadThumbnails()
        }
    }

    // MARK: - Mosaic Layouts

    private func mosaicGrid(size: CGFloat, urls: [String]) -> some View {
        let gap: CGFloat = 1.5
        let half = (size - gap) / 2

        return ZStack {
            VStack(spacing: gap) {
                HStack(spacing: gap) {
                    thumbnailImage(urls[0]).frame(width: half, height: half).clipped()
                    thumbnailImage(urls[1]).frame(width: half, height: half).clipped()
                }
                HStack(spacing: gap) {
                    thumbnailImage(urls[2]).frame(width: half, height: half).clipped()
                    thumbnailImage(urls[3]).frame(width: half, height: half).clipped()
                }
            }
        }
    }

    private func splitLayout(size: CGFloat, urls: [String]) -> some View {
        let gap: CGFloat = 1.5
        let bigWidth = size * 0.65
        let smallWidth = size - bigWidth - gap
        let halfHeight = (size - gap) / 2

        return HStack(spacing: gap) {
            thumbnailImage(urls[0])
                .frame(width: bigWidth, height: size)
                .clipped()

            VStack(spacing: gap) {
                if urls.count > 1 {
                    thumbnailImage(urls[1])
                        .frame(width: smallWidth, height: halfHeight)
                        .clipped()
                }
                if urls.count > 2 {
                    thumbnailImage(urls[2])
                        .frame(width: smallWidth, height: halfHeight)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.dopoSurfaceHover)
                        .frame(width: smallWidth, height: halfHeight)
                }
            }
        }
    }

    private func thumbnailImage(_ urlString: String) -> some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                Rectangle().fill(Color.dopoSurfaceHover)
            case .empty:
                Rectangle().fill(Color.dopoSurface)
            @unknown default:
                Rectangle().fill(Color.dopoSurface)
            }
        }
    }

    private func emptyPlaceholder(size: CGFloat) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 28))
                .foregroundColor(.dopoTextDim.opacity(0.5))
            Text("No saves yet")
                .font(.system(size: 11))
                .foregroundColor(.dopoTextDim.opacity(0.5))
        }
        .frame(width: size, height: size)
    }

    private var collectionGradient: some View {
        // Generate a unique-ish gradient based on collection name
        let hue = Double(abs(collection.name.hashValue) % 360) / 360.0
        return LinearGradient(
            colors: [
                Color(hue: hue, saturation: 0.3, brightness: 0.15),
                Color(hue: hue, saturation: 0.2, brightness: 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Data Loading

    private func loadThumbnails() async {
        guard let token, !hasLoaded else { return }
        do {
            let response = try await APIClient.shared.fetchLibrary(
                token: token, collectionId: collection.id, limit: 4
            )
            let urls = response.saves.compactMap { $0.thumbnailUrl }
            withAnimation(.easeIn(duration: 0.2)) {
                thumbnails = urls
                hasLoaded = true
            }
        } catch {
            hasLoaded = true
        }
    }
}

// MARK: - Shimmer Loading Effect

struct ShimmerView: View {
    @State private var isAnimating = false

    var body: some View {
        Rectangle()
            .fill(Color.dopoSurface)
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.dopoSurface,
                                Color.dopoSurfaceHover.opacity(0.6),
                                Color.dopoSurface
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 300 : -300)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Empty State

struct EmptyCollectionsView: View {
    let onCreateTap: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                // Layered cards visual
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.dopoSurfaceHover.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-8))
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.dopoSurfaceHover.opacity(0.5))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(4))
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.dopoSurface)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(.dopoAccent)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.dopoBorder, lineWidth: 1)
                    )
            }

            VStack(spacing: 8) {
                Text("Curate your saves")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.dopoText)

                Text("Group your best finds into\ncollections to keep things organized.")
                    .font(.dopoBody)
                    .foregroundColor(.dopoTextDim)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            Button(action: onCreateTap) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text("Create Collection")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.dopoAccent, Color(red: 1.0, green: 0.55, blue: 0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: .dopoAccent.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.top, 8)

            Spacer()
        }
    }
}

// MARK: - Skeleton Loading

struct CollectionsSkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero skeleton
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.dopoSurface)
                    .frame(height: 100)

                // Cards skeleton
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.dopoSurface)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .opacity(isAnimating ? 0.4 : 0.8)
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { isAnimating = true }
        }
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

                VStack(spacing: 24) {
                    // Emoji picker
                    VStack(spacing: 10) {
                        Text(emoji)
                            .font(.system(size: 56))
                            .padding(.top, 12)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(emojiOptions, id: \.self) { e in
                                    Button(action: {
                                        HapticManager.selection()
                                        withAnimation(.spring(response: 0.3)) { emoji = e }
                                    }) {
                                        Text(e)
                                            .font(.system(size: 24))
                                            .padding(8)
                                            .background(emoji == e ? Color.dopoAccentGlow : Color.dopoSurface)
                                            .cornerRadius(10)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(emoji == e ? Color.dopoAccent : Color.dopoBorder, lineWidth: emoji == e ? 2 : 1)
                                            )
                                            .scaleEffect(emoji == e ? 1.1 : 1.0)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    TextField("Collection name", text: $name)
                        .textFieldStyle(DopoTextFieldStyle())
                        .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 16)
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
                    .font(.system(size: 16, weight: .semibold))
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
    @State private var showShareSheet = false
    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var displayName: String = ""
    @Environment(\.dismiss) private var dismiss

    private var isOwner: Bool {
        collection.isOwner ?? true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dopoBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Modern header — no folder icon
                    VStack(spacing: 10) {
                        // Stats row
                        HStack(spacing: 16) {
                            StatPill(icon: "bookmark.fill", value: "\(saves.count)", label: "saves")

                            if collection.isPublic == true {
                                StatPill(icon: "globe", value: nil, label: "Public", tint: .dopoAccent)
                            }

                            if collection.isViewOnly {
                                StatPill(icon: "eye", value: nil, label: "View only")
                            } else if let isOwner = collection.isOwner, !isOwner {
                                StatPill(icon: "person.2", value: nil, label: "Collaborator")
                            }
                        }

                        if let desc = collection.description, !desc.isEmpty {
                            Text(desc)
                                .font(.system(size: 13))
                                .foregroundColor(.dopoTextMuted)
                                .multilineTextAlignment(.center)
                        }

                        // Action buttons
                        HStack(spacing: 10) {
                            if isOwner {
                                Button(action: {
                                    HapticManager.impact(.medium)
                                    showShareSheet = true
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "person.badge.plus")
                                            .font(.system(size: 12))
                                        Text("Share")
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.dopoAccent)
                                    .cornerRadius(10)
                                }
                            }

                            if let shareToken = collection.shareToken, collection.isPublic == true {
                                Button(action: {
                                    HapticManager.notification(.success)
                                    let shareURL = "https://adyqktvkxwohzxzjqpjt.supabase.co/functions/v1/library/shared/\(shareToken)"
                                    UIPasteboard.general.string = shareURL
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "link")
                                            .font(.system(size: 12))
                                        Text("Copy Link")
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(.dopoAccent)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.dopoAccentGlow)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.dopoAccent.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)

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
                        VStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 32))
                                .foregroundColor(.dopoTextDim.opacity(0.5))
                            Text("No saves yet")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.dopoTextDim)
                            Text("Add saves from your library to\nstart building this collection.")
                                .font(.system(size: 13))
                                .foregroundColor(.dopoTextDim.opacity(0.7))
                                .multilineTextAlignment(.center)
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
            .navigationTitle(displayName.isEmpty ? collection.name : displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.dopoAccent)
                }
                if isOwner {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button(action: {
                                renameText = displayName.isEmpty ? collection.name : displayName
                                showRenameAlert = true
                            }) {
                                Label("Rename", systemImage: "pencil")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.dopoAccent)
                        }
                    }
                }
            }
            .alert("Rename Collection", isPresented: $showRenameAlert) {
                TextField("Collection name", text: $renameText)
                Button("Save") {
                    guard !renameText.isEmpty else { return }
                    Task { await renameCollection() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter a new name for this collection")
            }
            .onAppear { displayName = collection.name }
            .sheet(item: $selectedSave) { save in
                SaveDetailView(save: save)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareCollectionView(collection: collection)
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

    private func renameCollection() async {
        guard let token = authManager.accessToken, !renameText.isEmpty else { return }
        do {
            try await APIClient.shared.renameCollection(token: token, collectionId: collection.id, name: renameText)
            HapticManager.notification(.success)
            withAnimation { displayName = renameText }
        } catch {
            HapticManager.notification(.error)
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

    private func removeFromCollection(_ save: Save) async {
        withAnimation { saves.removeAll { $0.id == save.id } }
        HapticManager.notification(.success)
        guard let token = authManager.accessToken else { return }
        try? await APIClient.shared.removeSaveFromCollection(
            token: token, collectionId: collection.id, saveId: save.id
        )
    }

    private func deleteFromLibrary(_ save: Save) async {
        withAnimation { saves.removeAll { $0.id == save.id } }
        HapticManager.notification(.warning)
        guard let token = authManager.accessToken else { return }
        try? await APIClient.shared.deleteSave(token: token, saveId: save.id)
    }
}

// MARK: - Stat Pill

struct StatPill: View {
    let icon: String
    let value: String?
    let label: String
    var tint: Color = .dopoTextDim

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            if let value {
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
            }
            Text(label)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tint.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Share Collection Sheet

struct ShareCollectionView: View {
    @EnvironmentObject var authManager: AuthManager
    let collection: DopoCollection
    @Environment(\.dismiss) private var dismiss
    @State private var isPublic: Bool
    @State private var shareToken: String?
    @State private var collaborators: [Collaborator] = []
    @State private var isLoadingCollabs = true
    @State private var inviteEmail = ""
    @State private var inviteRole = "viewer"
    @State private var isInviting = false
    @State private var toastMessage: String?

    init(collection: DopoCollection) {
        self.collection = collection
        _isPublic = State(initialValue: collection.isPublic ?? false)
        _shareToken = State(initialValue: collection.shareToken)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dopoBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Public link toggle
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PUBLIC LINK")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.dopoTextDim)
                                .tracking(1.5)

                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Anyone with the link")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.dopoText)
                                    Text(isPublic ? "Can view this collection" : "Link sharing is off")
                                        .font(.system(size: 12))
                                        .foregroundColor(.dopoTextDim)
                                }

                                Spacer()

                                Toggle("", isOn: $isPublic)
                                    .labelsHidden()
                                    .tint(.dopoAccent)
                                    .onChange(of: isPublic) { _ in
                                        Task { await toggleShare() }
                                    }
                            }
                            .padding(14)
                            .background(Color.dopoSurface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.dopoBorder, lineWidth: 1)
                            )

                            if isPublic, let token = shareToken {
                                Button(action: {
                                    HapticManager.notification(.success)
                                    let url = "https://adyqktvkxwohzxzjqpjt.supabase.co/functions/v1/library/shared/\(token)"
                                    UIPasteboard.general.string = url
                                    toastMessage = "Link copied!"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        toastMessage = nil
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "link")
                                        Text("Copy share link")
                                            .font(.system(size: 13, weight: .medium))
                                        Spacer()
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 12))
                                    }
                                    .foregroundColor(.dopoAccent)
                                    .padding(12)
                                    .background(Color.dopoAccentGlow)
                                    .cornerRadius(10)
                                }
                            }
                        }

                        // Invite collaborator
                        VStack(alignment: .leading, spacing: 12) {
                            Text("INVITE PEOPLE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.dopoTextDim)
                                .tracking(1.5)

                            HStack(spacing: 8) {
                                TextField("Email address", text: $inviteEmail)
                                    .textFieldStyle(DopoTextFieldStyle())
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .keyboardType(.emailAddress)

                                Menu {
                                    Button(action: { inviteRole = "viewer" }) {
                                        Label("Viewer", systemImage: "eye")
                                    }
                                    Button(action: { inviteRole = "editor" }) {
                                        Label("Collaborator", systemImage: "person.2")
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: inviteRole == "editor" ? "person.2" : "eye")
                                            .font(.system(size: 11))
                                        Text(inviteRole == "editor" ? "Collaborator" : "Viewer")
                                            .font(.system(size: 12, weight: .medium))
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 9))
                                    }
                                    .foregroundColor(.dopoTextMuted)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 10)
                                    .background(Color.dopoSurface)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.dopoBorder, lineWidth: 1)
                                    )
                                }
                            }

                            Button(action: {
                                HapticManager.impact(.medium)
                                Task { await sendInvite() }
                            }) {
                                HStack(spacing: 6) {
                                    if isInviting {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "paperplane.fill")
                                            .font(.system(size: 12))
                                    }
                                    Text("Send Invite")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(inviteEmail.isEmpty ? Color.dopoTextDim : Color.dopoAccent)
                                .cornerRadius(10)
                            }
                            .disabled(inviteEmail.isEmpty || isInviting)
                        }

                        // Current collaborators
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("COLLABORATORS")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.dopoTextDim)
                                    .tracking(1.5)

                                Spacer()

                                if !collaborators.isEmpty {
                                    Text("\(collaborators.count)")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.dopoTextDim)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.dopoSurfaceHover)
                                        .cornerRadius(6)
                                }
                            }

                            if isLoadingCollabs {
                                HStack {
                                    Spacer()
                                    ProgressView().tint(.dopoTextDim)
                                    Spacer()
                                }
                                .padding(.vertical, 20)
                            } else if collaborators.isEmpty {
                                HStack {
                                    Image(systemName: "person.2.slash")
                                        .foregroundColor(.dopoTextDim.opacity(0.5))
                                    Text("No collaborators yet")
                                        .font(.system(size: 13))
                                        .foregroundColor(.dopoTextDim)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(collaborators) { collab in
                                        CollaboratorRow(
                                            collaborator: collab,
                                            onRemove: {
                                                Task { await removeCollab(collab) }
                                            }
                                        )
                                        if collab.id != collaborators.last?.id {
                                            Divider().background(Color.dopoBorder)
                                        }
                                    }
                                }
                                .background(Color.dopoSurface)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.dopoBorder, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(16)
                }

                // Toast overlay
                if let toast = toastMessage {
                    VStack {
                        Spacer()
                        Text(toast)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.dopoSuccess)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                            .padding(.bottom, 30)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(), value: toastMessage)
                }
            }
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.dopoAccent)
                }
            }
            .task { await loadCollaborators() }
        }
    }

    private func toggleShare() async {
        guard let token = authManager.accessToken else { return }
        do {
            let updated = try await APIClient.shared.toggleCollectionShare(token: token, collectionId: collection.id)
            withAnimation {
                isPublic = updated.isPublic ?? false
                shareToken = updated.shareToken
            }
            HapticManager.notification(isPublic ? .success : .warning)
        } catch {
            withAnimation { isPublic.toggle() } // revert on failure
        }
    }

    private func sendInvite() async {
        guard let token = authManager.accessToken else { return }
        isInviting = true
        do {
            try await APIClient.shared.inviteCollaborator(
                token: token, collectionId: collection.id, email: inviteEmail, role: inviteRole
            )
            HapticManager.notification(.success)
            toastMessage = "Invite sent to \(inviteEmail)"
            inviteEmail = ""
            await loadCollaborators()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toastMessage = nil }
        } catch {
            HapticManager.notification(.error)
            toastMessage = "Failed to send invite"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toastMessage = nil }
        }
        isInviting = false
    }

    private func loadCollaborators() async {
        guard let token = authManager.accessToken else {
            isLoadingCollabs = false
            return
        }
        do {
            let response = try await APIClient.shared.fetchCollaborators(token: token, collectionId: collection.id)
            withAnimation {
                collaborators = response.collaborators
                isLoadingCollabs = false
            }
        } catch {
            isLoadingCollabs = false
        }
    }

    private func removeCollab(_ collab: Collaborator) async {
        guard let token = authManager.accessToken else { return }
        withAnimation { collaborators.removeAll { $0.id == collab.id } }
        HapticManager.notification(.success)
        try? await APIClient.shared.removeCollaborator(token: token, collaboratorId: collab.id)
    }
}

// MARK: - Collaborator Row

struct CollaboratorRow: View {
    let collaborator: Collaborator
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.dopoSurfaceHover)
                    .frame(width: 36, height: 36)
                Text(String(collaborator.displayEmail.prefix(1)).uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.dopoTextMuted)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(collaborator.displayEmail)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.dopoText)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(collaborator.role == "editor" ? "Collaborator" : collaborator.role.capitalized)
                        .font(.system(size: 11))
                        .foregroundColor(.dopoTextDim)

                    if !collaborator.accepted {
                        Text("Pending")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.dopoAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.dopoAccentGlow)
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.dopoTextDim)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
