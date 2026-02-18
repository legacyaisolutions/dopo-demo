import SwiftUI
import UIKit

struct SaveDetailView: View {
    let save: Save
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dopoBg.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Thumbnail hero area
                        ThumbnailHero(save: save)

                        VStack(alignment: .leading, spacing: 16) {
                            // Platform + type badge
                            HStack(spacing: 6) {
                                PlatformLogo(save.platformColor, size: 16)
                                Text(save.platformColor.label)
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(0.5)
                                if let ct = save.contentType {
                                    Text("· \(ct.uppercased())")
                                        .font(.system(size: 10))
                                        .foregroundColor(.dopoTextDim)
                                }
                                Spacer()
                                Text(save.displayDate)
                                    .font(.dopoCaption)
                                    .foregroundColor(.dopoTextDim)
                            }
                            .foregroundColor(Color.platformColor(save.platform))

                            // Title
                            Text(save.displayTitle)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.dopoText)

                            // Creator
                            if let creator = save.creatorName {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.dopoTextDim)
                                    Text(creator)
                                        .foregroundColor(.dopoTextMuted)
                                    if let handle = save.creatorHandle {
                                        Text(handle)
                                            .foregroundColor(.dopoAccent)
                                            .fontWeight(.medium)
                                    }
                                }
                                .font(.system(size: 14))
                            }

                            // Open Original — prominent CTA
                            Button(action: {
                                HapticManager.impact(.medium)
                                if let url = URL(string: save.canonicalUrl ?? save.url) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 8) {
                                    PlatformLogo(save.platformColor, size: 20)
                                    Text("Open on \(save.platformColor.label)")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .foregroundColor(.white)
                                .background(Color.platformColor(save.platform))
                                .cornerRadius(12)
                            }

                            // AI Summary
                            if let summary = save.aiSummary, !summary.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 10))
                                            .foregroundColor(.dopoAccent)
                                        Text("AI SUMMARY")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundColor(.dopoTextDim)
                                            .tracking(1)
                                    }
                                    Text(summary)
                                        .font(.system(size: 14))
                                        .foregroundColor(.dopoTextMuted)
                                        .lineSpacing(4)
                                }
                                .padding(14)
                                .background(Color.dopoSurface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.dopoBorder, lineWidth: 1))
                            }

                            // Tags
                            if let tags = save.aiTags, !tags.isEmpty {
                                FlowLayout(spacing: 6) {
                                    if let category = save.category, category != "other" {
                                        TagChip(text: category, isCategory: true)
                                    }
                                    ForEach(tags, id: \.self) { tag in
                                        TagChip(text: "#\(tag)")
                                    }
                                }
                            }

                            // Action row
                            HStack(spacing: 12) {
                                ActionButton(icon: "square.and.arrow.up", label: "Share") {
                                    HapticManager.impact(.light)
                                    showShareSheet = true
                                }
                                ActionButton(icon: "doc.on.doc", label: "Copy Link") {
                                    HapticManager.notification(.success)
                                    UIPasteboard.general.string = save.canonicalUrl ?? save.url
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.dopoAccent)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = URL(string: save.canonicalUrl ?? save.url) {
                    ShareSheet(items: [url])
                }
            }
        }
    }
}

// MARK: - Thumbnail Hero

struct ThumbnailHero: View {
    let save: Save

    var body: some View {
        ZStack {
            // Background
            Color.dopoSurface

            if let thumbUrl = save.thumbnailUrl, let url = URL(string: thumbUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderView
                    case .empty:
                        ProgressView()
                            .tint(.dopoAccent)
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }

            // Play icon overlay for video content
            if isVideoContent {
                Circle()
                    .fill(.black.opacity(0.5))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .offset(x: 2)
                    )
            }

            // Gradient overlay at bottom for visual depth
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, Color.dopoBg.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 40)
            }
        }
        .frame(height: isVideoContent ? 260 : 200)
        .clipped()
    }

    private var isVideoContent: Bool {
        save.contentType?.lowercased().contains("video") == true
            || save.platform == "youtube"
            || save.platform == "tiktok"
    }

    private var placeholderView: some View {
        VStack(spacing: 10) {
            PlatformLogo(save.platformColor, size: 48)
                .opacity(0.6)
            Text(save.platformColor.label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.dopoTextDim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Supporting Views

struct TagChip: View {
    let text: String
    var isCategory: Bool = false

    var body: some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundColor(isCategory ? .dopoAccent : .dopoTextDim)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isCategory ? Color.dopoAccentGlow : Color.dopoSurfaceHover)
            .cornerRadius(4)
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.dopoTextMuted)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.dopoSurface)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.dopoBorder, lineWidth: 1))
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, offset) in result.offsets.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (offsets: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxHeight: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            offsets.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            maxHeight = max(maxHeight, currentY + lineHeight)
        }

        return (offsets, CGSize(width: maxWidth, height: maxHeight))
    }
}
