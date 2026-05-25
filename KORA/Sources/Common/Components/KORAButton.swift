import SwiftUI

// MARK: - Primary Button

struct KORAPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(LocalizedStringKey(title))
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(KORATheme.accent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusMD))
        }
    }
}

// MARK: - Secondary Button

struct KORASecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                }
                Text(LocalizedStringKey(title))
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(KORATheme.accentLight)
            .foregroundStyle(KORATheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: KORATheme.radiusMD)
                    .strokeBorder(KORATheme.accent.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Tag Chip

struct KORATagChip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(LocalizedStringKey(text))
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Rating Stars

struct KORARatingView: View {
    let rating: Double
    let size: CGFloat

    init(rating: Double, size: CGFloat = 14) {
        self.rating = rating
        self.size = size
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: starImageName(for: index))
                    .font(.system(size: size))
                    .foregroundStyle(Color(hex: "#EF9F27"))
            }
            Text(String(format: "%.1f", rating))
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(KORATheme.labelPrimary)
        }
    }

    private func starImageName(for index: Int) -> String {
        let threshold = Double(index)
        if rating >= threshold {
            return "star.fill"
        } else if rating >= threshold - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        KORAPrimaryButton("インスタURLを貼り付ける", icon: "link") {}
        KORASecondaryButton("プランを最適化する", icon: "map") {}
        HStack {
            KORATagChip(text: "カフェ", color: Color(hex: "#534AB7"))
            KORATagChip(text: "写真映え", color: KORATheme.accent)
            KORATagChip(text: "並び必須", color: Color(hex: "#BA7517"))
        }
        KORARatingView(rating: 4.5)
    }
    .padding()
}
