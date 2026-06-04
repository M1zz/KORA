import AppIntents
import SwiftUI
import WidgetKit

/// Control Centre button that opens the KoreaWay subway navigator directly.
@available(iOS 18.0, *)
struct KoreaWayNavigatorControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.kora.leeo.widget.navigator",
            provider: Provider()
        ) { _ in
            ControlWidgetButton(action: OpenNavigatorIntent()) {
                Label("지하철 안내", systemImage: "tram.fill")
            }
        }
        .displayName("지하철 안내")
        .description("KoreaWay 지하철 네비게이터를 바로 엽니다.")
    }
}

@available(iOS 18.0, *)
extension KoreaWayNavigatorControl {
    struct Provider: ControlValueProvider {
        var previewValue: Bool { true }
        func currentValue() async throws -> Bool { true }
    }
}

struct OpenNavigatorIntent: AppIntent {
    static let title: LocalizedStringResource = "지하철 안내 열기"
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
