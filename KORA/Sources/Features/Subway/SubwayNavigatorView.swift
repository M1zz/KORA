import SwiftUI

// MARK: - Navigator View

struct SubwayNavigatorView: View {
    @State private var fromStation: String? = nil
    @State private var toStation: String? = nil
    @State private var showFromPicker = false
    @State private var showToPicker = false
    @State private var selectedJourneyIdx = 0

    private var journeys: [JourneyResult] {
        guard let f = fromStation, let t = toStation else { return [] }
        return MetroLineData.findJourneys(from: f, to: t)
    }
    private var journey: JourneyResult? {
        journeys.indices.contains(selectedJourneyIdx) ? journeys[selectedJourneyIdx] : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            setupBar
            Divider()
            if let j = journey {
                directionCard(j)
                Divider()
                stationList(j)
            } else if fromStation != nil && toStation != nil {
                noRouteView
            } else {
                emptyStateView
            }
        }
        .sheet(isPresented: $showFromPicker) {
            StationSearchSheet(title: "現在地 / 현재 역", excluding: toStation) {
                fromStation = $0
                selectedJourneyIdx = 0
            }
        }
        .sheet(isPresented: $showToPicker) {
            StationSearchSheet(title: "目的地 / 목적지", excluding: fromStation) {
                toStation = $0
                selectedJourneyIdx = 0
            }
        }
    }

    // MARK: Setup bar

    private var setupBar: some View {
        HStack(spacing: 8) {
            stationPill(
                jaName: fromStation.map { MetroLineData.displayName(for: $0, language: .japanese) },
                koName: fromStation,
                placeholder: "現在地を選ぶ",
                isSet: fromStation != nil,
                action: { showFromPicker = true }
            )

            Button {
                let tmp = fromStation
                fromStation = toStation
                toStation = tmp
                selectedJourneyIdx = 0
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(KORATheme.accent)
                    .frame(width: 34, height: 34)
                    .background(KORATheme.accent.opacity(0.1))
                    .clipShape(Circle())
            }
            .disabled(fromStation == nil && toStation == nil)

            stationPill(
                jaName: toStation.map { MetroLineData.displayName(for: $0, language: .japanese) },
                koName: toStation,
                placeholder: "目的地を選ぶ",
                isSet: toStation != nil,
                action: { showToPicker = true }
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private func stationPill(
        jaName: String?,
        koName: String?,
        placeholder: String,
        isSet: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(jaName ?? placeholder)
                    .font(.system(size: 14, weight: isSet ? .semibold : .regular))
                    .foregroundStyle(isSet ? KORATheme.labelPrimary : KORATheme.labelSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if let ko = koName {
                    Text(ko)
                        .font(.system(size: 11))
                        .foregroundStyle(KORATheme.labelSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: Direction card

    private func directionCard(_ j: JourneyResult) -> some View {
        let terminusJa = MetroLineData.displayName(for: j.terminus, language: .japanese)
        let stopCount = j.stations.count - 1
        let nextKo = stopCount > 1 ? j.stations[1] : nil

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Line number badge
                Text("\(j.line.number)")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(j.line.color)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(terminusJa)行き")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(j.line.color)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text("\(j.terminus)행 · \(stopCount)정거장")
                        .font(.system(size: 12))
                        .foregroundStyle(KORATheme.labelSecondary)
                }

                Spacer()

                // Next station (if more than 1 stop)
                if let next = nextKo, stopCount > 1 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("次の駅")
                            .font(.system(size: 10))
                            .foregroundStyle(KORATheme.labelSecondary)
                        Text(MetroLineData.displayName(for: next, language: .japanese))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(KORATheme.labelPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text(next)
                            .font(.system(size: 10))
                            .foregroundStyle(KORATheme.labelSecondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            // Multiple routes (e.g., line 1 branches)
            if journeys.count > 1 {
                Divider()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(journeys.indices, id: \.self) { idx in
                            let jj = journeys[idx]
                            Button { selectedJourneyIdx = idx } label: {
                                Text(jj.route.label)
                                    .font(.system(size: 12, weight: selectedJourneyIdx == idx ? .semibold : .regular))
                                    .foregroundStyle(selectedJourneyIdx == idx ? .white : jj.line.color)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(selectedJourneyIdx == idx ? jj.line.color : jj.line.color.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(j.line.color.opacity(0.06))
    }

    // MARK: Station list

    private func stationList(_ j: JourneyResult) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(j.stations.enumerated()), id: \.offset) { idx, ko in
                    JourneyStationRow(
                        ko: ko,
                        ja: MetroLineData.displayName(for: ko, language: .japanese),
                        isFrom: idx == 0,
                        isTo: idx == j.stations.count - 1,
                        transfers: MetroLineData.transferBadges(for: ko, excluding: j.line.number),
                        lineColor: j.line.color
                    )
                }
            }
            .padding(.bottom, 32)
        }
    }

    // MARK: Empty states

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "tram.fill")
                .font(.system(size: 52))
                .foregroundStyle(KORATheme.accent.opacity(0.2))
            VStack(spacing: 6) {
                Text("現在地と目的地を選んでください")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(KORATheme.labelSecondary)
                Text("현재 역과 목적지를 위에서 선택하세요")
                    .font(.system(size: 12))
                    .foregroundStyle(KORATheme.labelSecondary.opacity(0.7))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var noRouteView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "arrow.triangle.swap")
                .font(.system(size: 44))
                .foregroundStyle(KORATheme.labelSecondary.opacity(0.25))
            Text("직접 이동하는 노선이 없습니다")
                .font(.system(size: 15))
                .foregroundStyle(KORATheme.labelSecondary)
            Text("환승 경로 안내는 준비 중입니다")
                .font(.system(size: 12))
                .foregroundStyle(KORATheme.labelSecondary.opacity(0.6))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Journey Station Row

struct JourneyStationRow: View {
    let ko: String
    let ja: String
    let isFrom: Bool
    let isTo: Bool
    let transfers: [(number: Int, color: Color)]
    let lineColor: Color

    private static let rowH: CGFloat = 62
    private var isTransfer: Bool { !transfers.isEmpty && !isFrom && !isTo }

    var body: some View {
        HStack(spacing: 12) {
            timeline
                .frame(width: 28, height: Self.rowH)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(ja)
                        .font(.system(size: isFrom || isTo ? 17 : 15,
                                      weight: isFrom || isTo ? .bold : .regular))
                        .foregroundStyle(isTo ? lineColor : KORATheme.labelPrimary)

                    if !transfers.isEmpty {
                        HStack(spacing: 3) {
                            ForEach(transfers, id: \.number) { t in
                                Text("\(t.number)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 16, height: 16)
                                    .background(t.color)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                Text(ko)
                    .font(.system(size: 11))
                    .foregroundStyle(KORATheme.labelSecondary)
            }

            Spacer()

            roleBadge
        }
        .padding(.leading, 20)
        .padding(.trailing, 16)
        .frame(minHeight: Self.rowH)
        .background(rowBackground)
    }

    @ViewBuilder
    private var roleBadge: some View {
        if isFrom {
            pill("現在地", fg: .white, bg: Color(.systemGray2))
        } else if isTo {
            pill("下車", fg: .white, bg: lineColor)
        } else if isTransfer {
            pill("乗換", fg: KORATheme.accent, bg: KORATheme.accent.opacity(0.12))
        }
    }

    private func pill(_ label: String, fg: Color, bg: Color) -> some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(bg)
            .clipShape(Capsule())
    }

    private var rowBackground: Color {
        if isFrom { return Color(.secondarySystemBackground).opacity(0.6) }
        if isTo { return lineColor.opacity(0.06) }
        return .clear
    }

    private var timeline: some View {
        ZStack {
            if !isFrom {
                VStack(spacing: 0) {
                    Rectangle().fill(lineColor.opacity(0.4)).frame(width: 3, height: Self.rowH / 2)
                    Spacer(minLength: 0)
                }
            }
            if !isTo {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Rectangle().fill(lineColor.opacity(0.4)).frame(width: 3, height: Self.rowH / 2)
                }
            }

            if isFrom {
                Circle()
                    .fill(Color(.systemGray2))
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: "location.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.white)
                    )
            } else if isTo {
                Circle()
                    .fill(lineColor)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: "flag.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.white)
                    )
            } else {
                Circle()
                    .fill(isTransfer ? lineColor : Color(.systemBackground))
                    .frame(width: isTransfer ? 12 : 9, height: isTransfer ? 12 : 9)
                    .overlay(Circle().stroke(lineColor, lineWidth: isTransfer ? 0 : 2))
            }
        }
    }
}

// MARK: - Station Search Sheet

struct StationSearchSheet: View {
    let title: String
    let excluding: String?
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [String] {
        let q = query.trimmingCharacters(in: .whitespaces)
        let base = MetroLineData.allStationNames.filter { $0 != excluding }
        guard !q.isEmpty else { return base }
        return base.filter { s in
            s.contains(q)
                || MetroLineData.displayName(for: s, language: .japanese).contains(q)
                || MetroLineData.displayName(for: s, language: .english).lowercased().contains(q.lowercased())
        }
    }

    var body: some View {
        NavigationView {
            List(filtered, id: \.self) { station in
                Button {
                    onSelect(station)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(MetroLineData.displayName(for: station, language: .japanese))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(KORATheme.labelPrimary)
                            Text(station)
                                .font(.system(size: 12))
                                .foregroundStyle(KORATheme.labelSecondary)
                        }
                        Spacer()
                        HStack(spacing: 3) {
                            ForEach(linesForStation(station), id: \.self) { num in
                                Text("\(num)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 18, height: 18)
                                    .background(MetroLineData.lineColor(num))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $query, prompt: "역 이름 (한국어 · 日本語 · English)")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func linesForStation(_ station: String) -> [Int] {
        var result: [Int] = []
        for line in MetroLineData.seoulLines {
            guard !result.contains(line.number) else { continue }
            if line.routes.contains(where: { $0.stations.contains(station) }) {
                result.append(line.number)
            }
        }
        return result
    }
}

// MARK: - Preview

#Preview {
    SubwayNavigatorView()
}
