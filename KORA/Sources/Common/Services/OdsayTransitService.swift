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

        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("[Odsay] JSON parse failed")
            return nil
        }

        // Surface API-level errors
        if let errors = root["error"] as? [[String: Any]], let first = errors.first {
            print("[Odsay] API error: \(first["message"] ?? first)")
            return nil
        }

        guard let result = root["result"] as? [String: Any],
              let paths = result["path"] as? [[String: Any]],
              let firstPath = paths.first else {
            print("[Odsay] No paths in response: \(root.keys.joined(separator: ", "))")
            return nil
        }

        let info = firstPath["info"] as? [String: Any]
        let subPaths = firstPath["subPath"] as? [[String: Any]] ?? []

        print("[Odsay] info keys: \(info?.keys.sorted().joined(separator: ", ") ?? "nil")")
        print("[Odsay] info: exNo=\(info?["exNo"] ?? "nil"), exName=\(info?["exName"] ?? "nil")")

        // exNo can come back as String "4" or Int 4 — handle both
        let exNo: String = {
            if let s = info?["exNo"] as? String, !s.trimmingCharacters(in: .whitespaces).isEmpty {
                return s.trimmingCharacters(in: .whitespaces)
            }
            if let n = info?["exNo"] as? Int, n > 0 { return "\(n)" }
            // Fallback: last subway subPath's endExitNo
            let lastSubway = subPaths.last(where: { ($0["trafficType"] as? Int) == 1 })
            if let s = lastSubway?["endExitNo"] as? String, !s.isEmpty { return s }
            if let n = lastSubway?["endExitNo"] as? Int, n > 0 { return "\(n)" }
            return ""
        }()

        let exName: String = {
            if let s = info?["exName"] as? String, !s.isEmpty { return s }
            let lastSubway = subPaths.last(where: { ($0["trafficType"] as? Int) == 1 })
            return lastSubway?["endName"] as? String ?? ""
        }()

        print("[Odsay] resolved exNo=\(exNo), exName=\(exName)")

        guard !exNo.isEmpty else { return nil }

        // Walk time: last subPath with trafficType == 3 (walk)
        let walkMins = subPaths.last.flatMap { sp -> Int? in
            guard (sp["trafficType"] as? Int) == 3 else { return nil }
            return sp["sectionTime"] as? Int
        }

        return OdsayExitInfo(exitNo: exNo, stationName: exName, walkMinutes: walkMins)
    }
}
