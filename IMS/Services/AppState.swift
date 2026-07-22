import Foundation
import Observation
import WidgetKit

/// App 的中央狀態：管理排班資料、選定人員，並在資料/選擇變動時
/// 重載 Widget timeline，以及（Task 6 起）重排本地通知。
@MainActor
@Observable
final class AppState {
    private(set) var schedule: OfflineSchedule = .empty
    private(set) var source: ScheduleService.Source = .bundle
    private(set) var lastFetched: Date? = SharedStore.lastFetched
    private(set) var isLoading = false

    var selectedPerson: String? = SharedStore.selectedPerson

    /// 可選擇的人員（活動工作人員名單）。
    var people: [String] { schedule.people }

    /// 目前選定人員的值勤區塊。
    var selectedBlocks: [TaskBlock] {
        guard let selectedPerson else { return [] }
        return BlockBuilder.blocks(for: selectedPerson, in: schedule.schedule)
    }

    /// 目前選定人員的支線任務。
    var selectedMissions: [SideMission] {
        guard let selectedPerson else { return [] }
        return schedule.sideMissions.filter { $0.person == selectedPerson }
    }

    /// 抓取最新排班（遠端 → cache → bundle），更新 UI、Widget 與通知。
    func refresh() async {
        isLoading = true
        let result = await ScheduleService.load()
        schedule = result.schedule
        source = result.source
        lastFetched = SharedStore.lastFetched
        isLoading = false

        WidgetCenter.shared.reloadAllTimelines()
        await rescheduleNotifications()
    }

    func select(_ person: String) {
        guard people.contains(person) else { return }
        selectedPerson = person
        SharedStore.selectedPerson = person
        WidgetCenter.shared.reloadAllTimelines()
        Task { await rescheduleNotifications() }
    }

    func clearSelection() {
        selectedPerson = nil
        SharedStore.selectedPerson = nil
        WidgetCenter.shared.reloadAllTimelines()
        Task { await rescheduleNotifications() }
    }

    /// 依目前選定人員重排通知。Task 6 接上 NotificationScheduler。
    private func rescheduleNotifications() async {
        await NotificationScheduler.shared.reschedule(blocks: selectedBlocks)
    }
}
