import Foundation

/// 由目前的 timeline slot 組出 Live Activity 的 ContentState。
enum MissionActivityState {

    static func make(from slot: MissionSlot) -> MissionActivityAttributes.ContentState {
        MissionActivityAttributes.ContentState(
            currentRole: slot.current?.role,
            currentEndDate: slot.current?.endDate,
            currentEndLabel: slot.current?.end,
            nextRole: slot.next?.role,
            nextStartLabel: slot.next.map { "\(dayShort($0.day)) \($0.start)" },
            endPending: slot.current?.endPending ?? false
        )
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

    private static func dayShort(_ day: String) -> String {
        switch day {
        case "D0": return "7/24"
        case "D1": return "7/25"
        case "D2": return "7/26"
        default: return day
        }
    }
}
