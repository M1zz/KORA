import Foundation
import CoreLocation

// MARK: - Models

struct SubwayExit: Decodable {
    let no: String          // "1", "2", "9-1", ...
    let lat: Double
    let lng: Double
}

struct SubwayExitDatabase: Decodable {
    let exits: [String: [SubwayExit]]
}

// MARK: - Service
// Offline nearest-exit lookup, replacing the Odsay-based exit guess. Loads
// a bundled JSON (parsed from OpenStreetMap `railway=subway_entrance` nodes
// + canonicalized to MetroLineData station keys) once on first use.

final class SubwayExitService {
    static let shared = SubwayExitService()

    private let db: SubwayExitDatabase
    private init() {
        if let url = Bundle.main.url(forResource: "SubwayExits", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(SubwayExitDatabase.self, from: data) {
            self.db = decoded
        } else {
            debugLog("[ExitService] SubwayExits.json missing or invalid — exit recommendations disabled")
            self.db = SubwayExitDatabase(exits: [:])
        }
    }

    /// Returns the exit closest to `place` from the given station's exits,
    /// or nil if the station isn't in the dataset or the place coordinate
    /// is too far for the answer to be meaningful (a sanity-check that
    /// guards against partially-mapped stations recommending a wildly
    /// off-side exit).
    func nearestExit(station: String, to place: Coordinate, maxMeters: Double = 1000) -> NearestExit? {
        guard let exits = db.exits[station], !exits.isEmpty else {
            debugLog("[Exit] '\(station)' not in dataset (\(db.exits.count) stations loaded)")
            return nil
        }
        let target = CLLocation(latitude: place.latitude, longitude: place.longitude)
        var bestExit: SubwayExit?
        var bestDist: Double = .infinity
        for ex in exits {
            let d = target.distance(from: CLLocation(latitude: ex.lat, longitude: ex.lng))
            if d < bestDist { bestDist = d; bestExit = ex }
        }
        guard let best = bestExit else { return nil }
        debugLog("[Exit] \(station) → place(\(place.latitude),\(place.longitude)): nearest=\(best.no), \(Int(bestDist))m")
        guard bestDist <= maxMeters else {
            debugLog("[Exit] DROPPED — \(Int(bestDist))m > \(Int(maxMeters))m threshold")
            return nil
        }
        let walkMinutes = max(1, Int(round(bestDist / 80)))
        return NearestExit(no: best.no, distanceMeters: Int(round(bestDist)), walkMinutes: walkMinutes)
    }
}

// MARK: - Result

struct NearestExit {
    let no: String
    let distanceMeters: Int
    let walkMinutes: Int
}
