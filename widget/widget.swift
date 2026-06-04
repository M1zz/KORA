import WidgetKit
import SwiftUI

// MARK: - Data shared via App Group

private let appGroupID = "group.com.kora.leeo"

struct SavedPlaceEntry: Codable {
    let name: String
    let nameJP: String
    let nearestStation: String
    let categoryRaw: String
}

func loadRecentPlaces() -> [SavedPlaceEntry] {
    guard let defaults = UserDefaults(suiteName: appGroupID),
          let data = defaults.data(forKey: "kora.widget.recentPlaces"),
          let decoded = try? JSONDecoder().decode([SavedPlaceEntry].self, from: data)
    else { return [] }
    return Array(decoded.prefix(3))
}

// MARK: - Timeline

struct KoreaWayEntry: TimelineEntry {
    let date: Date
    let recentPlaces: [SavedPlaceEntry]
}

struct KoreaWayProvider: TimelineProvider {
    func placeholder(in context: Context) -> KoreaWayEntry {
        KoreaWayEntry(date: Date(), recentPlaces: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (KoreaWayEntry) -> ()) {
        completion(KoreaWayEntry(date: Date(), recentPlaces: loadRecentPlaces()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KoreaWayEntry>) -> ()) {
        let entry = KoreaWayEntry(date: Date(), recentPlaces: loadRecentPlaces())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
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

private struct SmallWidgetView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "tram.fill")
                    .font(.title3).fontWeight(.black)
                    .foregroundStyle(Color(hex: "3A7BCA"))
                Text("KoreaWay")
                    .font(.headline).fontWeight(.black)
                    .foregroundStyle(.primary)
            }
            LineAccentBar()
            Spacer()
            Text("서울 지하철\n길 안내")
                .font(.callout).fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "kora://subway"))
    }
}

private struct MediumWidgetView: View {
    let places: [SavedPlaceEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "tram.fill")
                    .font(.callout).fontWeight(.bold)
                    .foregroundStyle(Color(hex: "3A7BCA"))
                Text("KoreaWay")
                    .font(.callout).fontWeight(.black)
                Spacer()
                Text("가고싶은 곳")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 6)

            LineAccentBar()
                .padding(.horizontal, 14)

            if places.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "bookmark.fill")
                            .font(.title3)
                            .foregroundStyle(Color(hex: "3A7BCA").opacity(0.6))
                        Text("앱에서 장소를 저장해보세요")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                VStack(spacing: 0) {
                    ForEach(places.indices, id: \.self) { i in
                        Link(destination: URL(string: "kora://subway?dest=\(places[i].nearestStation.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!) {
                            HStack(spacing: 8) {
                                Image(systemName: categoryImage(places[i].categoryRaw))
                                    .font(.caption).frame(width: 16)
                                    .foregroundStyle(Color(hex: "3A7BCA"))
                                Text(places[i].nameJP.isEmpty ? places[i].name : places[i].nameJP)
                                    .font(.caption).fontWeight(.semibold)
                                    .lineLimit(1)
                                Spacer()
                                if !places[i].nearestStation.isEmpty {
                                    Text(places[i].nearestStation)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: "3A7BCA").opacity(0.7))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                        }
                        if i < places.count - 1 {
                            Divider().padding(.leading, 38)
                        }
                    }
                }
                .padding(.top, 4)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(URL(string: "kora://subway"))
    }

    private func categoryImage(_ raw: String) -> String {
        switch raw {
        case "restaurant": return "fork.knife"
        case "cafe":       return "cup.and.saucer.fill"
        case "shopping":   return "bag.fill"
        case "attraction": return "camera.fill"
        case "beauty":     return "sparkles"
        default:           return "mappin.circle.fill"
        }
    }
}

struct KoreaWayWidgetEntryView: View {
    var entry: KoreaWayEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(places: entry.recentPlaces)
        default:
            SmallWidgetView()
        }
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
        .configurationDisplayName("KoreaWay")
        .description("저장한 장소로 빠르게 지하철 경로를 안내합니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
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
    KoreaWayEntry(date: .now, recentPlaces: [])
}

#Preview(as: .systemMedium) {
    KoreaWayWidget()
} timeline: {
    KoreaWayEntry(date: .now, recentPlaces: [
        SavedPlaceEntry(name: "광장시장", nameJP: "クァンジャン市場", nearestStation: "종로5가", categoryRaw: "restaurant"),
        SavedPlaceEntry(name: "성수카페", nameJP: "ソンスカフェ", nearestStation: "성수", categoryRaw: "cafe"),
    ])
}
