import SwiftUI

// MARK: - KORA Design System

enum KORATheme {

    // MARK: Colors
    static let accent        = Color("KORAAccent")       // #D85A30 코랄 레드
    static let accentLight   = Color("KORAAccentLight")  // #FAECE7
    static let accentDark    = Color("KORAAccentDark")   // #993C1D

    static let surface       = Color(UIColor.secondarySystemBackground)
    static let background    = Color(UIColor.systemBackground)
    static let separator     = Color(UIColor.separator)

    static let labelPrimary     = Color(UIColor.label)
    static let labelSecondary   = Color(UIColor.secondaryLabel)
    static let labelTertiary    = Color(UIColor.tertiaryLabel)

    // MARK: Category Colors
    static func categoryColor(_ category: PlaceCategory) -> Color {
        switch category {
        case .restaurant:   return Color(hex: "#1D9E75")
        case .cafe:         return Color(hex: "#534AB7")
        case .shopping:     return Color(hex: "#D85A30")
        case .attraction:   return Color(hex: "#185FA5")
        case .entertainment: return Color(hex: "#BA7517")
        case .beauty:       return Color(hex: "#993556")
        }
    }

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
    /// Keeps a label on one line by scaling the font down to `minScale` (default 65%)
    /// before falling back to truncation. Use for station names, direction labels,
    /// and any other text that should stay single-line but can flex smaller.
    func autoFitLine(minScale: CGFloat = 0.65) -> some View {
        self
            .lineLimit(1)
            .minimumScaleFactor(minScale)
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
