import SwiftUI
import UserNotifications

/// 막차 알림 (KORA Pro). 이 경로로 오늘 밤 갈 수 있는 마지막 출발 시각을 알려 준다.
///
/// 원본은 서울 열린데이터광장의 역별 막차 시간(1~9호선)이고
/// `scripts/station-data/build_last_trains.py` 가 `last_trains.json` 으로 만든다.
/// 다른 노선이 한 구간이라도 끼면 시각을 지어내지 않고 아무것도 보이지 않는다.
enum LastTrainService {

    struct Deadline: Equatable {
        /// 여정 첫 역 (여기서 이 시각까지 타야 한다).
        let station: String
        /// 출발 시각 (실제 날짜·시각).
        let date: Date
        /// "00:46" 처럼 서울 시각으로.
        let clock: String
    }

    // MARK: - 데이터

    private struct Departure: Decodable {
        let destination: String
        let minute: Int   // 운행일 자정 기준 분, 자정 넘김은 24시 이후로 (00:46 → 1486)

        init(from decoder: Decoder) throws {
            var c = try decoder.unkeyedContainer()
            destination = try c.decode(String.self)
            minute = try c.decode(Int.self)
        }
    }

    /// "역|노선" → 요일 태그 → 방향 태그 → 행선지별 마지막 열차
    private static let table: [String: [String: [String: [Departure]]]] = {
        guard let url = Bundle.main.url(forResource: "last_trains", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [String: [String: [Departure]]]].self, from: data)
        else {
            assertionFailure("last_trains.json 을 읽지 못했다")
            return [:]
        }
        return decoded
    }()

    private static let seoul = TimeZone(identifier: "Asia/Seoul")!
    private static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = seoul
        return c
    }

    // MARK: - 계산

    /// 이 여정의 오늘 밤 마지막 출발. 데이터가 없는 노선이 끼면 nil.
    static func deadline(for journey: TransferJourney, now: Date = Date()) -> Deadline? {
        guard !journey.segments.isEmpty, let origin = journey.segments.first?.stations.first else { return nil }
        let (serviceDay, tags) = serviceDayAndTags(now)

        // 마지막 구간부터 거꾸로: 다음 구간 막차에 닿으려면 이 구간을 언제까지 타야 하나.
        var latest: Int?
        for seg in journey.segments.reversed() {
            let perTag = tags.map { lastDeparture(seg, tag: $0) }
            guard !perTag.contains(where: { $0 == nil }), let own = perTag.compactMap({ $0 }).min() else { return nil }
            if let next = latest {
                let ride = Int((Double(seg.stopCount * SubwayScheduleService.scheduleSecsPerStop(for: seg)) / 60).rounded(.up))
                let walk = MetroLineData.transferWalkingMinutes(at: seg.stations.last ?? "")
                // 열차는 띄엄띄엄 오므로 환승 연결 쪽이 정할 때는 5분 여유를 둔다.
                let connection = next - ride - walk - 5
                latest = min(own, connection)
            } else {
                latest = own
            }
        }
        guard let minute = latest else { return nil }
        let date = serviceDay.addingTimeInterval(TimeInterval(minute * 60))
        let clock = String(format: "%02d:%02d", (minute / 60) % 24, minute % 60)
        return Deadline(station: origin, date: date, clock: clock)
    }

    /// 한 구간을 그 방향으로 끝까지(내릴 역 이상) 가는 마지막 열차의 출발 분.
    private static func lastDeparture(_ seg: JourneySegment, tag: String) -> Int? {
        guard let board = seg.stations.first,
              let byDirection = table["\(board)|\(seg.line.number)"]?[tag] else { return nil }
        var best: Int?
        for (direction, trains) in byDirection {
            for t in trains where reaches(seg, destination: t.destination, directionTag: direction) {
                best = max(best ?? t.minute, t.minute)
            }
        }
        return best
    }

    /// 행선지가 `destination` 인 열차가 이 구간의 내릴 역까지 가는지.
    private static func reaches(_ seg: JourneySegment, destination: String, directionTag: String) -> Bool {
        guard seg.stations.count >= 2, let board = seg.stations.first, let alight = seg.stations.last else { return false }
        for route in seg.line.routes {
            let st = route.stations
            guard let ib = st.firstIndex(of: board), let ia = st.firstIndex(of: alight),
                  let id = st.firstIndex(of: destination) else { continue }
            if route.isCircular {
                // 순환선은 행선지만으로 방향을 알 수 없으니 방향 태그(1 = 내선, 2 = 외선)를 맞춘다.
                let n = st.count
                guard let i2 = st.firstIndex(of: seg.stations[1]) else { continue }
                let forward = (i2 - ib + n) % n == 1
                let forwardTag = (route.circularForwardLabel?.contains("내선") ?? true) ? "1" : "2"
                guard (directionTag == forwardTag) == forward else { continue }
                func distance(_ i: Int) -> Int { forward ? (i - ib + n) % n : (ib - i + n) % n }
                if id == ib || distance(id) >= distance(ia) { return true }
            } else if ia > ib ? id >= ia : id <= ia {
                return true
            }
        }
        return false
    }

    /// 운행일(새벽 4시까지는 전날)과 그날 쓸 시간표 태그. 1 = 평일, 2 = 토요일, 3 = 일요일·공휴일.
    /// 공휴일 표가 끝난 해의 평일에는 평일·휴일 중 이른 쪽을 쓴다 (늦은 시각을 잘못 알려 주면 안 된다).
    private static func serviceDayAndTags(_ now: Date) -> (Date, [String]) {
        let cal = calendar
        let day = cal.startOfDay(for: now.addingTimeInterval(-4 * 3600))
        let weekday = cal.component(.weekday, from: day)
        if weekday == 1 { return (day, ["3"]) }
        if weekday == 7 { return (day, ["2"]) }
        let c = cal.dateComponents([.year, .month, .day], from: day)
        guard let year = c.year, let month = c.month, let d = c.day else { return (day, ["1", "3"]) }
        if year > lastHolidayYear { return (day, ["1", "3"]) }
        return (day, holidays.contains(year * 10000 + month * 100 + d) ? ["3"] : ["1"])
    }

    /// 평일에 낀 공휴일·대체공휴일 (주말은 어차피 주말 시간표). 해가 바뀌기 전에 다음 해를 더한다.
    private static let lastHolidayYear = 2027
    private static let holidays: Set<Int> = [
        20260101, 20260216, 20260217, 20260218, 20260302, 20260505, 20260525, 20260603,
        20260817, 20260924, 20260925, 20260928, 20261005, 20261009, 20261225,
        20270101, 20270208, 20270209, 20270301, 20270505, 20270513, 20270816,
        20270914, 20270915, 20270916, 20271004, 20271011, 20271227,
    ]

    /// DEBUG 시험용 현재 시각: `-KORAFakeNow 2026-10-14T00:20:00+09:00`.
    static var debugNow: Date? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "KORAFakeNow").flatMap { ISO8601DateFormatter().date(from: $0) }
        #else
        nil
        #endif
    }

    // MARK: - 알림

    private static let reminderIDs = ["kora.lasttrain.30", "kora.lasttrain.10"]

    /// 막차 30분 전, 10분 전 알림. 권한을 거절하면 false.
    static func scheduleReminders(_ deadline: Deadline, lang: StationLanguage) async -> Bool {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return false }
        center.removePendingNotificationRequests(withIdentifiers: reminderIDs)
        let station = MetroLineData.displayName(for: deadline.station, language: lang)
        for (lead, id) in zip([30, 10], reminderIDs) {
            let fire = deadline.date.addingTimeInterval(TimeInterval(-lead * 60))
            guard fire > Date() else { continue }
            let content = UNMutableNotificationContent()
            content.title = NavLoc.lastTrainNotifyTitle.fill(lang, "\(lead)")
            content.body = NavLoc.lastTrainInfo.fill(lang, station, deadline.clock)
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fire.timeIntervalSinceNow, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
        return true
    }
}

