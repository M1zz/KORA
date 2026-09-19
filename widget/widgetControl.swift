import AppIntents
import SwiftUI
import WidgetKit

/// Control Centre button that opens the subway navigator directly.
@available(iOS 18.0, *)
struct KoreaWayNavigatorControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.kora.leeo.widget.navigator",
            provider: Provider()
        ) { _ in
            ControlWidgetButton(action: OpenNavigatorIntent()) {
                Label("Subway directions", systemImage: "tram.fill")
            }
        }
        .displayName("Subway directions")
        .description("Open the subway navigator in one tap.")
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
    static let title: LocalizedStringResource = "Open subway directions"
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
