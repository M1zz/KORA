import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct KoreaNaviLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var currentStation: String
        var nextStation: String
        var stopsRemaining: Int
        var lineColorHex: String
        var lineName: String
    }

    var destinationStation: String
    /// Localized unit under the stop count ("정거장", "stops" …). Station and
    /// line names arrive already localized in the app's display language.
    var stopsUnit: String
    /// 남은 정거장 수마다의 낱말 (칸 번호 = 남은 수). 아랍어 · 러시아어처럼 수에 따라 바뀌는 말을 맞게 쓴다.
    /// 없으면(옛 액티비티) `stopsUnit`.
    var stopsUnits: [String]? = nil

    func stopsUnit(for n: Int) -> String {
        guard let units = stopsUnits, units.indices.contains(n) else { return stopsUnit }
        return units[n]
    }
}
