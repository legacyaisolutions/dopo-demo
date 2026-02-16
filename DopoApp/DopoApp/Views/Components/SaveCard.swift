import SwiftUI

struct SaveCard: View {
    let save: Save
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail area — locked to 120pt
                GeometryReader { geo in
                    ZStack {
                        if let thumbURL = save.thumbnailUrl, let url = URL(string: thumbURL) {
                            Rectangle()
                                .fill(platformGradient)

                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: geo.size.width, height: 120)
                                        .clipped()
                                case .failure:
                                    platformPlaceholder
                                case .empty:
                                    Rectangle().fill(Color.dopoSurface)
                                        .overlay(ProgressView().tint(.dopoTextDim))
                                @unknown default:
                                    platformPlaceholder
                                }
                            }
                        } else {
                            platformPlaceholder
                        }

                        // Enrichment dot
                        VStack {
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(enrichmentColor)
                                    .frame(width: 8, height: 8)
                            }
                            Spacer()
                        }
                        .padding(8)

                        // Platform logo (top-left)
                        VStack {
                            HStack {
                                PlatformLogoOverlay(save.platformColor, size: 22)
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                }
                .frame(height: 120)
                .clipped()

                // Body — fixed height so all cards align in the grid
                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(save.displayTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.dopoText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Creator
                    if let creator = save.creatorName {
                        HStack(spacing: 4) {
                            Text(creator)
                                .foregroundColor(.dopoTextMuted)
                            if let handle = save.creatorHandle {
                                Text(handle)
                                    .foregroundColor(.dopoAccent)
                                    .fontWeight(.medium)
                            }
                        }
                        .font(.system(size: 11))
                        .lineLimit(1)
                    }

                    // Tags
                    if let tags = save.aiTags, !tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(tags.prefix(2), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 9))
                                    .foregroundColor(.dopoTextDim)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.dopoSurfaceHover)
                                    .cornerRadius(4)
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    // Bottom row — pinned to bottom
                    HStack {
                        Text(save.displayDate)
                            .font(.dopoCaption)
                            .foregroundColor(.dopoTextDim)

                        Spacer()

                        Button(action: onFavorite) {
                            Image(systemName: (save.isFavorite ?? false) ? "star.fill" : "star")
                                .font(.system(size: 14))
                                .foregroundColor((save.isFavorite ?? false) ? .dopoAccent : .dopoTextDim)
                        }
                        .buttonStyle(.plain)

                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                                .foregroundColor(.dopoTextDim)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .frame(height: 120)
            }
            .frame(height: 240)
            .background(Color.dopoSurface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dopoBorder, lineWidth: 1))
            .clipped()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Rich platform placeholder (no thumbnail)

    private var platformPlaceholder: some View {
        ZStack {
            // Bold platform-colored gradient background
            LinearGradient(
                colors: [
                    Color.platformColor(save.platform).opacity(0.35),
                    Color.platformColor(save.platform).opacity(0.10),
                    Color.dopoSurface
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Large faded logo in background for visual weight
            PlatformLogo(save.platformColor, size: 52)
                .opacity(0.15)
                .offset(x: 30, y: -10)

            // Centered content type or platform icon
            VStack(spacing: 6) {
                Image(systemName: contentTypeIcon)
                    .font(.system(size: 26))
                    .foregroundColor(Color.platformColor(save.platform).opacity(0.7))

                if let ct = save.contentType, !ct.isEmpty {
                    Text(ct.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundColor(Color.platformColor(save.platform).opacity(0.5))
                }
            }
        }
        .frame(height: 120)
    }

    private var contentTypeIcon: String {
        let ct = (save.contentType ?? "").lowercased()
        if ct.contains("video") { return "play.rectangle.fill" }
        if ct.contains("reel") || ct.contains("short") { return "film" }
        if ct.contains("image") || ct.contains("photo") { return "photo.fill" }
        if ct.contains("article") || ct.contains("post") { return "doc.text.fill" }
        if ct.contains("story") { return "circle.dashed" }
        return save.platformColor.iconName
    }

    private var platformGradient: LinearGradient {
        let base = Color.platformColor(save.platform).opacity(0.15)
        return LinearGradient(colors: [base, Color.dopoSurfaceHover], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var enrichmentColor: Color {
        switch save.enrichmentStatus {
        case "complete": return .dopoSuccess
        case "failed": return .dopoError
        default: return .yellow
        }
    }
}

