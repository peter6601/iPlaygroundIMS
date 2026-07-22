import ActivityKit
import WidgetKit
import SwiftUI

/// 活動進行中的即時提示：鎖屏橫幅 + Dynamic Island，顯示當下任務與倒數。
struct MissionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MissionActivityAttributes.self) { context in
            LiveActivityLockScreenView(state: context.state)
                .padding(16)
                .activityBackgroundTint(Theme.bg)
                .activitySystemActionForegroundColor(Theme.accent)
        } dynamicIsland: { context in
            dynamicIsland(context.state)
        }
    }

    // MARK: - Dynamic Island

    private func dynamicIsland(_ state: MissionActivityAttributes.ContentState) -> DynamicIsland {
        DynamicIsland {
            DynamicIslandExpandedRegion(.leading) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.currentRole ?? state.nextRole ?? "無任務")
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.accent)
                        .lineLimit(1)
                    if let start = state.nextStartLabel, state.currentRole != nil {
                        Text("下一場 \(start)").font(.mono(10)).foregroundStyle(Theme.ink3).lineLimit(1)
                    }
                }
            }
            DynamicIslandExpandedRegion(.trailing) {
                if let end = state.currentEndDate, !state.endPending {
                    Text(timerInterval: Date()...end, countsDown: true)
                        .font(.mono(15, .bold)).foregroundStyle(Theme.accent)
                        .monospacedDigit().frame(maxWidth: 64)
                }
            }
        } compactLeading: {
            Circle().fill(Theme.accent).frame(width: 8, height: 8)
        } compactTrailing: {
            if let end = state.currentEndDate, !state.endPending {
                Text(timerInterval: Date()...end, countsDown: true)
                    .font(.mono(12, .bold)).foregroundStyle(Theme.accent)
                    .monospacedDigit().frame(maxWidth: 44)
            }
        } minimal: {
            Circle().fill(Theme.accent).frame(width: 8, height: 8)
        }
    }
}
