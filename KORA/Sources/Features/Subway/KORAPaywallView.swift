import SwiftUI
import StoreKit
import LeeoKit

/// KORA Pro 결제 화면. LeeoKit 의 표준 `LeeoPaywallView` 대신 쓰는 이유:
///  1. 문구가 앱 안 언어 선택(`StationLanguage`)을 따라야 한다. 표준 화면은 휴대폰 언어를
///     따르므로 이 화면만 다른 언어로 나온다.
///  2. 결제 시트를 띄울 창을 StoreKit 이 짐작하지 않게 `@Environment(\.purchase)` 로 산다.
///     짐작에 맡기면 아이패드에서 결제가 오류로 끝난다 (심사 2.1(b) 거절 사유).
/// 상품 로드·구매·복원·권한은 `KORAPro.shared.store`(LeeoStore)가 한다.
struct KORAPaywallView: View {
    let lang: StationLanguage
    /// 분석용: 어디서 열렸는지 ("arrival", "basic_ride", "exit_guide", "settings").
    let reason: String

    @ObservedObject private var pro = KORAPro.shared
    @Environment(\.purchase) private var purchaseAction
    @Environment(\.dismiss) private var dismiss

    private var store: LeeoStore { pro.store }
    private var product: Product? { store.products.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                header
                benefits
                purchaseSection
                footer
            }
            .padding(.horizontal, 24)
            .padding(.top, 44)
            .padding(.bottom, 24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(KORATheme.background.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(KORATheme.labelTertiary)
                    .padding(16)
            }
            .accessibilityLabel(NavLoc.proNotNow.resolved(lang))
        }
        .task {
            LeeoAnalyticsCenter.track(.paywallShown(reason: reason))
            await store.loadProducts()
        }
        .onChange(of: pro.hasPro) { _, hasPro in
            if hasPro { dismiss() }
        }
    }

    // MARK: - 섹션

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 44))
                .foregroundStyle(KORATheme.accent)
            Text(NavLoc.proTitle.resolved(lang))
                .font(.subheadline).fontWeight(.bold)
                .foregroundStyle(KORATheme.accent)
            Text(NavLoc.proHeadline.resolved(lang))
                .font(.title).fontWeight(.black)
                .multilineTextAlignment(.center)
                .foregroundStyle(KORATheme.labelPrimary)
            // "KORA Pro" 가 두 줄로 갈라지지 않게 (띄어쓰기 없는 일본어·중국어에서 특히).
            Text(NavLoc.proSubtitle.resolved(lang).replacingOccurrences(of: "KORA Pro", with: "KORA\u{00A0}Pro"))
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(KORATheme.labelSecondary)
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 16) {
            benefitRow("lock.iphone", NavLoc.proBenefitLockScreen)
            benefitRow("waveform.and.mic", NavLoc.proBenefitAnnouncement)
            benefitRow("iphone.radiowaves.left.and.right", NavLoc.proBenefitAlight)
            benefitRow("door.right.hand.open", NavLoc.proBenefitExitGuide)
            benefitRow("infinity", NavLoc.proBenefitOneTime)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(KORATheme.surface, in: RoundedRectangle(cornerRadius: KORATheme.radiusLG))
    }

    private func benefitRow(_ icon: String, _ text: NavLoc) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .font(.body).fontWeight(.semibold)
                .foregroundStyle(KORATheme.accent)
                .frame(width: 26)
            Text(text.resolved(lang))
                .font(.body)
                .foregroundStyle(KORATheme.labelPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var purchaseSection: some View {
        if let product {
            VStack(spacing: 10) {
                Button {
                    Task { await store.purchase(product) { try await purchaseAction($0) } }
                } label: {
                    Group {
                        if store.purchasingProductID != nil {
                            ProgressView().tint(.white)
                        } else {
                            Text(NavLoc.proUnlockPrice.fill(lang, product.displayPrice))
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(KORATheme.accent, in: RoundedRectangle(cornerRadius: KORATheme.radiusLG))
                    .foregroundStyle(.white)
                }
                .disabled(store.purchasingProductID != nil)

                Text(NavLoc.proBilling.resolved(lang))
                    .font(.caption)
                    .foregroundStyle(KORATheme.labelSecondary)

                if let error = store.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
        } else if store.isLoadingProducts {
            ProgressView()
                .tint(KORATheme.accent)
                .padding(.vertical, 24)
        } else {
            VStack(spacing: 12) {
                Text(NavLoc.proLoadFailed.resolved(lang))
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(KORATheme.labelSecondary)
                Button(NavLoc.proRetry.resolved(lang)) {
                    Task { await store.loadProducts() }
                }
                .tint(KORATheme.accent)
            }
            .padding(.vertical, 12)
        }
    }

    private var footer: some View {
        VStack(spacing: 14) {
            Button(NavLoc.proNotNow.resolved(lang)) { dismiss() }
                .font(.body).fontWeight(.semibold)
                .tint(KORATheme.labelSecondary)

            Button {
                Task { await store.restore() }
            } label: {
                if store.isRestoring {
                    ProgressView()
                } else {
                    Text(NavLoc.proRestore.resolved(lang))
                }
            }
            .disabled(store.isRestoring)
            .font(.footnote)
            .tint(KORATheme.labelSecondary)
        }
    }
}

/// 언어 선택 시트 안의 Pro 줄 — 결제 화면을 스스로 열거나, 산 사람에게 고맙다고 말하는 곳.
/// 심사에서 요구하는 "구매 복원" 경로도 여기서 늘 닿는다.
struct KORAProSection: View {
    let lang: StationLanguage

    @ObservedObject private var pro = KORAPro.shared
    @State private var showPaywall = false

    var body: some View {
        Section {
            if pro.hasPro {
                Label(NavLoc.proActive.resolved(lang), systemImage: "checkmark.seal.fill")
                    .foregroundStyle(KORATheme.accent)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label(NavLoc.proGet.resolved(lang), systemImage: "bell.badge.fill")
                }
                .foregroundStyle(KORATheme.accent)
            }
        } header: {
            Text(NavLoc.proTitle.resolved(lang))
        } footer: {
            if let left = pro.freeRidesLeft, left == 0 {
                Text(NavLoc.proUsedUp.resolved(lang))
            } else if pro.freeRidesLeft == 1 {
                Text(NavLoc.proLastFreeRide.resolved(lang))
            }
        }
        .sheet(isPresented: $showPaywall) {
            KORAPaywallView(lang: lang, reason: "settings")
        }
    }
}
