import Foundation

/// Widget timeline 的一個時間切片：在 `date` 這個時刻，當下與下一個任務是什麼。
struct MissionSlot: Equatable {
    let date: Date
    let current: TaskBlock?
    let next: TaskBlock?
}

/// 依 block 邊界產生 timeline 切片，讓 Widget 不需喚醒 App 就能自動切換內容。
enum MissionTimeline {
    static func slots(person: String?, schedule: OfflineSchedule, now: Date) -> [MissionSlot] {
        guard let person, !person.isEmpty else {
            return [MissionSlot(date: now, current: nil, next: nil)]
        }
        let blocks = BlockBuilder.blocks(for: person, in: schedule.schedule)
            .sorted { $0.startDate < $1.startDate }

        var boundaries: Set<Date> = [now]
        for b in blocks where b.endDate > now {
            if b.startDate > now { boundaries.insert(b.startDate) }
            boundaries.insert(b.endDate)
        }

        let slots = boundaries.sorted().map { date -> MissionSlot in
            let current = blocks.first { $0.startDate <= date && date < $0.endDate }
            let next = blocks.first { $0.startDate > date }
            return MissionSlot(date: date, current: current, next: next)
        }
        return slots.isEmpty ? [MissionSlot(date: now, current: nil, next: nil)] : slots
    }
}
