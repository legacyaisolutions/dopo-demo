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
                RoundedRectangle(cornerRadius: size * 0.13)
                    .fill(Color(red: 1.0, green: 0.404, blue: 0.098))
                    .frame(width: size, height: size)
                SubstackMark(size: size)
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

// MARK: - Substack brand mark (two bars + bookmark bottom)

private struct SubstackMark: View {
    let size: CGFloat

    var body: some View {
        let pad = size * 0.165
        let barH = size * 0.115
        let bar1Y = size * 0.155
        let bar2Y = size * 0.345
        let bar3Y = size * 0.530
        let pointY = size * 0.835

        Canvas { ctx, _ in
            let bar1 = CGRect(x: pad, y: bar1Y, width: size - pad * 2, height: barH)
            let bar2 = CGRect(x: pad, y: bar2Y, width: size - pad * 2, height: barH)
            var bookmark = Path()
            bookmark.move(to: CGPoint(x: pad, y: bar3Y))
            bookmark.addLine(to: CGPoint(x: size - pad, y: bar3Y))
            bookmark.addLine(to: CGPoint(x: size - pad, y: pointY))
            bookmark.addLine(to: CGPoint(x: size / 2, y: pointY - size * 0.12))
            bookmark.addLine(to: CGPoint(x: pad, y: pointY))
            bookmark.closeSubpath()
            ctx.fill(Path(bar1), with: .color(.white))
            ctx.fill(Path(bar2), with: .color(.white))
            ctx.fill(bookmark, with: .color(.white))
        }
        .frame(width: size, height: size)
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
