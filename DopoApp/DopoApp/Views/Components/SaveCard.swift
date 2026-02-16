import SwiftUI

struct SaveCard: View {
    let save: Save
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail area
                ZStack {
                    if let thumbURL = save.thumbnailUrl, let url = URL(string: thumbURL) {
                        // Has thumbnail — show image with gradient fallback
                        Rectangle()
                            .fill(platformGradient)
                            .frame(height: 120)

                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 120)
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
                        // No thumbnail — rich platform-branded placeholder
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

                    // Platform pill badge overlay (top-left)
                    VStack {
                        HStack {
                            HStack(spacing: 3) {
                                Image(systemName: save.platformColor.iconName)
                                    .font(.system(size: 8))
                                Text(save.platformColor.label)
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.55))
                            .cornerRadius(6)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(8)
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
            .background(Color.dopoSurface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dopoBorder, lineWidth: 1))
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

            // Large faded icon in background for visual weight
            Image(systemName: save.platformColor.iconName)
                .font(.system(size: 52, weight: .ultraLight))
                .foregroundColor(Color.platformColor(save.platform).opacity(0.15))
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

struct PlatformPill: View {
    let platform: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if platform != "all" {
                    Image(systemName: PlatformTheme.from(platform).iconName)
                        .font(.system(size: 11))
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
