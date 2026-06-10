import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dopoBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {

                        // MARK: - Hero Section
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.dopoAccent.opacity(0.12))
                                    .frame(width: 88, height: 88)

                                Image(systemName: "sparkle.magnifyingglass")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundColor(.dopoAccent)
                            }

                            VStack(spacing: 8) {
                                Text("Discover")
                                    .font(.dopoTitle)
                                    .foregroundColor(.dopoText)

                                Text("Coming Soon")
                                    .font(.dopoCaption)
                                    .foregroundColor(.dopoAccent)
                                    .textCase(.uppercase)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.dopoAccent.opacity(0.15))
                                    )
                            }
                        }
                        .padding(.top, 40)

                        // MARK: - Description
                        VStack(spacing: 12) {
                            Text("See what the people you follow are curating in real time.")
                                .font(.dopoHeading)
                                .foregroundColor(.dopoText)
                                .multilineTextAlignment(.center)

                            Text("Discover will show you trending collections, curator activity, and content matched to your taste — all driven by human curation, not algorithms.")
                                .font(.dopoBody)
                                .foregroundColor(.dopoTextMuted)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 32)

                        // MARK: - What's Coming Cards
                        VStack(spacing: 12) {
                            Text("WHAT'S COMING")
                                .font(.dopoSmall)
                                .foregroundColor(.dopoTextDim)
                                .textCase(.uppercase)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            DiscoverFeatureCard(
                                icon: "person.2.fill",
                                title: "Activity Stream",
                                description: "See what curators you follow are saving and building"
                            )

                            DiscoverFeatureCard(
                                icon: "flame.fill",
                                title: "Trending Collections",
                                description: "Discover the most-followed collections across every category"
                            )

                            DiscoverFeatureCard(
                                icon: "waveform.path",
                                title: "Vibing",
                                description: "Find curators who share your vibe with AI-powered matching"
                            )

                            DiscoverFeatureCard(
                                icon: "arrow.triangle.branch",
                                title: "Collection Remixes",
                                description: "Fork any public collection and make it your own"
                            )

                            DiscoverFeatureCard(
                                icon: "bubble.left.and.text.bubble.right.fill",
                                title: "Save Requests",
                                description: "Ask the community for the best saves on any topic"
                            )
                        }
                        .padding(.horizontal, 16)

                        // MARK: - CTA
                        VStack(spacing: 8) {
                            Text("Follow curators now so your feed is ready when Discover launches.")
                                .font(.dopoBody)
                                .foregroundColor(.dopoTextMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Feature Card Component

struct DiscoverFeatureCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.dopoSurface)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.dopoAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.dopoText)

                Text(description)
                    .font(.dopoBody)
                    .foregroundColor(.dopoTextMuted)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.dopoSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.dopoBorder, lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    DiscoverView()
        .preferredColorScheme(.dark)
}
