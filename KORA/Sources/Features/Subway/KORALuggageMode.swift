import SwiftUI

/// 캐리어 모드 (KORA Pro). 짐이 많을 때 내릴 역 엘리베이터와 가까운 칸-문을 알려 준다.
///
/// 원본은 공공데이터포털 "서울교통공사_빠른하차정보"(1~8호선)이고
/// `scripts/station-data/build_quick_exits.py` 가 `quick_exits.json` 으로 만든다.
/// 문 번호("4-4")는 승강장 바닥과 스크린도어에 적힌 표시와 같다.
enum QuickExitService {

    struct Hint: Equatable {
        /// 가까운 문 (최대 2개).
        let doors: [String]
        /// true = 엘리베이터, false = 에스컬레이터.
        let elevator: Bool
        /// 내릴 역.
        let station: String
    }

    /// "역|노선" → 진행 방향 다음 역 → "e"(엘리베이터)/"s"(에스컬레이터) → 문 번호들
    private static let table: [String: [String: [String: [String]]]] = {
        guard let url = Bundle.main.url(forResource: "quick_exits", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [String: [String: [String]]]].self, from: data)
        else {
            assertionFailure("quick_exits.json 을 읽지 못했다")
            return [:]
        }
        return decoded
    }()

    /// 이 구간 내릴 역에서 엘리베이터(없으면 에스컬레이터)와 가까운 문. 데이터가 없으면 nil.
    static func hint(for seg: JourneySegment) -> Hint? {
        guard let alight = seg.stations.last, let toward = nextStation(after: seg),
              let kinds = table["\(alight)|\(seg.line.number)"]?[toward] else { return nil }
        if let doors = kinds["e"], !doors.isEmpty {
            return Hint(doors: Array(doors.prefix(2)), elevator: true, station: alight)
        }
        if let doors = kinds["s"], !doors.isEmpty {
            return Hint(doors: Array(doors.prefix(2)), elevator: false, station: alight)
        }
        return nil
    }

    /// 원본은 방향을 "그 방향의 다음 역"으로 적는다. 내릴 역 다음 역을 노선에서 찾는다.
    private static func nextStation(after seg: JourneySegment) -> String? {
        guard seg.stations.count >= 2 else { return nil }
        let alight = seg.stations[seg.stations.count - 1]
        let previous = seg.stations[seg.stations.count - 2]
        for route in seg.line.routes {
            let st = route.stations
            guard let ia = st.firstIndex(of: alight), let ip = st.firstIndex(of: previous) else { continue }
            if route.isCircular {
                let n = st.count
                if (ia - ip + n) % n == 1 { return st[(ia + 1) % n] }
                if (ip - ia + n) % n == 1 { return st[(ia - 1 + n) % n] }
            } else if abs(ia - ip) == 1 {
                let next = ia + (ia - ip)
                if st.indices.contains(next) { return st[next] }
            }
        }
        return nil
    }
}

/// 경로 확인 화면의 캐리어 모드 켜고 끄기. 잠겨 있으면 결제 화면을 연다.
struct LuggageModeRow: View {
    let lang: StationLanguage
    let unlocked: Bool
    let onLocked: () -> Void

    @AppStorage("kora.luggage_mode") private var luggageMode = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "suitcase.rolling.fill")
                .font(.body).fontWeight(.semibold)
                .foregroundStyle(KORATheme.accent)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(NavLoc.luggageMode.resolved(lang))
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(KORATheme.labelPrimary)
                Text(NavLoc.luggageModeHint.resolved(lang))
                    .font(.caption)
                    .foregroundStyle(KORATheme.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            if unlocked {
                Toggle("", isOn: $luggageMode)
                    .labelsHidden()
                    .tint(KORATheme.accent)
            } else {
                Button(action: onLocked) {
                    Label("Pro", systemImage: "lock.fill")
                        .font(.caption).fontWeight(.bold)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(KORATheme.accent.opacity(0.15), in: Capsule())
                        .foregroundStyle(KORATheme.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(KORATheme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: KORATheme.radiusMD))
        .accessibilityElement(children: .combine)
    }
}

/// 탑승 전 화면의 캐리어 모드 안내: "4-4 표시 앞에서 타세요".
struct LuggageHintCard: View {
    let seg: JourneySegment
    let lang: StationLanguage
    let unlocked: Bool

    @AppStorage("kora.luggage_mode") private var luggageMode = false

    var body: some View {
        if luggageMode, unlocked, let hint = QuickExitService.hint(for: seg) {
            let station = MetroLineData.displayName(for: hint.station, language: lang)
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: hint.elevator ? "suitcase.rolling.fill" : "arrow.up.right.circle.fill")
                    .font(.title3).fontWeight(.semibold)
                    .foregroundStyle(seg.line.color)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(NavLoc.luggageBoardAt.fill(lang, hint.doors.joined(separator: " / ")))
                        .font(.headline)
                        .foregroundStyle(KORATheme.labelPrimary)
                    Text((hint.elevator ? NavLoc.luggageElevatorNear : NavLoc.luggageEscalatorNear).fill(lang, station))
                        .font(.subheadline)
                        .foregroundStyle(KORATheme.labelPrimary)
                    Text(NavLoc.luggageFloorSign.resolved(lang))
                        .font(.caption)
                        .foregroundStyle(KORATheme.labelSecondary)
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(seg.line.color.opacity(0.12), in: RoundedRectangle(cornerRadius: KORATheme.radiusMD))
            .accessibilityElement(children: .combine)
        }
    }
}
