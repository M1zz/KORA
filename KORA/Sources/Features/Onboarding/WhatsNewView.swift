//
//  WhatsNewView.swift
//  KORA
//
//  업데이트 뒤 처음 열 때 한 번 뜨는 "새로 생긴 것".
//  - 마지막으로 본 버전을 UserDefaults 에 둔다. 처음 설치한 사람에게는 띄우지 않는다(사용법 안내가 먼저다).
//  - 그 버전에 적어 둔 항목이 없으면 띄우지 않는다. 새 버전마다 `notes` 에 한 줄을 더한다.
//  - 언어 시트 ▸ 새로 생긴 것 에서 다시 볼 수 있다.
//

import SwiftUI

enum KORAWhatsNew {
    static let lastSeenKey = "kora.whatsNew.lastSeenVersion"

    struct Item: Identifiable {
        let symbol: String
        let text: NavLoc
        var id: String { symbol }
    }

    /// 버전별 사용자 기능. 내부 정리·빌드 설정은 적지 않는다.
    static let notes: [String: [Item]] = [
        "1.0.9": [
            Item(symbol: "hand.wave.fill", text: .whatsNew1),
            Item(symbol: "bubble.left.and.text.bubble.right.fill", text: .whatsNew2),
            Item(symbol: "circle.lefthalf.filled", text: .whatsNew3),
        ],
    ]

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    /// 지금 버전에 보여 줄 것이 있으면 그 목록. 없으면 빈 배열.
    static var currentItems: [Item] { notes[currentVersion] ?? [] }

    /// 앱을 열 때 띄울지. 첫 설치(`isFirstLaunch`)는 지금 버전을 본 것으로 적고 띄우지 않는다.
    static func shouldPresent(isFirstLaunch: Bool, defaults: UserDefaults = .standard,
                              version: String = currentVersion,
                              notes: [String: [Item]] = notes) -> Bool {
        let lastSeen = defaults.string(forKey: lastSeenKey)
        if isFirstLaunch && lastSeen == nil {
            defaults.set(version, forKey: lastSeenKey)
            return false
        }
        guard lastSeen != version else { return false }
        guard let items = notes[version], !items.isEmpty else {
            defaults.set(version, forKey: lastSeenKey)
            return false
        }
        return true
    }

    static func markSeen(defaults: UserDefaults = .standard, version: String = currentVersion) {
        defaults.set(version, forKey: lastSeenKey)
    }
}

struct WhatsNewView: View {
    let lang: StationLanguage
    let items: [KORAWhatsNew.Item]

    @Environment(\.dismiss) private var dismiss
    @ScaledMetric(relativeTo: .title2) private var iconWidth: CGFloat = 36

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 14) {
                        Image(systemName: item.symbol)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(KORATheme.accent)
                            .frame(width: iconWidth)
                            .accessibilityHidden(true)
                        Text(item.text.resolved(lang))
                            .font(.body)
                            .foregroundStyle(KORATheme.labelPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle(NavLoc.whatsNewTitle.resolved(lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(NavLoc.done.resolved(lang)) { dismiss() }
                        .accessibilityIdentifier("whatsNew.done")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onDisappear { KORAWhatsNew.markSeen() }
    }
}
