import SwiftUI

// MARK: - KORA Design System

enum KORATheme {

    // MARK: Colors
    static let accent        = Color("KORAAccent")       // #CD2E3A 태극 빨강 (아이콘 바탕과 같다)
    static let accentLight   = Color("KORAAccentLight")  // #FBE8EA
    static let accentDark    = Color("KORAAccentDark")   // #9E1C28
    /// 작은 글자용 빨강 — 흰 바탕 · 검은 바탕 모두 4.5:1 이상 (고대비에서는 더 진하게).
    static let accentText    = Color("KORAAccentText")

    static let surface       = Color(UIColor.secondarySystemBackground)
    static let background    = Color(UIColor.systemBackground)
    static let separator     = Color(UIColor.separator)

    static let labelPrimary     = Color(UIColor.label)
    static let labelSecondary   = Color(UIColor.secondaryLabel)
    static let labelTertiary    = Color(UIColor.tertiaryLabel)
    /// 첫 화면의 안내 문구처럼 꼭 읽혀야 하는 보조 글자 — 시스템 보조색(약 3.4:1)보다 진하게(4.5:1 이상).
    static let labelGuide       = Color(UIColor.label).opacity(0.72)

    // MARK: Typography
    static func displayFont(size: CGFloat = 28) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func titleFont(size: CGFloat = 17) -> Font {
        .system(size: size, weight: .semibold)
    }

    static func bodyFont(size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular)
    }

    static func captionFont(size: CGFloat = 12) -> Font {
        .system(size: size, weight: .regular)
    }

    // MARK: Spacing
    static let spacing4:  CGFloat = 4
    static let spacing8:  CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24

    // MARK: Corner Radius
    static let radiusSM: CGFloat = 8
    static let radiusMD: CGFloat = 12
    static let radiusLG: CGFloat = 16
    static let radiusXL: CGFloat = 20
}

// MARK: - Auto-fit line modifier

extension View {
    /// Keeps a label on one line: first tightens letter spacing, then scales the font
    /// down to `minScale` (default 65%), and only then truncates — in the middle, so
    /// both the start and the end of a long station name stay readable
    /// ("Dongdaemun History & C…Park" → "Dongdaemun…Culture Park").
    /// Use for station names, direction labels, and any other single-line text.
    func autoFitLine(minScale: CGFloat = 0.65) -> some View {
        self
            .lineLimit(1)
            .allowsTightening(true)
            .minimumScaleFactor(minScale)
            .truncationMode(.middle)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b)  / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Fixed URLs

extension URL {
    /// A URL written in the source (support page, mail address). It's fixed at
    /// build time, so a typo is a programmer error caught on first run — not a
    /// runtime condition to handle.
    init(fixed string: StaticString) {
        guard let url = URL(string: "\(string)") else {
            preconditionFailure("Invalid fixed URL: \(string)")
        }
        self = url
    }
}
