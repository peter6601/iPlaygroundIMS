import WidgetKit
import SwiftUI

@main
struct IMSWidgetBundle: WidgetBundle {
    var body: some Widget {
        MissionWidget()
        MissionLiveActivity()
    }
}
