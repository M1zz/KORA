import Foundation

// MARK: - Naver API 설정
// 키는 `KORA/Config/Secrets.xcconfig`에 정의하면 빌드 시 Info.plist로
// 주입됩니다. 자세한 안내는 `Secrets.sample.xcconfig`를 보세요.

enum NaverConfig {
    static var clientID: String {
        Bundle.main.object(forInfoDictionaryKey: "NaverClientID") as? String ?? ""
    }
    static var clientSecret: String {
        Bundle.main.object(forInfoDictionaryKey: "NaverClientSecret") as? String ?? ""
    }
}
