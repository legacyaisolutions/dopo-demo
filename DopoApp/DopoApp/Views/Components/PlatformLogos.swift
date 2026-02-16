import SwiftUI

// MARK: - Platform Logo View
// Renders recognizable brand-style logos for each platform using SwiftUI paths

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

    var body: some View {
        switch platform {
        case .youtube:
            YouTubeLogo(size: size)
        case .instagram:
            InstagramLogo(size: size)
        case .tiktok:
            TikTokLogo(size: size)
        case .twitter:
            XLogo(size: size)
        case .facebook:
            FacebookLogo(size: size)
        case .other:
            Image(systemName: "link")
                .font(.system(size: size * 0.6, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - YouTube (Red rounded rect with white play triangle)
struct YouTubeLogo: View {
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let s = canvasSize.width
            let rectH = s * 0.72
            let rectW = s
            let rectY = (s - rectH) / 2
            let cornerR = rectH * 0.28

            // Red rounded rectangle background
            let rectPath = Path(roundedRect: CGRect(x: 0, y: rectY, width: rectW, height: rectH), cornerRadius: cornerR)
            context.fill(rectPath, with: .color(Color(red: 1.0, green: 0.0, blue: 0.0)))

            // White play triangle — centered in the rect
            let triW = s * 0.32
            let triH = s * 0.36
            let triX = (s - triW) / 2 + triW * 0.08 // nudge right slightly since triangle visual center is left of geometric center
            let triY = (s - triH) / 2
            var tri = Path()
            tri.move(to: CGPoint(x: triX, y: triY))
            tri.addLine(to: CGPoint(x: triX + triW, y: triY + triH / 2))
            tri.addLine(to: CGPoint(x: triX, y: triY + triH))
            tri.closeSubpath()
            context.fill(tri, with: .color(.white))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Instagram (Camera outline with gradient)
struct InstagramLogo: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Gradient background
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.51, green: 0.23, blue: 0.72), // purple
                            Color(red: 0.88, green: 0.19, blue: 0.42), // pink
                            Color(red: 0.99, green: 0.44, blue: 0.09), // orange
                            Color(red: 0.99, green: 0.76, blue: 0.18), // yellow
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )
                .frame(width: size, height: size)

            // Inner rounded rect border
            RoundedRectangle(cornerRadius: size * 0.18)
                .stroke(.white, lineWidth: size * 0.08)
                .frame(width: size * 0.65, height: size * 0.65)

            // Center circle (lens)
            Circle()
                .stroke(.white, lineWidth: size * 0.08)
                .frame(width: size * 0.3, height: size * 0.3)

            // Small dot (flash)
            Circle()
                .fill(.white)
                .frame(width: size * 0.09, height: size * 0.09)
                .offset(x: size * 0.17, y: -size * 0.17)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - TikTok (Music note "d" shape)
struct TikTokLogo: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(.black)
                .frame(width: size, height: size)

            // Offset colored layers for the 3D effect
            TikTokNoteShape()
                .fill(Color(red: 0.14, green: 0.89, blue: 0.82)) // cyan
                .frame(width: size * 0.5, height: size * 0.65)
                .offset(x: 1, y: -1)

            TikTokNoteShape()
                .fill(Color(red: 0.99, green: 0.18, blue: 0.33)) // red
                .frame(width: size * 0.5, height: size * 0.65)
                .offset(x: -1, y: 1)

            TikTokNoteShape()
                .fill(.white)
                .frame(width: size * 0.5, height: size * 0.65)
        }
        .frame(width: size, height: size)
    }
}

struct TikTokNoteShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Musical note "d" shape
        // Stem
        let stemX = w * 0.6
        let stemTop = h * 0.0
        let stemBottom = h * 0.72
        let stemWidth = w * 0.18

        path.addRoundedRect(
            in: CGRect(x: stemX, y: stemTop, width: stemWidth, height: stemBottom),
            cornerSize: CGSize(width: stemWidth * 0.3, height: stemWidth * 0.3)
        )

        // Note head (circle at bottom-left of stem)
        let noteR = w * 0.22
        let noteX = stemX - noteR * 0.5
        let noteY = stemBottom - noteR * 0.3
        path.addEllipse(in: CGRect(x: noteX - noteR, y: noteY, width: noteR * 2, height: noteR * 1.6))

        // Curved top (the flag)
        path.move(to: CGPoint(x: stemX + stemWidth, y: stemTop + h * 0.05))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.95, y: stemTop + h * 0.18),
            control: CGPoint(x: w * 0.95, y: stemTop)
        )
        path.addLine(to: CGPoint(x: w * 0.95, y: stemTop + h * 0.3))
        path.addQuadCurve(
            to: CGPoint(x: stemX + stemWidth, y: stemTop + h * 0.17),
            control: CGPoint(x: w * 0.78, y: stemTop + h * 0.22)
        )
        path.closeSubpath()

        return path
    }
}

// MARK: - X / Twitter (Stylized X on black circle)
struct XLogo: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(.black)
                .frame(width: size, height: size)

            Canvas { context, canvasSize in
                let s = canvasSize.width
                let pad = s * 0.24
                let top = pad
                let bot = s - pad
                let left = pad
                let right = s - pad

                // The X/Twitter logo is two crossing strokes with specific widths
                // Top-left to bottom-right (thicker stroke)
                var stroke1 = Path()
                stroke1.move(to: CGPoint(x: left, y: top))
                stroke1.addLine(to: CGPoint(x: left + s * 0.14, y: top))
                stroke1.addLine(to: CGPoint(x: right, y: bot))
                stroke1.addLine(to: CGPoint(x: right - s * 0.14, y: bot))
                stroke1.closeSubpath()
                context.fill(stroke1, with: .color(.white))

                // Top-right to bottom-left (thinner stroke)
                var stroke2 = Path()
                stroke2.move(to: CGPoint(x: right, y: top))
                stroke2.addLine(to: CGPoint(x: right, y: top + s * 0.10))
                stroke2.addLine(to: CGPoint(x: left, y: bot))
                stroke2.addLine(to: CGPoint(x: left, y: bot - s * 0.10))
                stroke2.closeSubpath()
                context.fill(stroke2, with: .color(.white))
            }
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Facebook (F letterform)
struct FacebookLogo: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.09, green: 0.47, blue: 0.95))
                .frame(width: size, height: size)

            // "f" letter
            Text("f")
                .font(.system(size: size * 0.6, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .offset(x: size * 0.02, y: size * 0.03)
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
