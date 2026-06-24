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
        case .substack:  return nil
        case .web:       return nil
        }
    }

    var body: some View {
        if platform == .substack {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.22)
                    .fill(Color(red: 1.0, green: 0.40, blue: 0.098))
                    .frame(width: size, height: size)
                Text("S")
                    .font(.system(size: size * 0.65, weight: .black, design: .serif))
                    .foregroundColor(.white)
            }
        } else if let assetName {
            Image(assetName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            Image(systemName: "globe")
                .font(.system(size: size * 0.7, weight: .medium))
                .foregroundColor(.dopoAccent)
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
