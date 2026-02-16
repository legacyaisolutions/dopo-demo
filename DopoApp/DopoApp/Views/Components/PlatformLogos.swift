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

// MARK: - TikTok (Musical note with 3-color offset)
struct TikTokLogo: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(.black)
                .frame(width: size, height: size)

            // Three overlapping layers: cyan, red, white (center)
            Canvas { context, canvasSize in
                let s = canvasSize.width

                func drawNote(ctx: inout GraphicsContext, color: Color, dx: CGFloat, dy: CGFloat) {
                    // Stem (vertical bar, right side)
                    let stemW = s * 0.13
                    let stemH = s * 0.48
                    let stemX = s * 0.52 + dx
                    let stemY = s * 0.16 + dy
                    let stemRect = CGRect(x: stemX, y: stemY, width: stemW, height: stemH)
                    ctx.fill(Path(roundedRect: stemRect, cornerRadius: stemW * 0.2), with: .color(color))

                    // Note head (ellipse at bottom-left of stem)
                    let headW = s * 0.26
                    let headH = s * 0.19
                    let headX = stemX - headW * 0.55
                    let headY = stemY + stemH - headH * 0.45
                    ctx.fill(Path(ellipseIn: CGRect(x: headX, y: headY, width: headW, height: headH)), with: .color(color))

                    // Wave/flag at top (curved piece going right from top of stem)
                    var wave = Path()
                    let waveTop = stemY
                    wave.move(to: CGPoint(x: stemX + stemW, y: waveTop))
                    wave.addQuadCurve(
                        to: CGPoint(x: s * 0.72 + dx, y: waveTop + s * 0.12),
                        control: CGPoint(x: s * 0.72 + dx, y: waveTop - s * 0.02)
                    )
                    wave.addLine(to: CGPoint(x: s * 0.72 + dx, y: waveTop + s * 0.22))
                    wave.addQuadCurve(
                        to: CGPoint(x: stemX + stemW, y: waveTop + s * 0.12),
                        control: CGPoint(x: s * 0.62 + dx, y: waveTop + s * 0.16)
                    )
                    wave.closeSubpath()
                    ctx.fill(wave, with: .color(color))
                }

                // Cyan layer (offset up-right)
                drawNote(ctx: &context, color: Color(red: 0.14, green: 0.89, blue: 0.82), dx: 1.2, dy: -1.2)
                // Red layer (offset down-left)
                drawNote(ctx: &context, color: Color(red: 0.99, green: 0.18, blue: 0.33), dx: -1.2, dy: 1.2)
                // White center layer
                drawNote(ctx: &context, color: .white, dx: 0, dy: 0)
            }
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
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

// MARK: - Facebook (Bold "f" path on blue circle)
struct FacebookLogo: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.09, green: 0.47, blue: 0.95))
                .frame(width: size, height: size)

            // Draw the Facebook "f" as a Canvas path for precise control
            Canvas { context, canvasSize in
                let s = canvasSize.width

                // The Facebook "f" is: vertical bar + horizontal crossbar + curved top
                let barW = s * 0.18  // width of the vertical stroke
                let barL = s * 0.38  // left edge of vertical bar (slightly right of center)
                let barR = barL + barW

                // Vertical bar — runs from middle area down to bottom
                let vTop = s * 0.28
                let vBot = s * 0.82
                var vBar = Path()
                vBar.addRect(CGRect(x: barL, y: vTop, width: barW, height: vBot - vTop))
                context.fill(vBar, with: .color(.white))

                // Horizontal crossbar
                let crossY = s * 0.46
                let crossH = barW * 0.75
                let crossL = s * 0.22
                let crossR = s * 0.68
                var cross = Path()
                cross.addRect(CGRect(x: crossL, y: crossY, width: crossR - crossL, height: crossH))
                context.fill(cross, with: .color(.white))

                // Curved top of the "f" (curves right from top of vertical bar)
                var curve = Path()
                curve.move(to: CGPoint(x: barL, y: vTop + barW * 0.3))
                curve.addQuadCurve(
                    to: CGPoint(x: s * 0.65, y: s * 0.14),
                    control: CGPoint(x: barL, y: s * 0.13)
                )
                curve.addLine(to: CGPoint(x: s * 0.65, y: s * 0.14 + crossH))
                curve.addQuadCurve(
                    to: CGPoint(x: barR, y: vTop + barW * 0.3),
                    control: CGPoint(x: barR, y: s * 0.16)
                )
                curve.closeSubpath()
                context.fill(curve, with: .color(.white))
            }
            .frame(width: size, height: size)
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
