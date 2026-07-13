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
            RouteSchedule(lineNumber:1, terminusA:"연천", terminusB:"인천", isCircular:false,
                firstFromA_wd:322, firstFromA_sat:325, firstFromA_sun:330,
                firstFromB_wd:305, firstFromB_sat:310, firstFromB_sun:315, secsPerStop:135,
                weekdayHeadways:[h(300,390,10),h(390,540,5),h(540,1080,8),h(1080,1200,5),h(1200,1500,10)],
                weekendHeadways:[h(300,540,12),h(540,1320,8),h(1320,1500,12)]),
            RouteSchedule(lineNumber:1, terminusA:"연천", terminusB:"신창", isCircular:false,
                firstFromA_wd:325, firstFromA_sat:330, firstFromA_sun:335,
                firstFromB_wd:310, firstFromB_sat:315, firstFromB_sun:320, secsPerStop:140,
                weekdayHeadways:[h(300,390,12),h(390,540,6),h(540,1080,9),h(1080,1200,6),h(1200,1500,12)],
                weekendHeadways:[h(300,540,14),h(540,1320,9),h(1320,1500,14)]),
            RouteSchedule(lineNumber:1, terminusA:"병점", terminusB:"서동탄", isCircular:false,
                firstFromA_wd:340, firstFromA_sat:345, firstFromA_sun:350,
                firstFromB_wd:345, firstFromB_sat:350, firstFromB_sun:355, secsPerStop:120,
                weekdayHeadways:[h(300,1500,20)], weekendHeadways:[h(300,1500,25)]),
            // 광명셔틀 (금천구청↔광명, 출퇴근 위주 저빈도)
            RouteSchedule(lineNumber:1, terminusA:"금천구청", terminusB:"광명", isCircular:false,
                firstFromA_wd:345, firstFromA_sat:350, firstFromA_sun:355,
                firstFromB_wd:350, firstFromB_sat:355, firstFromB_sun:360, secsPerStop:150,
                weekdayHeadways:[h(300,1500,40)], weekendHeadways:[h(300,1500,60)]),
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
            // Line 4 (진접선 연장 반영: 진접 ↔ 오이도)
            RouteSchedule(lineNumber:4, terminusA:"진접", terminusB:"오이도", isCircular:false,
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
            RouteSchedule(lineNumber:6, terminusA:"신내", terminusB:"구산", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:335, firstFromA_sun:340,
                firstFromB_wd:337, firstFromB_sat:342, firstFromB_sun:347, secsPerStop:130,
                weekdayHeadways:[h(300,420,9),h(420,540,5),h(540,1080,8),h(1080,1200,5),h(1200,1500,10)],
                weekendHeadways:[h(300,540,11),h(540,1320,9),h(1320,1500,11)]),
            // Line 7
            RouteSchedule(lineNumber:7, terminusA:"장암", terminusB:"석남", isCircular:false,
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
            // Line 10 — 공항철도 (AREX). Longer inter-station distances, lower frequency.
            RouteSchedule(lineNumber:10, terminusA:"서울역", terminusB:"인천공항2터미널", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:335, firstFromA_sun:340,
                firstFromB_wd:330, firstFromB_sat:335, firstFromB_sun:340, secsPerStop:200,
                weekdayHeadways:[h(300,1500,10)],
                weekendHeadways:[h(300,1500,12)]),
            // Line 11 — 신분당선
            RouteSchedule(lineNumber:11, terminusA:"신사", terminusB:"광교", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:335, firstFromA_sun:340,
                firstFromB_wd:330, firstFromB_sat:335, firstFromB_sun:340, secsPerStop:90,
                weekdayHeadways:[h(300,390,6),h(390,540,4),h(540,1080,5),h(1080,1200,4),h(1200,1500,7)],
                weekendHeadways:[h(300,540,7),h(540,1320,5),h(1320,1500,8)]),
            // Line 12 — 수인분당선
            RouteSchedule(lineNumber:12, terminusA:"청량리", terminusB:"인천", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:335, firstFromA_sun:340,
                firstFromB_wd:330, firstFromB_sat:335, firstFromB_sun:340, secsPerStop:110,
                weekdayHeadways:[h(300,390,9),h(390,540,5),h(540,1080,7),h(1080,1200,5),h(1200,1500,10)],
                weekendHeadways:[h(300,540,10),h(540,1320,7),h(1320,1500,12)]),
            // Line 13 — 경의중앙선
            RouteSchedule(lineNumber:13, terminusA:"지평", terminusB:"문산", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:335, firstFromA_sun:340,
                firstFromB_wd:330, firstFromB_sat:335, firstFromB_sun:340, secsPerStop:180,
                weekdayHeadways:[h(300,390,12),h(390,540,7),h(540,1080,10),h(1080,1200,7),h(1200,1500,14)],
                weekendHeadways:[h(300,540,15),h(540,1320,10),h(1320,1500,18)]),
            // Line 13 — 경의선 서울역 착발 계통 (저빈도)
            RouteSchedule(lineNumber:13, terminusA:"서울역", terminusB:"문산", isCircular:false,
                firstFromA_wd:350, firstFromA_sat:355, firstFromA_sun:360,
                firstFromB_wd:340, firstFromB_sat:345, firstFromB_sun:350, secsPerStop:180,
                weekdayHeadways:[h(300,1500,60)], weekendHeadways:[h(300,1500,80)]),
            // Line 14 — GTX-A (역간 거리가 길어 secsPerStop이 큼)
            RouteSchedule(lineNumber:14, terminusA:"운정중앙", terminusB:"서울역", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:335, firstFromA_sun:340,
                firstFromB_wd:332, firstFromB_sat:337, firstFromB_sun:342, secsPerStop:330,
                weekdayHeadways:[h(300,420,12),h(420,540,7),h(540,1080,10),h(1080,1200,7),h(1200,1440,15)],
                weekendHeadways:[h(300,540,15),h(540,1320,12),h(1320,1440,18)]),
            RouteSchedule(lineNumber:14, terminusA:"수서", terminusB:"동탄", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:335, firstFromA_sun:340,
                firstFromB_wd:320, firstFromB_sat:325, firstFromB_sun:330, secsPerStop:400,
                weekdayHeadways:[h(300,420,12),h(420,540,8),h(540,1080,12),h(1080,1200,8),h(1200,1440,17)],
                weekendHeadways:[h(300,540,15),h(540,1320,12),h(1320,1440,20)]),
            // Line 15 — 경춘선
            RouteSchedule(lineNumber:15, terminusA:"청량리", terminusB:"춘천", isCircular:false,
                firstFromA_wd:310, firstFromA_sat:315, firstFromA_sun:320,
                firstFromB_wd:300, firstFromB_sat:305, firstFromB_sun:310, secsPerStop:150,
                weekdayHeadways:[h(300,540,12),h(540,1080,20),h(1080,1200,12),h(1200,1440,25)],
                weekendHeadways:[h(300,1440,20)]),
            // Line 16 — 경강선
            RouteSchedule(lineNumber:16, terminusA:"판교", terminusB:"여주", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:335, firstFromA_sun:340,
                firstFromB_wd:330, firstFromB_sat:335, firstFromB_sun:340, secsPerStop:160,
                weekdayHeadways:[h(300,540,12),h(540,1080,17),h(1080,1200,12),h(1200,1440,20)],
                weekendHeadways:[h(300,1440,17)]),
            // Line 17 — 서해선
            RouteSchedule(lineNumber:17, terminusA:"일산", terminusB:"원시", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:335, firstFromA_sun:340,
                firstFromB_wd:330, firstFromB_sat:335, firstFromB_sun:340, secsPerStop:130,
                weekdayHeadways:[h(300,540,9),h(540,1080,14),h(1080,1200,9),h(1200,1440,17)],
                weekendHeadways:[h(300,1440,14)]),
            // Line 18~22 — 수도권 경전철
            RouteSchedule(lineNumber:18, terminusA:"양촌", terminusB:"김포공항", isCircular:false,
                firstFromA_wd:326, firstFromA_sat:326, firstFromA_sun:330,
                firstFromB_wd:330, firstFromB_sat:330, firstFromB_sun:334, secsPerStop:110,
                weekdayHeadways:[h(300,540,3),h(540,1080,6),h(1080,1200,3),h(1200,1470,8)],
                weekendHeadways:[h(300,1440,7)]),
            RouteSchedule(lineNumber:19, terminusA:"샛강", terminusB:"관악산", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:330, firstFromA_sun:334,
                firstFromB_wd:330, firstFromB_sat:330, firstFromB_sun:334, secsPerStop:90,
                weekdayHeadways:[h(300,540,4),h(540,1080,8),h(1080,1200,4),h(1200,1480,10)],
                weekendHeadways:[h(300,1440,8)]),
            RouteSchedule(lineNumber:20, terminusA:"북한산우이", terminusB:"신설동", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:330, firstFromA_sun:334,
                firstFromB_wd:330, firstFromB_sat:330, firstFromB_sun:334, secsPerStop:90,
                weekdayHeadways:[h(300,540,3),h(540,1080,7),h(1080,1200,3),h(1200,1470,9)],
                weekendHeadways:[h(300,1440,8)]),
            RouteSchedule(lineNumber:21, terminusA:"발곡", terminusB:"탑석", isCircular:false,
                firstFromA_wd:300, firstFromA_sat:300, firstFromA_sun:304,
                firstFromB_wd:300, firstFromB_sat:300, firstFromB_sun:304, secsPerStop:80,
                weekdayHeadways:[h(300,540,4),h(540,1080,6),h(1080,1200,4),h(1200,1450,8)],
                weekendHeadways:[h(300,1440,7)]),
            RouteSchedule(lineNumber:22, terminusA:"기흥", terminusB:"전대·에버랜드", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:330, firstFromA_sun:334,
                firstFromB_wd:330, firstFromB_sat:330, firstFromB_sun:334, secsPerStop:100,
                weekdayHeadways:[h(300,540,3),h(540,1080,6),h(1080,1200,4),h(1200,1410,10)],
                weekendHeadways:[h(300,1410,8)]),
            // Line 23·24 — 인천 1·2호선
            RouteSchedule(lineNumber:23, terminusA:"검단호수공원", terminusB:"송도달빛축제공원", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:330, firstFromA_sun:334,
                firstFromB_wd:330, firstFromB_sat:330, firstFromB_sun:334, secsPerStop:110,
                weekdayHeadways:[h(300,540,5),h(540,1080,9),h(1080,1200,5),h(1200,1470,11)],
                weekendHeadways:[h(300,1440,9)]),
            RouteSchedule(lineNumber:24, terminusA:"검단오류", terminusB:"운연", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:330, firstFromA_sun:334,
                firstFromB_wd:330, firstFromB_sat:330, firstFromB_sun:334, secsPerStop:100,
                weekdayHeadways:[h(300,540,3),h(540,1080,6),h(1080,1200,3),h(1200,1470,8)],
                weekendHeadways:[h(300,1440,7)]),
            // ── 부산권 ──────────────────────────────────────────────
            RouteSchedule(lineNumber:31, terminusA:"다대포해수욕장", terminusB:"노포", isCircular:false,
                firstFromA_wd:305, firstFromA_sat:305, firstFromA_sun:310,
                firstFromB_wd:305, firstFromB_sat:305, firstFromB_sun:310, secsPerStop:110,
                weekdayHeadways:[h(300,540,5),h(540,1080,7),h(1080,1200,5),h(1200,1440,9)],
                weekendHeadways:[h(300,1440,8)]),
            RouteSchedule(lineNumber:32, terminusA:"장산", terminusB:"양산", isCircular:false,
                firstFromA_wd:300, firstFromA_sat:300, firstFromA_sun:305,
                firstFromB_wd:300, firstFromB_sat:300, firstFromB_sun:305, secsPerStop:110,
                weekdayHeadways:[h(300,540,5),h(540,1080,7),h(1080,1200,5),h(1200,1440,9)],
                weekendHeadways:[h(300,1440,8)]),
            RouteSchedule(lineNumber:33, terminusA:"수영", terminusB:"대저", isCircular:false,
                firstFromA_wd:320, firstFromA_sat:320, firstFromA_sun:325,
                firstFromB_wd:316, firstFromB_sat:316, firstFromB_sun:320, secsPerStop:110,
                weekdayHeadways:[h(300,540,5),h(540,1080,7),h(1080,1200,5),h(1200,1440,9)],
                weekendHeadways:[h(300,1440,8)]),
            RouteSchedule(lineNumber:34, terminusA:"미남", terminusB:"안평", isCircular:false,
                firstFromA_wd:305, firstFromA_sat:305, firstFromA_sun:310,
                firstFromB_wd:305, firstFromB_sat:305, firstFromB_sun:310, secsPerStop:100,
                weekdayHeadways:[h(300,540,5),h(540,1080,8),h(1080,1200,5),h(1200,1440,10)],
                weekendHeadways:[h(300,1440,9)]),
            RouteSchedule(lineNumber:35, terminusA:"사상", terminusB:"가야대", isCircular:false,
                firstFromA_wd:300, firstFromA_sat:300, firstFromA_sun:305,
                firstFromB_wd:300, firstFromB_sat:300, firstFromB_sun:305, secsPerStop:100,
                weekdayHeadways:[h(300,540,6),h(540,1080,11),h(1080,1200,6),h(1200,1440,13)],
                weekendHeadways:[h(300,1440,11)]),
            RouteSchedule(lineNumber:36, terminusA:"부전(동해선)", terminusB:"태화강", isCircular:false,
                firstFromA_wd:333, firstFromA_sat:333, firstFromA_sun:338,
                firstFromB_wd:330, firstFromB_sat:330, firstFromB_sun:335, secsPerStop:180,
                weekdayHeadways:[h(300,540,15),h(540,1080,27),h(1080,1200,15),h(1200,1440,30)],
                weekendHeadways:[h(300,1440,27)]),
            // ── 대구권 ──────────────────────────────────────────────
            RouteSchedule(lineNumber:41, terminusA:"설화명곡", terminusB:"하양", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:330, firstFromA_sun:335,
                firstFromB_wd:330, firstFromB_sat:330, firstFromB_sun:335, secsPerStop:110,
                weekdayHeadways:[h(300,540,5),h(540,1080,8),h(1080,1200,5),h(1200,1440,10)],
                weekendHeadways:[h(300,1440,9)]),
            RouteSchedule(lineNumber:42, terminusA:"문양", terminusB:"영남대", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:330, firstFromA_sun:335,
                firstFromB_wd:330, firstFromB_sat:330, firstFromB_sun:335, secsPerStop:110,
                weekdayHeadways:[h(300,540,5),h(540,1080,8),h(1080,1200,5),h(1200,1440,10)],
                weekendHeadways:[h(300,1440,9)]),
            RouteSchedule(lineNumber:43, terminusA:"칠곡경대병원", terminusB:"용지", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:330, firstFromA_sun:335,
                firstFromB_wd:330, firstFromB_sat:330, firstFromB_sun:335, secsPerStop:100,
                weekdayHeadways:[h(300,540,5),h(540,1080,7),h(1080,1200,5),h(1200,1440,9)],
                weekendHeadways:[h(300,1440,8)]),
            RouteSchedule(lineNumber:44, terminusA:"구미", terminusB:"경산", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:330, firstFromA_sun:335,
                firstFromB_wd:330, firstFromB_sat:330, firstFromB_sun:335, secsPerStop:300,
                weekdayHeadways:[h(300,540,19),h(540,1080,25),h(1080,1200,19),h(1200,1440,30)],
                weekendHeadways:[h(300,1440,25)]),
            // ── 광주·대전 ───────────────────────────────────────────
            RouteSchedule(lineNumber:51, terminusA:"녹동", terminusB:"평동", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:330, firstFromA_sun:335,
                firstFromB_wd:330, firstFromB_sat:330, firstFromB_sun:335, secsPerStop:110,
                weekdayHeadways:[h(300,540,6),h(540,1080,10),h(1080,1200,6),h(1200,1440,12)],
                weekendHeadways:[h(300,1440,10)]),
            RouteSchedule(lineNumber:61, terminusA:"판암", terminusB:"반석", isCircular:false,
                firstFromA_wd:330, firstFromA_sat:330, firstFromA_sun:335,
                firstFromB_wd:330, firstFromB_sat:330, firstFromB_sun:335, secsPerStop:110,
                weekdayHeadways:[h(300,540,6),h(540,1080,9),h(1080,1200,6),h(1200,1440,11)],
                weekendHeadways:[h(300,1440,10)]),
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
