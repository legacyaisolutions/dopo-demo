import SwiftUI

struct SaveCard: View {
    let save: Save
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail
                ZStack {
                    Rectangle()
                        .fill(platformGradient)
                        .frame(height: 120)

                    if let thumbURL = save.thumbnailUrl, let url = URL(string: thumbURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 120)
                                    .clipped()
                            default:
                                platformIcon
                            }
                        }
                    } else {
                        platformIcon
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
                }
                .frame(height: 120)
                .clipped()

                // Body
                VStack(alignment: .leading, spacing: 6) {
                    // Platform badge
                    HStack(spacing: 4) {
                        Image(systemName: save.platformColor.iconName)
                            .font(.system(size: 10))
                        Text(save.platformColor.label)
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.5)
                        if let ct = save.contentType, !ct.isEmpty {
                            Text("·")
                                .foregroundColor(.dopoTextDim)
                            Text(ct.uppercased())
                                .font(.system(size: 9))
                                .foregroundColor(.dopoTextDim)
                        }
                    }
                    .foregroundColor(Color.platformColor(save.platform))
                    .textCase(.uppercase)

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
                            ForEach(tags.prefix(3), id: \.self) { tag in
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

                    // Bottom row
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
                    .padding(.top, 4)
                }
                .padding(12)
            }
            .background(Color.dopoSurface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dopoBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var platformGradient: LinearGradient {
        let base = Color.platformColor(save.platform).opacity(0.15)
        return LinearGradient(colors: [base, Color.dopoSurfaceHover], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var platformIcon: some View {
        Image(systemName: save.platformColor.iconName)
            .font(.system(size: 32))
            .foregroundColor(Color.platformColor(save.platform).opacity(0.6))
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
