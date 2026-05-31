import Foundation

// MARK: - Kakao API 설정
// 키는 `KORA/Config/Secrets.xcconfig`에 정의하면 빌드 시 Info.plist로
// 주입됩니다. 자세한 안내는 `Secrets.sample.xcconfig`를 보세요.

enum KakaoConfig {
    static var restAPIKey: String {
        Bundle.main.object(forInfoDictionaryKey: "KakaoRestAPIKey") as? String ?? ""
    }
}
