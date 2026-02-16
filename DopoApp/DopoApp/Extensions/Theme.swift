import SwiftUI

extension Color {
    static let dopoBg = Color(red: 0.04, green: 0.04, blue: 0.06)
    static let dopoSurface = Color(red: 0.08, green: 0.08, blue: 0.12)
    static let dopoSurfaceHover = Color(red: 0.11, green: 0.11, blue: 0.18)
    static let dopoBorder = Color(red: 0.16, green: 0.16, blue: 0.24)
    static let dopoText = Color(red: 0.91, green: 0.91, blue: 0.94)
    static let dopoTextMuted = Color(red: 0.53, green: 0.53, blue: 0.63)
    static let dopoTextDim = Color(red: 0.35, green: 0.35, blue: 0.45)
    static let dopoAccent = Color(red: 1.0, green: 0.42, blue: 0.21)
    static let dopoAccentGlow = Color(red: 1.0, green: 0.42, blue: 0.21).opacity(0.15)
    static let dopoSuccess = Color(red: 0.20, green: 0.83, blue: 0.60)
    static let dopoError = Color(red: 0.97, green: 0.44, blue: 0.44)

    static func platformColor(_ platform: String) -> Color {
        switch platform.lowercased() {
        case "youtube": return Color(red: 1.0, green: 0.0, blue: 0.2)
        case "instagram": return Color(red: 0.88, green: 0.19, blue: 0.42)
        case "tiktok": return Color(red: 0.0, green: 0.95, blue: 0.92)
        case "twitter": return Color(red: 0.11, green: 0.61, blue: 0.94)
        case "facebook": return Color(red: 0.09, green: 0.47, blue: 0.95)
        default: return .dopoTextMuted
        }
    }
}

extension Font {
    static let dopoTitle = Font.custom("SpaceMono-Bold", size: 28)
    static let dopoHeading = Font.system(size: 18, weight: .semibold, design: .default)
    static let dopoBody = Font.system(size: 14, weight: .regular, design: .default)
    static let dopoCaption = Font.system(size: 12, weight: .regular, design: .monospaced)
    static let dopoSmall = Font.system(size: 11, weight: .medium, design: .default)
}
