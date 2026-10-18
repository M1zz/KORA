//
//  KORAOnboardingView.swift
//  KORA
//
//  처음 연 사람에게 세 장으로 쓰는 법을 보여 준다 — 도착역 고르기 · 타면 밀기 · 언어 바꾸기.
//  다 보거나 건너뛰면 `hasCompletedOnboarding` 이 켜져 다시 뜨지 않는다.
//  언어 시트 ▸ 사용법 다시 보기 로 언제든 다시 볼 수 있다.
//

import SwiftUI
import TipKit

enum KORAOnboarding {
    static let completedKey = "kora.hasCompletedOnboarding"

    /// 앱 `init()` 에서 부트스트랩(실행 횟수 기록) 뒤에 한 번. 이 화면이 생기기 전부터 쓰던 사람에게는
    /// 안내를 띄우지 않는다 — 이미 아는 것을 다시 가르치면 길을 막는 것이다.
    static func markDoneForExistingUsers(launchCount: Int, defaults: UserDefaults = .standard) {
        guard defaults.object(forKey: completedKey) == nil, launchCount > 1 else { return }
        defaults.set(true, forKey: completedKey)
    }
}

extension StationLanguage {
    /// 앱 안에서 고른 언어(언어 시트). 비어 있으면 기기 언어를 따른다 — 화면의 나머지와 같은 규칙.
    static var inAppChoice: StationLanguage {
        let pref = UserDefaults.standard.string(forKey: "kora.display_language") ?? ""
        return StationLanguage(rawValue: pref) ?? StationLanguage.resolveFromSystemLocale()
    }
}

struct KORAOnboardingView: View {
    let lang: StationLanguage
    let onFinish: () -> Void

    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize: CGFloat = 64

    private struct Page {
        let symbol: String
        let title: NavLoc
        let body: NavLoc
    }

    private let pages: [Page] = [
        Page(symbol: "mappin.and.ellipse", title: .onboarding1Title, body: .onboarding1Body),
        Page(symbol: "tram.fill", title: .onboarding2Title, body: .onboarding2Body),
        Page(symbol: "globe", title: .onboarding3Title, body: .onboarding3Body),
    ]

    private var isLastPage: Bool { page == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(NavLoc.onboardingSkip.resolved(lang), action: onFinish)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(KORATheme.accentText)
                    .accessibilityIdentifier("onboarding.skip")
                    .accessibilityInputLabels([Text(NavLoc.onboardingSkip.resolved(lang)), Text(verbatim: "Skip")])
                    .opacity(isLastPage ? 0 : 1)
                    .disabled(isLastPage)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    pageView(pages[i], index: i)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if isLastPage {
                    onFinish()
                } else if reduceMotion {
                    page += 1
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
                }
            } label: {
                Text(isLastPage ? NavLoc.onboardingStart.resolved(lang) : NavLoc.onboardingNext.resolved(lang))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            // 흰 글자가 4.5:1 이상 되도록 진한 코랄.
            .tint(KORATheme.accentDark)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .accessibilityIdentifier("onboarding.next")
        }
        .background(KORATheme.background.ignoresSafeArea())
        .onAppear { LanguageLongPressTip.isOnboardingVisible = true }
        .onDisappear { LanguageLongPressTip.isOnboardingVisible = false }
    }

    private func pageView(_ p: Page, index: Int) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: p.symbol)
                    .font(.system(size: symbolSize, weight: .bold))
                    .foregroundStyle(KORATheme.accent)
                    .symbolEffect(.bounce, value: reduceMotion ? 0 : (page == index ? 1 : 0))
                    .frame(height: symbolSize * 1.4)
                    .accessibilityHidden(true)
                Text(p.title.resolved(lang))
                    .font(.title.weight(.black))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(KORATheme.labelPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(p.body.resolved(lang))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(KORATheme.labelPrimary.opacity(contrast == .increased ? 1 : 0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)
            .padding(.top, 48)
            .padding(.bottom, 56)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    KORAOnboardingView(lang: .english) {}
}
