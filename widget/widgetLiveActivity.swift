import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Color helper (widget-local, mirrors KORATheme)

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Lock-screen / banner view

@available(iOS 16.1, *)
private struct KORALockScreenView: View {
    let context: ActivityViewContext<KORALiveActivityAttributes>

    private var lineColor: Color { Color(hex: context.state.lineColorHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header: line name + destination
            HStack(spacing: 6) {
                Image(systemName: "tram.fill")
                    .font(.caption).fontWeight(.bold)
                    .foregroundStyle(lineColor)
                Text(context.state.lineName)
                    .font(.caption).fontWeight(.bold)
                    .foregroundStyle(lineColor)
                Spacer()
                Text("→ \(context.attributes.destinationStation)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Current → Next
            HStack(alignment: .center, spacing: 8) {
                Text(context.state.currentStation)
                    .font(.title3).fontWeight(.black)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Image(systemName: "arrow.right")
                    .font(.body).fontWeight(.bold)
                    .foregroundStyle(lineColor)
                Text(context.state.nextStation)
                    .font(.title3).fontWeight(.black)
                    .foregroundStyle(lineColor)
                    .lineLimit(1)
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(context.state.stopsRemaining)")
                        .font(.title2).fontWeight(.black)
                        .foregroundStyle(.primary)
                    Text("정거장")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .activityBackgroundTint(Color.black.opacity(0.04))
        .activitySystemActionForegroundColor(.primary)
    }
}

// MARK: - Widget

@available(iOS 16.1, *)
struct widgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KORALiveActivityAttributes.self) { context in
            KORALockScreenView(context: context)
        } dynamicIsland: { context in
            let lineColor = Color(hex: context.state.lineColorHex)

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.lineName, systemImage: "tram.fill")
                        .font(.body).fontWeight(.bold)
                        .foregroundStyle(lineColor)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("→ \(context.attributes.destinationStation)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        Text(context.state.currentStation)
                            .font(.title2).fontWeight(.black)
                            .lineLimit(1)
                        Image(systemName: "arrow.right")
                            .fontWeight(.bold)
                            .foregroundStyle(lineColor)
                        Text(context.state.nextStation)
                            .font(.title2).fontWeight(.black)
                            .foregroundStyle(lineColor)
                            .lineLimit(1)
                        Spacer()
                        Text("\(context.state.stopsRemaining)정거장")
                            .font(.body).fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Label(context.state.lineName, systemImage: "tram.fill")
                    .font(.caption2).fontWeight(.bold)
                    .foregroundStyle(lineColor)
            } compactTrailing: {
                Text(context.state.nextStation)
                    .font(.caption2).fontWeight(.bold)
                    .foregroundStyle(lineColor)
                    .lineLimit(1)
            } minimal: {
                Image(systemName: "tram.fill")
                    .foregroundStyle(lineColor)
            }
            .widgetURL(URL(string: "kora://subway"))
            .keylineTint(lineColor)
        }
    }
}
