import WidgetKit
import SwiftUI

// MARK: - Timeline

/// The widget is a static shortcut into the navigator — nothing to refresh.
struct KoreaWayEntry: TimelineEntry {
    let date: Date
}

struct KoreaWayProvider: TimelineProvider {
    func placeholder(in context: Context) -> KoreaWayEntry {
        KoreaWayEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (KoreaWayEntry) -> ()) {
        completion(KoreaWayEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KoreaWayEntry>) -> ()) {
        completion(Timeline(entries: [KoreaWayEntry(date: Date())], policy: .never))
    }
}

// MARK: - Views

private struct LineAccentBar: View {
    let colors: [Color] = [.orange, Color(hex: "3A7BCA"), .green, .yellow, Color(hex: "8B4DC8")]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(colors.indices, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(colors[i])
                    .frame(height: 4)
            }
        }
    }
}

struct KoreaWayWidgetEntryView: View {
    var entry: KoreaWayEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "tram.fill")
                .font(.title2).fontWeight(.black)
                .foregroundStyle(Color(hex: "3A7BCA"))
            LineAccentBar()
            Spacer()
            Text("Subway directions")
                .font(.body).fontWeight(.bold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "kora://subway"))
    }
}

// MARK: - Widget

struct KoreaWayWidget: Widget {
    let kind: String = "KoreaWayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KoreaWayProvider()) { entry in
            KoreaWayWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Subway directions")
        .description("Open the subway navigator in one tap.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Color helper (widget-local)

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
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    KoreaWayWidget()
} timeline: {
    KoreaWayEntry(date: .now)
}
