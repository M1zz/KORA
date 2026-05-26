import Foundation

// MARK: - Types

struct HeadwayRule {
    let fromMinute: Int   // minutes past midnight (300 = 05:00)
    let toMinute: Int
    let everyMinutes: Int
}

struct RouteSchedule {
    let lineNumber: Int
    let terminusA: String   // route.stations.first
    let terminusB: String   // route.stations.last
    let isCircular: Bool
    // minutes past midnight from terminusA going toward terminusB (weekday/sat/sun)
    let firstFromA_wd: Int;  let firstFromA_sat: Int;  let firstFromA_sun: Int
    // minutes past midnight from terminusB going toward terminusA
    let firstFromB_wd: Int;  let firstFromB_sat: Int;  let firstFromB_sun: Int
    let secsPerStop: Int
    let weekdayHeadways: [HeadwayRule]
    let weekendHeadways: [HeadwayRule]
}

struct SegmentTiming {
    let nextArrivalAtBoarding: Date   // when the next train arrives at boarding station
    let minutesUntilArrival: Int
    let currentTrainStation: String?  // nil = train waiting at terminal
    let currentTrainTerminus: String  // origin terminal of this train
    let travelMinutes: Int            // travel time for this segment in minutes
}

// MARK: - Service

enum SubwayScheduleService {

