import Foundation

struct OdsayExitInfo {
    let exitNo: String       // "4"
    let stationName: String  // Korean station name at destination
    let walkMinutes: Int?    // walk time from exit to final destination
}

final class OdsayTransitService {
    private let apiKey = "6SPMs6H1JkwUam4FLo2PJA"
    private let session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 10
        return URLSession(configuration: cfg)
    }()

    func fetchExitInfo(fromLat: Double, fromLon: Double,
                       toLat: Double, toLon: Double) async throws -> OdsayExitInfo? {
        var comps = URLComponents(string: "https://api.odsay.com/v1/api/searchPubTransPathT")!
        comps.queryItems = [
            .init(name: "SX", value: "\(fromLon)"),
            .init(name: "SY", value: "\(fromLat)"),
            .init(name: "EX", value: "\(toLon)"),
            .init(name: "EY", value: "\(toLat)"),
            .init(name: "apiKey", value: apiKey),
        ]
        guard let url = comps.url else { return nil }

        let (data, _) = try await session.data(from: url)
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = root["result"] as? [String: Any],
              let paths = result["path"] as? [[String: Any]],
              let firstPath = paths.first else { return nil }

        // info.exNo / info.exName — quickest exit hint from Odsay
        let info = firstPath["info"] as? [String: Any]
        let exNo   = (info?["exNo"]   as? String ?? "").trimmingCharacters(in: .whitespaces)
        let exName = (info?["exName"] as? String ?? "").trimmingCharacters(in: .whitespaces)

        guard !exNo.isEmpty else { return nil }

        // Walk time: last subPath segment with trafficType == 3 (walk)
        let subPaths = firstPath["subPath"] as? [[String: Any]] ?? []
        let walkMins = subPaths.last.flatMap { sp -> Int? in
            guard (sp["trafficType"] as? Int) == 3 else { return nil }
            return sp["sectionTime"] as? Int
        }

        return OdsayExitInfo(exitNo: exNo, stationName: exName, walkMinutes: walkMins)
    }
}
