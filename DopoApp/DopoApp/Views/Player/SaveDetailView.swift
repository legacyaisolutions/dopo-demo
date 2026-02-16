import SwiftUI
import WebKit

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
                        // In-app content viewer
                        InAppContentViewer(save: save)
                            .frame(height: videoPlayerHeight)
                            .cornerRadius(0)

                        VStack(alignment: .leading, spacing: 16) {
                            // Platform + type
                            HStack(spacing: 6) {
                                Image(systemName: save.platformColor.iconName)
                                    .font(.system(size: 12))
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

                            // AI Summary
                            if let summary = save.aiSummary, !summary.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("AI SUMMARY")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.dopoTextDim)
                                        .tracking(1)
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

                            // Action buttons
                            HStack(spacing: 12) {
                                ActionButton(icon: "square.and.arrow.up", label: "Share") {
                                    showShareSheet = true
                                }
                                ActionButton(icon: "safari", label: "Open Original") {
                                    if let url = URL(string: save.canonicalUrl ?? save.url) {
                                        UIApplication.shared.open(url)
                                    }
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

    private var videoPlayerHeight: CGFloat {
        let isVideo = save.contentType?.lowercased().contains("video") == true
            || save.platform == "youtube"
            || save.platform == "tiktok"
        return isVideo ? 320 : 240
    }
}

// MARK: - In-App Content Viewer (WebView-based)

struct InAppContentViewer: UIViewRepresentable {
    let save: Save

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsPictureInPictureMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(Color.dopoSurface)
        webView.scrollView.isScrollEnabled = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let embedURL = embeddableURL
        if let url = URL(string: embedURL) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    private var embeddableURL: String {
        let urlStr = save.canonicalUrl ?? save.url

        // YouTube embed
        if save.platform == "youtube" {
            if let videoId = extractYouTubeId(from: urlStr) {
                return "https://www.youtube.com/embed/\(videoId)?autoplay=0&playsinline=1&rel=0"
            }
        }

        // For other platforms, load in iframe wrapper
        return urlStr
    }

    private func extractYouTubeId(from urlString: String) -> String? {
        // Handle youtu.be/ID
        if urlString.contains("youtu.be/") {
            return urlString.components(separatedBy: "youtu.be/").last?.components(separatedBy: "?").first
        }
        // Handle youtube.com/watch?v=ID
        if let components = URLComponents(string: urlString),
           let videoId = components.queryItems?.first(where: { $0.name == "v" })?.value {
            return videoId
        }
        // Handle youtube.com/shorts/ID
        if urlString.contains("/shorts/") {
            return urlString.components(separatedBy: "/shorts/").last?.components(separatedBy: "?").first
        }
        return nil
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
