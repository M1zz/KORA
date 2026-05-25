import SwiftUI

// MARK: - SubwayLineBrowserView

struct SubwayLineBrowserView: View {
    @State private var selectedLineIdx: Int = 2   // default: 3호선
    @State private var selectedRouteIdx: Int = 0
    @State private var isReversed: Bool = false
    @State private var language: StationLanguage = .japanese

    private let lines = MetroLineData.seoulLines

    private var line: SeoulMetroLineInfo { lines[selectedLineIdx] }
    private var route: MetroRoute { line.routes[min(selectedRouteIdx, line.routes.count - 1)] }
    private var displayedStations: [String] {
        isReversed ? Array(route.stations.reversed()) : route.stations
    }

    var body: some View {
        VStack(spacing: 0) {
            lineSelector
            Divider()

            // Route picker (only for lines with branches)
            if line.routes.count > 1 {
                routeSelector
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                Divider()
            }

            // Direction toggle + language toggle in one bar
            HStack(spacing: 12) {
                directionBar
                Spacer(minLength: 0)
                languageMenu
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            Divider()

            stationList
        }
    }

    // MARK: - Line Selector

    private var lineSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(lines.indices, id: \.self) { idx in
                    let l = lines[idx]
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedLineIdx = idx
                            selectedRouteIdx = 0
                            isReversed = false
                        }
                    } label: {
                        Text(l.name)
                            .font(.system(size: 13, weight: selectedLineIdx == idx ? .bold : .medium))
                            .foregroundStyle(selectedLineIdx == idx ? .white : l.color)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedLineIdx == idx ? l.color : l.color.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Route Selector

    private var routeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(line.routes.indices, id: \.self) { idx in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedRouteIdx = idx
                            isReversed = false
                        }
                    } label: {
                        Text(line.routes[idx].label)
                            .font(.system(size: 12, weight: selectedRouteIdx == idx ? .semibold : .regular))
                            .foregroundStyle(selectedRouteIdx == idx ? line.color : KORATheme.labelSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedRouteIdx == idx
                                    ? line.color.opacity(0.12)
                                    : Color(.secondarySystemBackground)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Direction Bar

    private var directionBar: some View {
        Group {
            if route.isCircular {
                circleDirectionBar
            } else {
                linearDirectionBar
            }
        }
    }

    private var linearDirectionBar: some View {
        HStack(spacing: 0) {
            directionButton(
                label: terminusLabel(route.terminusA),
                icon: "arrow.left",
                isSelected: !isReversed,
                isLeft: true
            ) { isReversed = false }

            Rectangle()
                .fill(line.color.opacity(0.25))
                .frame(width: 1)

            directionButton(
                label: terminusLabel(route.terminusB),
                icon: "arrow.right",
                isSelected: isReversed,
                isLeft: false
            ) { isReversed = true }
        }
        .frame(height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(line.color.opacity(0.25), lineWidth: 1)
        )
    }

    private func terminusLabel(_ ko: String) -> String {
        switch language {
        case .korean:   return "\(ko)행"
        case .japanese: return "\(MetroLineData.displayName(for: ko, language: .japanese))行"
        case .english:  return "To \(MetroLineData.displayName(for: ko, language: .english))"
        }
    }

    private func directionButton(
        label: String,
        icon: String,
        isSelected: Bool,
        isLeft: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isLeft {
                    Image(systemName: icon).font(.system(size: 10, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if !isLeft {
                    Image(systemName: icon).font(.system(size: 10, weight: .semibold))
                }
            }
            .foregroundStyle(isSelected ? .white : KORATheme.labelSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isSelected ? line.color : Color.clear)
        }
    }

    private var circleDirectionBar: some View {
        HStack(spacing: 8) {
            circleDirectionButton("外線循環", sub: "외선순환", icon: "arrow.clockwise",   isSelected: !isReversed) { isReversed = false }
            circleDirectionButton("内線循環", sub: "내선순환", icon: "arrow.counterclockwise", isSelected: isReversed)  { isReversed = true  }
        }
    }

    private func circleDirectionButton(
        _ ja: String, sub ko: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let label: String = {
            switch language {
            case .korean:   return ko
            case .japanese: return ja
            case .english:  return ja == "外線循環" ? "Outer Loop" : "Inner Loop"
            }
        }()
        return Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 11, weight: .medium))
                Text(label).font(.system(size: 13, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? line.color : KORATheme.labelSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected ? line.color.opacity(0.12) : Color(.secondarySystemBackground)
            )
            .clipShape(Capsule())
        }
    }

    // MARK: - Language Menu

    private var languageMenu: some View {
        Menu {
            ForEach(StationLanguage.allCases, id: \.self) { lang in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { language = lang }
                } label: {
                    HStack {
                        Text(lang.rawValue)
                        if language == lang {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.system(size: 13, weight: .medium))
                Text(language.rawValue)
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(KORATheme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(KORATheme.accent.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    // MARK: - Station List

    private var stationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(displayedStations.enumerated()), id: \.offset) { idx, ko in
                    StationTimelineRow(
                        primaryName: MetroLineData.displayName(for: ko, language: language),
                        subtitle: MetroLineData.subtitle(for: ko, language: language),
                        isFirst: idx == 0,
                        isLast: idx == displayedStations.count - 1,
                        isCircular: route.isCircular,
                        lineColor: line.color,
                        transfers: MetroLineData.transferBadges(for: ko, excluding: line.number)
                    )
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Station Timeline Row

struct StationTimelineRow: View {
    let primaryName: String
    let subtitle: String?
    let isFirst: Bool
    let isLast: Bool
    let isCircular: Bool
    let lineColor: Color
    let transfers: [(number: Int, color: Color)]

    private var isTerminus: Bool { !isCircular && (isFirst || isLast) }
    private static let rowH: CGFloat = 52

    var body: some View {
        HStack(spacing: 14) {
            timeline
                .frame(width: 20, height: Self.rowH)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(primaryName)
                        .font(.system(
                            size: isTerminus ? 15 : 14,
                            weight: isTerminus ? .bold : .regular
                        ))
                        .foregroundStyle(isTerminus ? lineColor : KORATheme.labelPrimary)

                    if !transfers.isEmpty {
                        HStack(spacing: 4) {
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

                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 11))
                        .foregroundStyle(KORATheme.labelSecondary)
                }
            }

            Spacer()
        }
        .padding(.leading, 28)
        .frame(minHeight: Self.rowH)
    }

    private var timeline: some View {
        ZStack {
            if !isFirst || isCircular {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(lineColor.opacity(0.5))
                        .frame(width: 3, height: Self.rowH / 2)
                    Spacer(minLength: 0)
                }
            }
            if !isLast || isCircular {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    Rectangle()
                        .fill(lineColor.opacity(0.5))
                        .frame(width: 3, height: Self.rowH / 2)
                }
            }
            Circle()
                .fill(isTerminus ? lineColor : Color(.systemBackground))
                .frame(width: isTerminus ? 14 : 10, height: isTerminus ? 14 : 10)
                .overlay(Circle().stroke(lineColor, lineWidth: isTerminus ? 0 : 2.5))
        }
    }
}

// MARK: - Preview

#Preview {
    SubwayLineBrowserView()
}
