import SwiftUI

/// 출구 안내 (KORA Pro). 역마다 출구 번호와 그 출구 가까운 장소를 보여 준다.
///
/// 원본은 서울교통공사 "역별 역세권 현황"(1~8호선, 9호선 2·3단계)이고
/// `scripts/station-data/build_exits.py` 가 `station_exits.json` 으로 만든다.
/// 장소 이름은 역 안 출구 표지판에 적힌 한글 그대로다 — 번역하지 않아야 표지판과 맞춰 볼 수 있다.
struct StationExit: Identifiable, Hashable {
    let number: String
    let places: [String]
    var id: String { number }
}

enum StationExitGuide {
    private static let table: [String: [StationExit]] = {
        guard let url = Bundle.main.url(forResource: "station_exits", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode([String: [[ExitRow]]].self, from: data)
        else {
            assertionFailure("station_exits.json 을 읽지 못했다")
            return [:]
        }
        return raw.mapValues { rows in
            rows.compactMap { row in
                guard case .number(let no) = row.first, case .places(let places) = row.last else { return nil }
                return StationExit(number: no, places: places)
            }
        }
    }()

    /// JSON 한 줄 `["3", ["장소", …]]` 의 두 칸.
    private enum ExitRow: Decodable {
        case number(String)
        case places([String])

        init(from decoder: Decoder) throws {
            let c = try decoder.singleValueContainer()
            if let s = try? c.decode(String.self) { self = .number(s) } else { self = .places(try c.decode([String].self)) }
        }
    }

    /// 출구 정보가 없는 역(서울교통공사 밖 노선, 지방 노선)은 빈 배열.
    static func exits(for stationKo: String) -> [StationExit] {
        table[stationKo] ?? []
    }
}

/// 경로 확인 화면과 도착 화면에 들어가는 "출구 안내" 버튼.
/// 잠겨 있으면 결제 화면을 연다(`onLocked`). 출구 정보가 없는 역에서는 아무것도 그리지 않는다.
struct ExitGuideButton: View {
    let stationKo: String
    let lang: StationLanguage
    let unlocked: Bool
    let tint: Color
    let onLocked: () -> Void

    @State private var showGuide = false

    var body: some View {
        if !StationExitGuide.exits(for: stationKo).isEmpty {
            Button {
                if unlocked { showGuide = true } else { onLocked() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "door.right.hand.open")
                        .font(.body).fontWeight(.semibold)
                    Text(NavLoc.exitGuide.resolved(lang))
                        .font(.body).fontWeight(.semibold)
                    Spacer(minLength: 4)
                    if unlocked {
                        Image(systemName: "chevron.right")
                            .font(.footnote).fontWeight(.bold)
                    } else {
                        Label("Pro", systemImage: "lock.fill")
                            .font(.caption).fontWeight(.bold)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(tint.opacity(0.15), in: Capsule())
                    }
                }
                .foregroundStyle(tint)
                .padding(.horizontal, 16).padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: KORATheme.radiusMD))
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showGuide) {
                ExitGuideSheet(stationKo: stationKo, lang: lang)
            }
        }
    }
}

struct ExitGuideSheet: View {
    let stationKo: String
    let lang: StationLanguage

    @Environment(\.dismiss) private var dismiss

    private var exits: [StationExit] { StationExitGuide.exits(for: stationKo) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(NavLoc.exitGuide.resolved(lang))
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundStyle(KORATheme.accent)
                    Text(MetroLineData.displayBilingual(for: stationKo, language: lang))
                        .font(.title2).fontWeight(.black)
                        .foregroundStyle(KORATheme.labelPrimary)
                    Text(NavLoc.exitGuideNote.resolved(lang))
                        .font(.footnote)
                        .foregroundStyle(KORATheme.labelSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 0) {
                    ForEach(exits) { exit in
                        exitRow(exit)
                        if exit != exits.last { Divider().padding(.leading, 64) }
                    }
                }
                .background(KORATheme.surface, in: RoundedRectangle(cornerRadius: KORATheme.radiusLG))
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 24)
            .frame(maxWidth: 560)
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
            .accessibilityLabel(NavLoc.done.resolved(lang))
            .accessibilityInputLabels([Text(NavLoc.done.resolved(lang))])
        }
        .presentationDragIndicator(.visible)
    }

    private func exitRow(_ exit: StationExit) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // 서울 지하철 출구 표지판처럼 노란 바탕에 검은 번호.
            Text(exit.number)
                .font(.system(.headline, design: .rounded)).fontWeight(.heavy)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(.black)
                .frame(width: 34, height: 34)
                .background(Color(red: 1.0, green: 0.80, blue: 0.0), in: RoundedRectangle(cornerRadius: 7))
                .accessibilityHidden(true)
            Text(exit.places.joined(separator: " · "))
                .font(.body)
                .foregroundStyle(KORATheme.labelPrimary)
                // 길게 눌러 복사 — 지도 앱에 장소 이름을 붙여 넣을 때.
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(NavLoc.exitNumber.fill(lang, exit.number) + ", " + exit.places.joined(separator: ", "))
    }
}
