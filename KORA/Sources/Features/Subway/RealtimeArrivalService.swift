import Foundation

struct RealtimeArrivalInfo: Identifiable {
    let id = UUID()
    let lineNumber: Int
    let direction: String      // "성수행 - 외선순환" (trainLineNm)
    let message: String        // "2분 후 [강남]" (arvlMsg2)
    let locationStation: String // 열차의 현재 위치 역 (arvlMsg3)
    let terminusName: String   // 이 열차의 종착역 (bstatnNm) — 방향 매칭에 사용
    let trainNumber: String    // 열차 번호 (btrainNo) — 열차 식별에 사용
    let statusCode: Int        // 0=진입,1=도착,2=출발,3=전역출발,4=전전역출발,5=전역진입,99=운행중

    var minutesUntilArrival: Int? {
        if let m = message.range(of: #"(\d+)분 후"#, options: .regularExpression) {
            return Int(message[m].replacingOccurrences(of: "분 후", with: "").trimmingCharacters(in: .whitespaces))
        }
        if message.contains("도착") || message.contains("진입") { return 0 }
        if message.contains("전역출발") || message.contains("전역 출발") { return 2 }
        if message.contains("전전역") { return 4 }
        return nil
    }

    /// 이 열차가 조회한 역에 이미 도착했거나 진입 중인지 (정차 확정 신호).
    var isAtStation: Bool { statusCode == 0 || statusCode == 1 }

    /// 이 열차가 조회한 역의 직전/직전전 역을 출발해 접근 중인지 (출발 신호).
    var isApproaching: Bool { statusCode == 2 || statusCode == 3 || statusCode == 4 }
}

enum RealtimeArrivalService {

    private struct APIResponse: Decodable {
        let realtimeArrivalList: [Item]?
        struct Item: Decodable {
            let subwayId: String?
            let trainLineNm: String?
            let arvlCd: String?
            let arvlMsg2: String?
            let arvlMsg3: String?
            let bstatnNm: String?
            let btrainNo: String?
        }
    }

    enum FetchError: Error { case missingKey, badResponse }

    /// 앱 내부 노선 번호 → 서울 열린데이터 `subwayId` 매핑.
    /// 1~9호선은 100N, 광역/민자 노선은 공식 코드. 미지원 노선은 nil → 매칭 없음(폴백).
    static func seoulSubwayId(for lineNumber: Int) -> String? {
        switch lineNumber {
        case 1...9: return "100\(lineNumber)"
        case 10:    return "1065"   // 공항철도 (AREX)
        case 11:    return "1077"   // 신분당선
        case 12:    return "1075"   // 수인분당선
        case 13:    return "1063"   // 경의중앙선
        case 14:    return "1032"   // GTX-A
        case 15:    return "1067"   // 경춘선
        case 16:    return "1081"   // 경강선
        case 17:    return "1093"   // 서해선
        case 19:    return "1091"   // 신림선
        case 20:    return "1092"   // 우이신설선
        // 김포골드라인·의정부경전철·에버라인·인천 1/2호선과 지방 노선은
        // 서울 열린데이터 API 미지원 → nil (자동 폴백).
        default:    return nil
        }
    }

    /// 서울 열린데이터 API가 쓰는 역명. 앱 내부에서 동명이역 구분용으로 붙인
    /// 괄호 표기("양평(서울)", "신촌(경의중앙)")를 벗겨 실제 역명으로 되돌린다.
    static func apiStationName(_ station: String) -> String {
        let base = station.hasSuffix("역") ? String(station.dropLast()) : station
        guard let parenIdx = base.firstIndex(of: "(") else { return base }
        return String(base[..<parenIdx])
    }

    /// 서울 열린데이터광장 실시간 도착 API. `apiKey` 미지정 시 설정(Secrets)에서 읽습니다.
    static func fetch(
        station: String,
        lineNumber: Int,
        apiKey: String = SeoulTransitConfig.openApiKey
    ) async throws -> [RealtimeArrivalInfo] {
        let key = apiKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty, key != "YOUR_SEOUL_OPEN_API_KEY" else { throw FetchError.missingKey }
        let name = apiStationName(station)
        let raw = "https://swopenAPI.seoul.go.kr/api/subway/\(key)/json/realtimeStationArrival/0/15/\(name)"
        guard let encoded = raw.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else { throw FetchError.missingKey }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        let (data, resp) = try await URLSession.shared.data(for: request)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else { throw FetchError.badResponse }
        let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
        // 미지원 노선이면 다른 노선 열차 오인 매칭을 피하려 빈 결과로 폴백.
        guard let lineId = seoulSubwayId(for: lineNumber) else { return [] }
        return (decoded.realtimeArrivalList ?? [])
            .filter { $0.subwayId == lineId }
            .compactMap { item -> RealtimeArrivalInfo? in
                guard let msg = item.arvlMsg2 else { return nil }
                return RealtimeArrivalInfo(
                    lineNumber: lineNumber,
                    direction: item.trainLineNm ?? "",
                    message: msg,
                    locationStation: item.arvlMsg3 ?? "",
                    terminusName: item.bstatnNm ?? "",
                    trainNumber: item.btrainNo ?? "",
                    statusCode: Int(item.arvlCd ?? "99") ?? 99
                )
            }
    }

    // MARK: - 출발·정차 동기화용 확정 신호

    enum StopConfirmation {
        /// 우리 방향 열차가 다음 역에 도착/진입함 → 한 정거장 진행 확정.
        case arrivedAtNext(trainNumber: String)
        /// 우리 방향 열차가 다음 역으로 접근 중 (직전역 출발 등) → 곧 정차.
        case approachingNext(trainNumber: String)
        /// 일치하는 열차 없음 / 데이터 부족.
        case none
    }

    /// `nextStation`(현재 다음 정거장) 기준으로 우리가 가는 방향(`terminus`)과 일치하는
    /// 열차의 상태를 반환합니다. 종착역(`terminus`) 또는 순환 방향 문자열로 방향을 매칭합니다.
    static func nextStopConfirmation(
        lineNumber: Int,
        nextStation: String,
        terminus: String,
        apiKey: String = SeoulTransitConfig.openApiKey
    ) async -> StopConfirmation {
        guard let arrivals = try? await fetch(station: nextStation, lineNumber: lineNumber, apiKey: apiKey),
              !arrivals.isEmpty else { return .none }

        let bareTerminus = terminus.hasSuffix("역") ? String(terminus.dropLast()) : terminus
        let matches = arrivals.filter { info in
            // 종착역 일치(가장 신뢰) 또는 trainLineNm/순환 문자열 일치로 방향 판별.
            info.terminusName.contains(bareTerminus)
                || info.direction.contains(bareTerminus)
                || (terminus.contains("순환") && info.direction.contains(terminus))
        }
        guard !matches.isEmpty else { return .none }

        if let arrived = matches.first(where: { $0.isAtStation }) {
            return .arrivedAtNext(trainNumber: arrived.trainNumber)
        }
        if let approaching = matches.first(where: { $0.isApproaching }) {
            return .approachingNext(trainNumber: approaching.trainNumber)
        }
        return .none
    }
}
