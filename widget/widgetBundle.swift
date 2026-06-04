import WidgetKit
import SwiftUI

@main
struct KoreaWayWidgetBundle: WidgetBundle {
    var body: some Widget {
        KoreaWayWidget()
        if #available(iOS 18.0, *) {
            KoreaWayNavigatorControl()
        }
        widgetLiveActivity()
    }
}
