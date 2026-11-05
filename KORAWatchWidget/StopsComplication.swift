//
//  StopsComplication.swift
//  KORAWatchWidget
//
//  손목을 들 때마다 보는 값 하나: 내릴 역까지 남은 정거장.
//  역마다 닿을 시각에 항목을 하나씩 두어, 아이폰이 잠들어 있어도 정거장마다 하나씩 줄어든다.
//

import WidgetKit
import SwiftUI

struct StopsEntry: TimelineEntry {
    let date: Date
    let ride: RideSnapshot?
}

struct StopsProvider: TimelineProvider {
    func placeholder(in context: Context) -> StopsEntry {
        StopsEntry(date: .now, ride: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (StopsEntry) -> Void) {
        completion(entries().first ?? placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StopsEntry>) -> Void) {
        completion(Timeline(entries: entries(), policy: .never))
    }

    /// 지금 한 장 + 다음 역에 닿을 때마다 한 장 + 내릴 역을 한참 지나면 '안 타는 중'
    private func entries() -> [StopsEntry] {
        guard let ride = RideLink.load() else { return [StopsEntry(date: .now, ride: nil)] }
        let now = Date.now
        let upcoming = (ride.index(at: now) + 1 ..< ride.stations.count).map { ride.arrival(atIndex: $0) }
        return [StopsEntry(date: now, ride: ride)]
            + upcoming.map { StopsEntry(date: $0, ride: ride) }
            + [StopsEntry(date: ride.expiresAt, ride: nil)]
    }
}

struct StopsComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StopsEntry

    var body: some View {
        if let ride = entry.ride {
            riding(ride, left: ride.stopsLeft(at: entry.date))
        } else {
            idle
        }
    }

    @ViewBuilder
    private func riding(_ ride: RideSnapshot, left: Int) -> some View {
        let total = max(ride.stations.count - 1, 1)
        let color = ride.lineColor ?? .red
        switch family {
        case .accessoryCircular:
            Gauge(value: Double(total - left), in: 0...Double(total)) {
                Image(systemName: "tram.fill")
            } currentValueLabel: {
                Text(verbatim: "\(left)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(color)
            .widgetAccentable()
        case .accessoryCorner:
            Text(verbatim: "\(left)")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .widgetAccentable()
                .widgetLabel {
                    Gauge(value: Double(total - left), in: 0...Double(total)) {
                        Text(ride.alightStation)
                    }
                    .tint(color)
                }
        case .accessoryInline:
            Label {
                Text(verbatim: "\(left) · \(ride.alightStation)")
            } icon: {
                Image(systemName: "tram.fill")
            }
        default:
            VStack(alignment: .leading, spacing: 0) {
                Text(ride.line)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(color)
                    .widgetAccentable()
                    .lineLimit(1)
                if left <= 1 {
                    Text(left == 1 ? ride.labels.nextStopGetOff : ride.labels.getOffNow)
                        .font(.headline)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(verbatim: "\(left)")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                        Text(ride.stopsUnit(left)).font(.caption2)
                    }
                }
                Text(ride.alightStation)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var idle: some View {
        switch family {
        case .accessoryCircular, .accessoryCorner:
            Image(systemName: "tram")
                .font(.title3)
                .widgetAccentable()
        case .accessoryInline:
            Text(verbatim: "KORA")
        default:
            VStack(alignment: .leading, spacing: 2) {
                Label { Text(verbatim: "KORA") } icon: { Image(systemName: "tram.fill") }
                    .font(.headline)
                    .widgetAccentable()
                Text("Not on a train")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

@main
struct StopsComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StopsLeft", provider: StopsProvider()) { entry in
            StopsComplicationView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Stops left")
        .description("Shows how many stops are left until you get off.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryCorner, .accessoryInline])
    }
}
