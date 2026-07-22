import Foundation
import Observation
import WidgetKit

/// App 的中央狀態：管理排班資料、選定人員，並在資料/選擇變動時
/// 重載 Widget timeline，以及重排本地通知。
@MainActor
@Observable
final class AppState {
    private(set) var schedule: OfflineSchedule = .empty
    private(set) var source: ScheduleService.Source = .bundle
    private(set) var lastFetched: Date? = SharedStore.lastFetched
    private(set) var isLoading = false
    private(set) var selectedPerson: String? = SharedStore.selectedPerson

    /// 各人員的值勤段數，於資料載入後預先算好（避免每張卡片重算）。
    private(set) var taskCounts: [String: Int] = [:]

    /// 目前進行中的重排工作；新的一律取消舊的，確保序列化。
    private var rescheduleTask: Task<Void, Never>?

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
        guard !isLoading else { return }
        isLoading = true
        let result = await ScheduleService.load()
        schedule = result.schedule
        source = result.source
        lastFetched = SharedStore.lastFetched
        taskCounts = Self.computeTaskCounts(result.schedule)
        isLoading = false

        WidgetCenter.shared.reloadAllTimelines()
        rescheduleNotifications()
        LiveActivityController.sync(person: selectedPerson, schedule: schedule)
        await rescheduleTask?.value
    }

    func select(_ person: String) {
        guard people.contains(person) else { return }
        selectedPerson = person
        SharedStore.selectedPerson = person
        WidgetCenter.shared.reloadAllTimelines()
        rescheduleNotifications()
        LiveActivityController.sync(person: person, schedule: schedule)
    }

    func clearSelection() {
        selectedPerson = nil
        SharedStore.selectedPerson = nil
        WidgetCenter.shared.reloadAllTimelines()
        rescheduleNotifications()
        LiveActivityController.endAll()
    }

    /// 序列化重排：取消尚未完成的舊工作，並在當下 snapshot blocks。
    private func rescheduleNotifications() {
        rescheduleTask?.cancel()
        let blocks = selectedBlocks
        rescheduleTask = Task {
            guard !Task.isCancelled else { return }
            await NotificationScheduler.shared.reschedule(blocks: blocks)
        }
    }

    private static func computeTaskCounts(_ schedule: OfflineSchedule) -> [String: Int] {
        var counts: [String: Int] = [:]
        for person in schedule.people {
            counts[person] = BlockBuilder.blocks(for: person, in: schedule.schedule).count
        }
        return counts
    }
}