    static let schedules: [RouteSchedule] = {
        func h(_ f: Int, _ t: Int, _ e: Int) -> HeadwayRule { HeadwayRule(fromMinute: f, toMinute: t, everyMinutes: e) }
        return [
            // Line 1
            RouteSchedule(lineNumber:1, terminusA:"소요산", terminusB:"인천", isCircular:false,
                firstFromA_wd:322, firstFromA_sat:325, firstFromA_sun:330,
                firstFromB_wd:305, firstFromB_sat:310, firstFromB_sun:315, secsPerStop:135,
                weekdayHeadways:[h(300,390,10),h(390,540,5),h(540,1080,8),h(1080,1200,5),h(1200,1500,10)],
                weekendHeadways:[h(300,540,12),h(540,1320,8),h(1320,1500,12)]),
            RouteSchedule(lineNumber:1, terminusA:"소요산", terminusB:"신창", isCircular:false,
                firstFromA_wd:325, firstFromA_sat:330, firstFromA_sun:335,
                firstFromB_wd:310, firstFromB_sat:315, firstFromB_sun:320, secsPerStop:140,
                weekdayHeadways:[h(300,390,12),h(390,540,6),h(540,1080,9),h(1080,1200,6),h(1200,1500,12)],
                weekendHeadways:[h(300,540,14),h(540,1320,9),h(1320,1500,14)]),
            RouteSchedule(lineNumber:1, terminusA:"병점", terminusB:"서동탄", isCircular:false,
                firstFromA_wd:340, firstFromA_sat:345, firstFromA_sun:350,
                firstFromB_wd:345, firstFromB_sat:350, firstFromB_sun:355, secsPerStop:120,
                weekdayHeadways:[h(300,1500,20)], weekendHeadways:[h(300,1500,25)]),
            // Line 2
            RouteSchedule(lineNumber:2, terminusA:"시청", terminusB:"충정로", isCircular:true,
                firstFromA_wd:328, firstFromA_sat:335, firstFromA_sun:340,
                firstFromB_wd:330, firstFromB_sat:337, firstFromB_sun:342, secsPerStop:100,
                weekdayHeadways:[h(300,390,7),h(390,540,3),h(540,1080,4),h(1080,1260,3),h(1260,1500,6)],
                weekendHeadways:[h(300,480,8),h(480,1320,5),h(1320,1500,7)]),
            RouteSchedule(lineNumber:2, terminusA:"성수", terminusB:"신답", isCircular:false,
                firstFromA_wd:340, firstFromA_sat:345, firstFromA_sun:350,
                firstFromB_wd:345, firstFromB_sat:350, firstFromB_sun:355, secsPerStop:100,
                weekdayHeadways:[h(300,390,15),h(390,540,8),h(540,1080,12),h(1080,1200,8),h(1200,1500,15)],
                weekendHeadways:[h(300,540,18),h(540,1320,12),h(1320,1500,18)]),
            RouteSchedule(lineNumber:2, terminusA:"신도림", terminusB:"까치산", isCircular:false,
                firstFromA_wd:335, firstFromA_sat:340, firstFromA_sun:345,
                firstFromB_wd:340, firstFromB_sat:345, firstFromB_sun:350, secsPerStop:100,
                weekdayHeadways:[h(300,390,15),h(390,540,8),h(540,1080,12),h(1080,1200,8),h(1200,1500,15)],
                weekendHeadways:[h(300,540,18),h(540,1320,12),h(1320,1500,18)]),
            // Line 3
            RouteSchedule(lineNumber:3, terminusA:"대화", terminusB:"오금", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:335, firstFromA_sun:340,
                firstFromB_wd:335, firstFromB_sat:340, firstFromB_sun:345, secsPerStop:120,
                weekdayHeadways:[h(300,420,7),h(420,540,4),h(540,1080,6),h(1080,1200,4),h(1200,1500,8)],
                weekendHeadways:[h(300,540,9),h(540,1320,6),h(1320,1500,9)]),
            // Line 4
            RouteSchedule(lineNumber:4, terminusA:"당고개", terminusB:"오이도", isCircular:false,
                firstFromA_wd:320, firstFromA_sat:325, firstFromA_sun:330,
                firstFromB_wd:317, firstFromB_sat:325, firstFromB_sun:330, secsPerStop:125,
                weekdayHeadways:[h(300,420,7),h(420,540,4),h(540,1080,6),h(1080,1200,4),h(1200,1500,8)],
                weekendHeadways:[h(300,540,9),h(540,1320,6),h(1320,1500,9)]),
            // Line 5
            RouteSchedule(lineNumber:5, terminusA:"방화", terminusB:"마천", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:335, firstFromA_sun:340,
                firstFromB_wd:332, firstFromB_sat:337, firstFromB_sun:342, secsPerStop:120,
                weekdayHeadways:[h(300,420,9),h(420,540,5),h(540,1080,8),h(1080,1200,5),h(1200,1500,10)],
                weekendHeadways:[h(300,540,11),h(540,1320,8),h(1320,1500,11)]),
            RouteSchedule(lineNumber:5, terminusA:"방화", terminusB:"하남검단산", isCircular:false,
                firstFromA_wd:332, firstFromA_sat:337, firstFromA_sun:342,
                firstFromB_wd:335, firstFromB_sat:340, firstFromB_sun:345, secsPerStop:120,
                weekdayHeadways:[h(300,420,9),h(420,540,5),h(540,1080,8),h(1080,1200,5),h(1200,1500,10)],
                weekendHeadways:[h(300,540,11),h(540,1320,8),h(1320,1500,11)]),
            // Line 6
            RouteSchedule(lineNumber:6, terminusA:"신내", terminusB:"응암", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:335, firstFromA_sun:340,
                firstFromB_wd:337, firstFromB_sat:342, firstFromB_sun:347, secsPerStop:130,
                weekdayHeadways:[h(300,420,9),h(420,540,5),h(540,1080,8),h(1080,1200,5),h(1200,1500,10)],
                weekendHeadways:[h(300,540,11),h(540,1320,9),h(1320,1500,11)]),
            // Line 7
            RouteSchedule(lineNumber:7, terminusA:"장암", terminusB:"부평구청", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:335, firstFromA_sun:340,
                firstFromB_wd:340, firstFromB_sat:345, firstFromB_sun:350, secsPerStop:120,
                weekdayHeadways:[h(300,420,7),h(420,540,4),h(540,1080,6),h(1080,1200,4),h(1200,1500,8)],
                weekendHeadways:[h(300,540,9),h(540,1320,6),h(1320,1500,9)]),
            // Line 8
            RouteSchedule(lineNumber:8, terminusA:"별내", terminusB:"모란", isCircular:false,
                firstFromA_wd:338, firstFromA_sat:343, firstFromA_sun:348,
                firstFromB_wd:339, firstFromB_sat:344, firstFromB_sun:349, secsPerStop:120,
                weekdayHeadways:[h(300,420,9),h(420,540,6),h(540,1080,9),h(1080,1200,6),h(1200,1500,11)],
                weekendHeadways:[h(300,540,12),h(540,1320,9),h(1320,1500,12)]),
            // Line 9
            RouteSchedule(lineNumber:9, terminusA:"개화", terminusB:"중앙보훈병원", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:335, firstFromA_sun:340,
                firstFromB_wd:335, firstFromB_sat:340, firstFromB_sun:345, secsPerStop:110,
                weekdayHeadways:[h(300,420,8),h(420,540,5),h(540,1080,7),h(1080,1200,5),h(1200,1500,9)],
                weekendHeadways:[h(300,540,10),h(540,1320,7),h(1320,1500,10)]),
        ]
    }()

