import SwiftUI

// MARK: - Platform Logo View
// Uses SVG assets from the asset catalog for crisp, brand-accurate logos at any size

struct PlatformLogo: View {
    let platform: PlatformTheme
    let size: CGFloat

    init(_ platform: PlatformTheme, size: CGFloat = 20) {
        self.platform = platform
        self.size = size
    }

    init(_ platformString: String, size: CGFloat = 20) {
        self.platform = PlatformTheme.from(platformString)
        self.size = size
    }

    private var assetName: String? {
        switch platform {
        case .youtube:   return "PlatformLogos/youtube-logo"
        case .instagram: return "PlatformLogos/instagram-logo"
        case .tiktok:    return "PlatformLogos/tiktok-logo"
        case .twitter:   return "PlatformLogos/x-logo"
        case .facebook:  return "PlatformLogos/facebook-logo"
        case .other:     return nil
        }
    }

    var body: some View {
        if let assetName {
            Image(assetName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            // Fallback for unknown platforms
            Image(systemName: "link")
                .font(.system(size: size * 0.6, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Platform Logo with Glow (for use on dark thumbnails)
struct PlatformLogoOverlay: View {
    let platform: PlatformTheme
    let size: CGFloat

    init(_ platform: PlatformTheme, size: CGFloat = 20) {
        self.platform = platform
        self.size = size
    }

    var body: some View {
        PlatformLogo(platform, size: size)
            .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
    }
}
