import Foundation

struct OdsayExitInfo {
    let exitNo: String       // "4"
    let stationName: String  // Korean station name at destination
    let walkMinutes: Int?    // walk time from exit to final destination
}

final class OdsayTransitService {
    /// Read from Info.plist (injected from Secrets.xcconfig at build time).
    private var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "OdsayAPIKey") as? String ?? ""
    }
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

        debugLog("[Odsay] URL: \(url)")
        let (data, _) = try await session.data(from: url)
        debugLog("[Odsay] raw: \(String(data: data, encoding: .utf8) ?? "nil")")

        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            debugLog("[Odsay] JSON parse failed")
            return nil
        }

        // Surface API-level errors
        if let errors = root["error"] as? [[String: Any]], let first = errors.first {
            debugLog("[Odsay] API error: \(first["message"] ?? first)")
            return nil
        }

        guard let result = root["result"] as? [String: Any],
              let paths = result["path"] as? [[String: Any]],
              !paths.isEmpty else {
            debugLog("[Odsay] No paths in response: \(root.keys.joined(separator: ", "))")
            return nil
        }

        // Prefer the first path that actually uses subway. Odsay sometimes
        // ranks a faster bus-only option (pathType 2) above a subway path
        // (pathType 1) or mixed (pathType 3); for the Subway tab we only
        // care about subway paths since that's what the user is taking.
        let chosenPath: [String: Any] = {
            if let subwayPath = paths.first(where: { p in
                let t = p["pathType"] as? Int ?? 0
                return t == 1 || t == 3
            }) { return subwayPath }
            return paths[0]
        }()
        let info = chosenPath["info"] as? [String: Any]
        let subPaths = chosenPath["subPath"] as? [[String: Any]] ?? []

        debugLog("[Odsay] chosen pathType=\(chosenPath["pathType"] ?? "?"), subPaths=\(subPaths.count)")
        debugLog("[Odsay] info: exNo=\(info?["exNo"] ?? "nil"), exName=\(info?["exName"] ?? "nil")")

        // Prefer the last subway segment's `endExitNo` — that's the actual
        // alighting exit at the destination station, picked by Odsay using
        // the place coords we passed as `EY/EX`. The path-level `info.exNo`
        // is sometimes empty when the journey doesn't end on subway.
        let lastSubway = subPaths.last(where: { ($0["trafficType"] as? Int) == 1 })

        let exNo: String = {
            if let s = lastSubway?["endExitNo"] as? String,
               !s.trimmingCharacters(in: .whitespaces).isEmpty {
                return s.trimmingCharacters(in: .whitespaces)
            }
            if let n = lastSubway?["endExitNo"] as? Int, n > 0 { return "\(n)" }
            // Path-level fallback
            if let s = info?["exNo"] as? String,
               !s.trimmingCharacters(in: .whitespaces).isEmpty {
                return s.trimmingCharacters(in: .whitespaces)
            }
            if let n = info?["exNo"] as? Int, n > 0 { return "\(n)" }
            return ""
        }()

        let exName: String = {
            if let s = lastSubway?["endName"] as? String, !s.isEmpty { return s }
            if let s = info?["exName"] as? String, !s.isEmpty { return s }
            return ""
        }()

        debugLog("[Odsay] resolved exNo=\(exNo), exName=\(exName)")

        guard !exNo.isEmpty else { return nil }

        // Walk time: last subPath with trafficType == 3 (walk)
        let walkMins = subPaths.last.flatMap { sp -> Int? in
            guard (sp["trafficType"] as? Int) == 3 else { return nil }
            return sp["sectionTime"] as? Int
        }

        return OdsayExitInfo(exitNo: exNo, stationName: exName, walkMinutes: walkMins)
    }
}
