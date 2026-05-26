import Foundation

struct RealtimeArrivalInfo: Identifiable {
    let id = UUID()
    let lineNumber: Int
    let direction: String   // "성수행 - 외선순환"
    let message: String     // "2분 후 [강남]"
    let statusCode: Int     // 0=진입,1=도착,2=출발,3=전역출발,4=전전역출발

    var minutesUntilArrival: Int? {
        if let m = message.range(of: #"(\d+)분 후"#, options: .regularExpression) {
            return Int(message[m].replacingOccurrences(of: "분 후", with: "").trimmingCharacters(in: .whitespaces))
        }
        if message.contains("도착") || message.contains("진입") { return 0 }
        if message.contains("전역출발") || message.contains("전역 출발") { return 2 }
        if message.contains("전전역") { return 4 }
        return nil
    }
}

enum RealtimeArrivalService {

    private struct APIResponse: Decodable {
        let realtimeArrivalList: [Item]?
        struct Item: Decodable {
            let subwayId: String?
            let trainLineNm: String?
            let arvlCd: String?
            let arvlMsg2: String?
        }
    }

    enum FetchError: Error { case missingKey, badResponse }

    static func fetch(station: String, lineNumber: Int, apiKey: String) async throws -> [RealtimeArrivalInfo] {
        let key = apiKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { throw FetchError.missingKey }
        let name = station.hasSuffix("역") ? String(station.dropLast()) : station
        let raw = "https://swopenAPI.seoul.go.kr/api/subway/\(key)/json/realtimeStationArrival/0/10/\(name)"
        guard let encoded = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else { throw FetchError.missingKey }
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw FetchError.badResponse }
        let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
        let lineId = "100\(lineNumber)"
        return (decoded.realtimeArrivalList ?? [])
            .filter { $0.subwayId == lineId }
            .compactMap { item -> RealtimeArrivalInfo? in
                guard let msg = item.arvlMsg2 else { return nil }
                return RealtimeArrivalInfo(
                    lineNumber: lineNumber,
                    direction: item.trainLineNm ?? "",
                    message: msg,
                    statusCode: Int(item.arvlCd ?? "99") ?? 99
                )
            }
    }
}
