import ActivityKit
import WidgetKit
import SwiftUI

/// 活動進行中的即時提示：鎖屏橫幅 + Dynamic Island，顯示當下任務與倒數。
struct MissionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MissionActivityAttributes.self) { context in
            lockScreen(context.state)
                .padding(16)
                .activityBackgroundTint(Theme.bg)
                .activitySystemActionForegroundColor(Theme.accent)
        } dynamicIsland: { context in
            dynamicIsland(context.state)
        }
    }

    // MARK: - 鎖屏橫幅

    private func lockScreen(_ state: MissionActivityAttributes.ContentState) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                if let role = state.currentRole {
                    Text("NOW").font(.mono(10, .heavy)).foregroundStyle(Theme.bg)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Theme.accent, in: Capsule())
                    Text(role).font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.ink)
                        .lineLimit(1)
                } else if let next = state.nextRole {
                    Text("NEXT").font(.mono(10, .heavy)).foregroundStyle(Theme.accent)
                    Text(next).font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.ink)
                        .lineLimit(1)
                } else {
                    Text("今日任務完成").font(.system(size: 16, weight: .semibold)).foregroundStyle(Theme.ink2)
                }
                if let next = state.nextRole, state.currentRole != nil,
                   let start = state.nextStartLabel {
                    Text("下一場 \(next) · \(start)").font(.mono(11)).foregroundStyle(Theme.ink3)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            trailingCountdown(state)
        }
    }

    @ViewBuilder
    private func trailingCountdown(_ state: MissionActivityAttributes.ContentState) -> some View {
        if let role = state.currentRole, role.isEmpty == false {
            VStack(alignment: .trailing, spacing: 2) {
                if state.endPending {
                    Text("結束待定").font(.mono(12)).foregroundStyle(Theme.ink2)
                } else if let end = state.currentEndDate {
                    Text(timerInterval: Date()...end, countsDown: true)
                        .font(.mono(20, .heavy)).foregroundStyle(Theme.accent)
                        .monospacedDigit().frame(maxWidth: 88)
                    Text("至 \(state.currentEndLabel ?? "")").font(.mono(10)).foregroundStyle(Theme.ink3)
                }
            }
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
