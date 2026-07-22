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

    /// 活動日常駐：當天第一場任務前多久就開始顯示 Live Activity。
    static let dayPreLead: TimeInterval = 60 * 60

    private static var taipeiCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Taipei")!
        return cal
    }

    /// 這位人員此刻是否該顯示 Live Activity。
    /// 「活動日常駐」：正在進行中，或處於當天值勤窗（第一場前 `dayPreLead` ～ 最後一場結束）內；
    /// 當天值勤窗包含任務之間的空檔，所以整個活動日都會常駐，收工後才消失。
    static func hasActiveWork(person: String?, schedule: OfflineSchedule, now: Date) -> Bool {
        guard let person else { return false }
        let blocks = BlockBuilder.blocks(for: person, in: schedule.schedule)
        guard !blocks.isEmpty else { return false }

        // 進行中一定顯示
        if blocks.contains(where: { $0.startDate <= now && now < $0.endDate }) { return true }

        // 當天（Asia/Taipei）的整段值勤窗
        let cal = taipeiCalendar
        let todays = blocks.filter { cal.isDate($0.startDate, inSameDayAs: now) }
        guard let firstStart = todays.map(\.startDate).min(),
              let lastEnd = todays.map(\.endDate).max() else { return false }

        return now >= firstStart.addingTimeInterval(-dayPreLead) && now < lastEnd
    }
}