    // MARK: - Public

    static func timing(for segment: JourneySegment, at now: Date = Date()) -> SegmentTiming? {
        guard let (schedule, isAtoB, routeStations) = findScheduleAndRoute(for: segment) else { return nil }

        let boarding = segment.stations[0]
        let stopsFromOrigin = countStops(in: routeStations, to: boarding, isAtoB: isAtoB)
        let offsetMinutes = stopsFromOrigin * schedule.secsPerStop / 60

        let terminalDepartureMinutes = nextTerminalDeparture(schedule: schedule, isAtoB: isAtoB, offsetMinutes: offsetMinutes, at: now)
        let boardingArrivalMinutes = terminalDepartureMinutes + offsetMinutes
        let boardingArrivalDate = minutesToDate(boardingArrivalMinutes, relativeTo: now)
        let minutesUntilArrival = max(0, Int(boardingArrivalDate.timeIntervalSinceNow / 60.0))

        let nowMin = nowMinutes(at: now)
        let terminusName: String
        let currentStation: String?

        if isAtoB {
            terminusName = schedule.terminusA
            if terminalDepartureMinutes > nowMin {
                currentStation = nil
            } else {
                let elapsed = nowMin - terminalDepartureMinutes
                let stop = min(elapsed * 60 / schedule.secsPerStop, routeStations.count - 1)
                currentStation = routeStations[stop]
            }
        } else {
            terminusName = schedule.terminusB
            let reversed = Array(routeStations.reversed())
            if terminalDepartureMinutes > nowMin {
                currentStation = nil
            } else {
                let elapsed = nowMin - terminalDepartureMinutes
                let stop = min(elapsed * 60 / schedule.secsPerStop, reversed.count - 1)
                currentStation = reversed[stop]
            }
        }

        return SegmentTiming(
            nextArrivalAtBoarding: boardingArrivalDate,
            minutesUntilArrival: minutesUntilArrival,
            currentTrainStation: currentStation,
            currentTrainTerminus: terminusName,
            travelMinutes: max(1, segment.stopCount * schedule.secsPerStop / 60)
        )
    }

    static func estimatedArrival(for journey: TransferJourney, at now: Date = Date()) -> Date? {
        guard !journey.segments.isEmpty,
              let firstTiming = timing(for: journey.segments[0], at: now) else { return nil }
        var total = firstTiming.minutesUntilArrival + firstTiming.travelMinutes
        for i in 1..<journey.segments.count {
            let seg = journey.segments[i]
            let walk = MetroLineData.transferWalkingMinutes(at: seg.stations[0])
            let hw = avgHeadway(for: seg, at: now) / 2
            let travel = max(1, seg.stopCount * (scheduleSecsPerStop(for: seg) / 60))
            total += walk + hw + travel
        }
        return now.addingTimeInterval(Double(total * 60))
    }

