import Foundation

// MARK: - 서울 열린데이터광장 (실시간 지하철 도착) API 설정
// 키는 `KORA/Config/Secrets.xcconfig`의 SEOUL_OPEN_API_KEY 에 정의하면 빌드 시
// Info.plist(SeoulOpenApiKey)로 주입됩니다. 키가 없으면 실시간 보정은
// 조용히 비활성화되고 GPS/가속도계/시간 기반 추정으로 폴백합니다.

enum SeoulTransitConfig {
    static var openApiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "SeoulOpenApiKey") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 실시간 보정 사용 가능 여부 (키가 주입되어 있고 플레이스홀더가 아닐 때).
    static var isRealtimeAvailable: Bool {
        let k = openApiKey
        return !k.isEmpty && k != "YOUR_SEOUL_OPEN_API_KEY"
    }
}