/// 앱을 보고 있을 때도 막차 알림을 배너로 띄운다.
final class KORANotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = KORANotificationPresenter()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

/// 경로 확인 화면의 막차 카드. 막차 3시간 전부터 새벽 4시까지만 보인다.
struct LastTrainCard: View {
    let journey: TransferJourney
    let lang: StationLanguage
    let unlocked: Bool
    let onLocked: () -> Void

    @State private var reminderSet = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            let now = LastTrainService.debugNow ?? context.date
            if let deadline = LastTrainService.deadline(for: journey, now: now) {
                let left = deadline.date.timeIntervalSince(now) / 60
                if left <= 180 {
                    if unlocked {
                        card(deadline, minutesLeft: left)
                    } else {
                        lockedRow
                    }
                }
            }
        }
    }

    private func card(_ deadline: LastTrainService.Deadline, minutesLeft: Double) -> some View {
        let gone = minutesLeft < 0
        let soon = !gone && minutesLeft <= 30
        let tint: Color = gone ? .red : (soon ? .orange : KORATheme.accent)
        let station = MetroLineData.displayName(for: deadline.station, language: lang)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: gone ? "exclamationmark.triangle.fill" : "moon.stars.fill")
                Text((gone ? NavLoc.lastTrainGone : soon ? NavLoc.lastTrainSoon : NavLoc.lastTrainTonight).resolved(lang))
                    .fontWeight(.bold)
                Spacer(minLength: 4)
                if !gone {
                    Text(deadline.clock)
                        .font(.title3).fontWeight(.heavy)
                        .monospacedDigit()
                }
            }
            .font(.body)
            .foregroundStyle(tint)

            Text((gone ? NavLoc.lastTrainGoneHint : NavLoc.lastTrainInfo).fill(lang, station, deadline.clock))
                .font(.subheadline)
                .foregroundStyle(KORATheme.labelPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if !gone, minutesLeft > 10 {
                if reminderSet {
                    Label(NavLoc.lastTrainReminderSet.resolved(lang), systemImage: "bell.fill")
                        .font(.footnote).fontWeight(.semibold)
                        .foregroundStyle(tint)
                } else {
                    Button {
                        Task { reminderSet = await LastTrainService.scheduleReminders(deadline, lang: lang) }
                    } label: {
                        Label(NavLoc.lastTrainRemind.resolved(lang), systemImage: "bell")
                            .font(.footnote).fontWeight(.bold)
                    }
                    .tint(tint)
                }
            }

            Text(NavLoc.lastTrainNote.resolved(lang))
                .font(.caption)
                .foregroundStyle(KORATheme.labelSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: KORATheme.radiusMD))
    }

    private var lockedRow: some View {
        Button(action: onLocked) {
            HStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.body).fontWeight(.semibold)
                Text(NavLoc.lastTrainTonight.resolved(lang))
                    .font(.body).fontWeight(.semibold)
                Spacer(minLength: 4)
                Label("Pro", systemImage: "lock.fill")
                    .font(.caption).fontWeight(.bold)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(KORATheme.accent.opacity(0.15), in: Capsule())
            }
            .foregroundStyle(KORATheme.accent)
            .padding(.horizontal, 16).padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(KORATheme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: KORATheme.radiusMD))
        }
        .buttonStyle(.plain)
    }
}
