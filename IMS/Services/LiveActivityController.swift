import Foundation
import ActivityKit

/// 管理 Live Activity 的生命週期：活動期間（有當下或未來任務時）啟動並更新，
/// 沒有任務或換人時結束。App 進前景與資料更新時呼叫 `sync`。
@MainActor
enum LiveActivityController {

    static func sync(person: String?, schedule: OfflineSchedule, now: Date = Date()) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let existing = Activity<MissionActivityAttributes>.activities

        guard let person,
              MissionActivityState.hasActiveWork(person: person, schedule: schedule, now: now),
              let slot = MissionActivityState.currentSlot(person: person, schedule: schedule, now: now)
        else {
            Task { for activity in existing { await activity.end(nil, dismissalPolicy: .immediate) } }
            return
        }

        let state = MissionActivityState.make(from: slot)
        let content = ActivityContent(state: state, staleDate: slot.current?.endDate)

        if let activity = existing.first(where: { $0.attributes.person == person }) {
            Task { await activity.update(content) }
            // 換人殘留的舊 activity 收掉
            for other in existing where other.attributes.person != person {
                Task { await other.end(nil, dismissalPolicy: .immediate) }
            }
        } else {
            // 先結束其他人的殘留，再啟動這位
            for other in existing { Task { await other.end(nil, dismissalPolicy: .immediate) } }
            _ = try? Activity.request(
                attributes: MissionActivityAttributes(person: person),
                content: content,
                pushType: nil
            )
        }
    }

    static func endAll() {
        Task {
            for activity in Activity<MissionActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    #if DEBUG
    /// 截圖／預覽用：立刻啟動一個示範 Live Activity（不依賴活動日期）。
    static func startSample() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        for activity in Activity<MissionActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
        let state = MissionActivityAttributes.ContentState(
            focusRole: "外場負責人",
            focusTimeLabel: "16:00–17:30",
            focusDuty: "外場動線與人力調度。",
            isCurrent: true,
            focusStartDate: Date().addingTimeInterval(-5 * 60),
            focusEndDate: Date().addingTimeInterval(25 * 60),
            endPending: false,
            upNext: "便當發放 · 17:30"
        )
        _ = try? Activity.request(
            attributes: MissionActivityAttributes(person: "DinDin"),
            content: ActivityContent(state: state, staleDate: nil),
            pushType: nil
        )
    }
    #endif
}
