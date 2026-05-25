import SwiftUI

// MARK: - SubwayLineBrowserView

struct SubwayLineBrowserView: View {
    @State private var selectedLineIdx: Int = 2   // default: 3호선
    @State private var selectedRouteIdx: Int = 0
    @State private var isReversed: Bool = false

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

            if line.routes.count > 1 {
                routeSelector
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                Divider()
            }

            directionBar
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
                label: "\(route.terminusA)행",
                icon: "arrow.left",
                isSelected: !isReversed,
                isLeft: true
            ) { isReversed = false }

            Rectangle()
                .fill(line.color.opacity(0.25))
                .frame(width: 1)

            directionButton(
                label: "\(route.terminusB)행",
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

    private func directionButton(
        label: String,
        icon: String,
        isSelected: Bool,
        isLeft: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isLeft {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if !isLeft {
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .semibold))
                }
            }
            .foregroundStyle(isSelected ? .white : KORATheme.labelSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isSelected ? line.color : Color.clear)
        }
    }

    private var circleDirectionBar: some View {
        HStack(spacing: 8) {
            circleDirectionButton("외선순환", icon: "arrow.clockwise", isSelected: !isReversed) {
                isReversed = false
            }
            circleDirectionButton("내선순환", icon: "arrow.counterclockwise", isSelected: isReversed) {
                isReversed = true
            }
            Spacer()
        }
    }

    private func circleDirectionButton(
        _ label: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
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

    // MARK: - Station List

    private var stationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(displayedStations.enumerated()), id: \.offset) { idx, name in
                    StationTimelineRow(
                        name: name,
                        isFirst: idx == 0,
                        isLast: idx == displayedStations.count - 1,
                        isCircular: route.isCircular,
                        lineColor: line.color
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
    let name: String
    let isFirst: Bool
    let isLast: Bool
    let isCircular: Bool
    let lineColor: Color

    private var isTerminus: Bool { !isCircular && (isFirst || isLast) }
    private static let rowH: CGFloat = 46

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                // Top connector (drawn for all rows except the first of a non-circular line)
                if !isFirst || isCircular {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(lineColor.opacity(0.5))
                            .frame(width: 3, height: Self.rowH / 2)
                        Spacer(minLength: 0)
                    }
                }
                // Bottom connector
                if !isLast || isCircular {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        Rectangle()
                            .fill(lineColor.opacity(0.5))
                            .frame(width: 3, height: Self.rowH / 2)
                    }
                }
                // Station dot
                Circle()
                    .fill(isTerminus ? lineColor : Color(.systemBackground))
                    .frame(
                        width: isTerminus ? 14 : 10,
                        height: isTerminus ? 14 : 10
                    )
                    .overlay(
                        Circle().stroke(lineColor, lineWidth: isTerminus ? 0 : 2.5)
                    )
            }
            .frame(width: 20, height: Self.rowH)

            Text(name)
                .font(.system(
                    size: isTerminus ? 15 : 14,
                    weight: isTerminus ? .bold : .regular
                ))
                .foregroundStyle(isTerminus ? lineColor : KORATheme.labelPrimary)

            Spacer()
        }
        .padding(.leading, 28)
        .frame(height: Self.rowH)
    }
}

// MARK: - Preview

#Preview {
    SubwayLineBrowserView()
}
