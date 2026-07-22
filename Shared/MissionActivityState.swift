import Foundation

/// 由目前的 timeline slot 組出 Live Activity 的 ContentState。
enum MissionActivityState {

    static func make(from slot: MissionSlot) -> MissionActivityAttributes.ContentState {
        if let cur = slot.current {
            return MissionActivityAttributes.ContentState(
                focusRole: cur.role,
                focusTimeLabel: timeLabel(cur),
                focusDuty: dutyLine(cur),
                isCurrent: true,
                focusStartDate: cur.startDate,
                focusEndDate: cur.endPending ? nil : cur.endDate,
                endPending: cur.endPending,
                upNext: slot.next.map { "\($0.role) · \($0.start)" }
            )
        } else if let nxt = slot.next {
            return MissionActivityAttributes.ContentState(
                focusRole: nxt.role,
                focusTimeLabel: timeLabel(nxt),
                focusDuty: dutyLine(nxt),
                isCurrent: false,
                focusStartDate: nxt.startDate,
                focusEndDate: nil,
                endPending: nxt.endPending,
                upNext: nil
            )
        } else {
            return MissionActivityAttributes.ContentState(
                focusRole: nil, focusTimeLabel: nil, focusDuty: nil,
                isCurrent: false, focusStartDate: nil, focusEndDate: nil,
                endPending: false, upNext: nil
            )
        }
    }

    private static func timeLabel(_ b: TaskBlock) -> String {
        b.endPending ? "\(b.start) 開始" : "\(b.start)–\(b.end)"
    }

    private static func dutyLine(_ b: TaskBlock) -> String {
        b.duty.isEmpty ? (b.contents.first ?? "") : b.duty
    }

    /// 目前該顯示的 slot：最後一個 date <= now 的切片。
    static func currentSlot(person: String?, schedule: OfflineSchedule, now: Date) -> MissionSlot? {
        let slots = MissionTimeline.slots(person: person, schedule: schedule, now: now)
        return slots.last { $0.date <= now } ?? slots.first
    }

    /// 下一場任務在多久內才值得提前啟動 Live Activity（避免活動前好幾天就一直掛著）。
    static let lookahead: TimeInterval = 3 * 60 * 60

    /// 這位人員此刻是否值得顯示 Live Activity：正在進行中，或下一場即將開始。
    static func hasActiveWork(person: String?, schedule: OfflineSchedule, now: Date) -> Bool {
        guard let slot = currentSlot(person: person, schedule: schedule, now: now) else { return false }
        if slot.current != nil { return true }
        if let next = slot.next {
            return next.startDate.timeIntervalSince(now) <= lookahead
        }
        return false
    }
}
