import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct KORALiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var currentStation: String
        var nextStation: String
        var stopsRemaining: Int
        var lineColorHex: String
        var lineName: String
    }

    var destinationStation: String
}
