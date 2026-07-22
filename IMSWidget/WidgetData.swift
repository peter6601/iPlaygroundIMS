import Foundation

/// Widget 端的資料來源：優先讀 App Group 已解析快照（App 寫入），
/// 退回 widget bundle 內建快照。完全不執行 JavaScript。
enum WidgetData {

    static func loadSchedule() -> OfflineSchedule {
        if let snapshot = SharedStore.readSnapshot() { return snapshot }
        if let bundled = loadBundledSnapshot() { return bundled }
        return .empty
    }

    private static func loadBundledSnapshot() -> OfflineSchedule? {
        guard let url = Bundle.main.url(forResource: "snapshot.bundle", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(OfflineSchedule.self, from: data)
    }

    /// 產生 timeline entries：在每個 block 邊界切換「當下 / 下一個」任務。
    static func entries(person: String?, schedule: OfflineSchedule, now: Date) -> [MissionEntry] {
        MissionTimeline.slots(person: person, schedule: schedule, now: now).map {
            MissionEntry(date: $0.date, person: person, current: $0.current, next: $0.next)
        }
    }
}
