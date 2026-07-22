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
                VStack(alignment: .trailing, spacing: 1) {
                    islandCountdown(state, font: .mono(16, .bold))
                    if state.focusRole != nil {
                        Text(state.isCurrent ? "剩餘" : "後開始")
                            .font(.mono(8)).foregroundStyle(Theme.ink3)
                    }
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
            islandCountdown(state, font: .mono(12, .bold))
        } minimal: {
            Circle().fill(Theme.accent).frame(width: 8, height: 8)
        }
    }

    /// 進行中→倒數到結束；下一場→倒數到開始。
    @ViewBuilder
    private func islandCountdown(_ state: MissionActivityAttributes.ContentState, font: Font) -> some View {
        if state.isCurrent, let end = state.focusEndDate, !state.endPending {
            Text(timerInterval: Date()...end, countsDown: true)
                .font(font).foregroundStyle(Theme.accent).monospacedDigit().frame(maxWidth: 52)
        } else if !state.isCurrent, let start = state.focusStartDate {
            Text(timerInterval: Date()...start, countsDown: true)
                .font(font).foregroundStyle(Theme.accent).monospacedDigit().frame(maxWidth: 52)
        }
    }
}
