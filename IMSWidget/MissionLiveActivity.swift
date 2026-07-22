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
                    Text(state.isCurrent ? "NOW" : "NEXT")
                        .font(.mono(9, .heavy)).foregroundStyle(Theme.accent)
                    Text(state.focusRole ?? "今日完成")
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    if let time = state.focusTimeLabel {
                        Text(time).font(.mono(11)).foregroundStyle(Theme.accent).lineLimit(1)
                    }
                }
            }
            DynamicIslandExpandedRegion(.trailing) {
                if state.isCurrent, let end = state.focusEndDate, !state.endPending {
                    Text(timerInterval: Date()...end, countsDown: true)
                        .font(.mono(16, .bold)).foregroundStyle(Theme.accent)
                        .monospacedDigit().frame(maxWidth: 68)
                }
            }
            DynamicIslandExpandedRegion(.bottom) {
                if let duty = state.focusDuty, !duty.isEmpty {
                    Text(duty).font(.system(size: 12)).foregroundStyle(Theme.ink2).lineLimit(2)
                }
            }
        } compactLeading: {
            Circle().fill(Theme.accent).frame(width: 8, height: 8)
        } compactTrailing: {
            if state.isCurrent, let end = state.focusEndDate, !state.endPending {
                Text(timerInterval: Date()...end, countsDown: true)
                    .font(.mono(12, .bold)).foregroundStyle(Theme.accent)
                    .monospacedDigit().frame(maxWidth: 44)
            }
        } minimal: {
            Circle().fill(Theme.accent).frame(width: 8, height: 8)
        }
    }
}
