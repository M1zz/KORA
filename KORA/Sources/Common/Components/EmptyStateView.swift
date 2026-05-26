import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: KORATheme.spacing16) {
            Spacer()

            Image(systemName: systemImage)
                .font(.largeTitle).fontWeight(.thin)
                .foregroundStyle(KORATheme.accent.opacity(0.6))

            VStack(spacing: KORATheme.spacing8) {
                Text(LocalizedStringKey(title))
                    .font(KORATheme.titleFont())
                    .foregroundStyle(KORATheme.labelPrimary)
                    .multilineTextAlignment(.center)

                Text(LocalizedStringKey(subtitle))
                    .font(KORATheme.bodyFont(size: 14))
                    .foregroundStyle(KORATheme.labelSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            if let actionTitle, let action {
                KORAPrimaryButton(actionTitle, action: action)
                    .frame(maxWidth: 240)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    EmptyStateView(
        systemImage: "bookmark",
        title: "まだ保存したスポットがありません",
        subtitle: "InstagramのURLを貼り付けると\n自動でスポット情報が追加されます",
        actionTitle: "URLを貼り付ける",
        action: {}
    )
}