    // MARK: - Private

    private static func findScheduleAndRoute(for segment: JourneySegment) -> (RouteSchedule, Bool, [String])? {
        let lineNum = segment.line.number
        let terminus = segment.terminus
        guard let line = MetroLineData.seoulLines.first(where: { $0.number == lineNum }) else { return nil }

        for schedule in schedules where schedule.lineNumber == lineNum {
            if schedule.isCircular {
                guard let route = line.routes.first(where: { $0.isCircular }),
                      route.stations.contains(segment.stations[0]) else { continue }
                let stations = route.stations
                guard stations.count > 1 else { continue }
                let bi = stations.firstIndex(of: segment.stations[0]) ?? 0
                let nextStation = segment.stations.count > 1 ? segment.stations[1] : terminus
                let ni = stations.firstIndex(of: nextStation) ?? (bi + 1) % stations.count
                let isForward = (ni - bi + stations.count) % stations.count == 1
                return (schedule, isForward, stations)
            }
            // Linear route: match terminus
            for route in line.routes {
                let rA = route.terminusA, rB = route.terminusB
                let matchesSchedule = (rA == schedule.terminusA && rB == schedule.terminusB) ||
                                      (rA == schedule.terminusB && rB == schedule.terminusA)
                guard matchesSchedule else { continue }
                if route.terminusB == terminus { return (schedule, true, route.stations) }
                if route.terminusA == terminus { return (schedule, false, route.stations) }
            }
        }
        return nil
    }

    private static func countStops(in stations: [String], to boarding: String, isAtoB: Bool) -> Int {
        guard let idx = stations.firstIndex(of: boarding) else { return 0 }
        return isAtoB ? idx : (stations.count - 1 - idx)
    }

    private static func nextTerminalDeparture(schedule: RouteSchedule, isAtoB: Bool, offsetMinutes: Int, at now: Date) -> Int {
        let nowMin = nowMinutes(at: now)
        let isWd = isWeekday(date: now)
        let firstTrain = isAtoB
            ? (isWd ? schedule.firstFromA_wd : schedule.firstFromA_sat)
            : (isWd ? schedule.firstFromB_wd : schedule.firstFromB_sat)
        let headways = isWd ? schedule.weekdayHeadways : schedule.weekendHeadways
        let target = nowMin - offsetMinutes
        var t = firstTrain
        while t < target && t < 1500 { t += headway(headways, at: t) }
        return t
    }

    private static func nowMinutes(at date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        let m = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        return (c.hour ?? 0) < 4 ? m + 1440 : m
    }

    private static func isWeekday(date: Date) -> Bool {
        let w = Calendar.current.component(.weekday, from: date)
        return w != 1 && w != 7
    }

    private static func headway(_ rules: [HeadwayRule], at minute: Int) -> Int {
        rules.first { minute >= $0.fromMinute && minute < $0.toMinute }?.everyMinutes ?? (rules.last?.everyMinutes ?? 10)
    }

    private static func minutesToDate(_ minutes: Int, relativeTo base: Date) -> Date {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: base)
        let m = minutes >= 1440 ? minutes - 1440 : minutes
        comps.hour = m / 60; comps.minute = m % 60; comps.second = 0
        let d = Calendar.current.date(from: comps) ?? base
        return minutes >= 1440 ? Calendar.current.date(byAdding: .day, value: 1, to: d) ?? d : d
    }

    private static func avgHeadway(for segment: JourneySegment, at date: Date) -> Int {
        guard let (schedule, _, _) = findScheduleAndRoute(for: segment) else { return 6 }
        let rules = isWeekday(date: date) ? schedule.weekdayHeadways : schedule.weekendHeadways
        return headway(rules, at: nowMinutes(at: date))
    }

    private static func scheduleSecsPerStop(for segment: JourneySegment) -> Int {
        findScheduleAndRoute(for: segment)?.0.secsPerStop ?? 120
    }
}
