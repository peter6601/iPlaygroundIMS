import Foundation
import Observation
import WidgetKit

/// App 的中央狀態。
/// - `selectedPerson`：目前檢視中的人（純導覽，不啟動任何提醒）
/// - `activatedPerson`：已「開啟提醒」並鎖定為本人的人（通知 / Widget / Live Activity 依此）
@MainActor
@Observable
final class AppState {
    private(set) var schedule: OfflineSchedule = .empty
    private(set) var source: ScheduleService.Source = .bundle
    private(set) var lastFetched: Date? = SharedStore.lastFetched
    private(set) var isLoading = false
    private(set) var selectedPerson: String? = SharedStore.selectedPerson
    private(set) var activatedPerson: String? = SharedStore.activatedPerson

    /// 各人員的值勤段數，於資料載入後預先算好（避免每張卡片重算）。
    private(set) var taskCounts: [String: Int] = [:]

    private var rescheduleTask: Task<Void, Never>?

    var people: [String] { schedule.people }

    /// 目前檢視人員的值勤區塊（給 timeline 顯示）。
    var selectedBlocks: [TaskBlock] {
        guard let selectedPerson else { return [] }
        return BlockBuilder.blocks(for: selectedPerson, in: schedule.schedule)
    }

    var selectedMissions: [SideMission] {
        guard let selectedPerson else { return [] }
        return schedule.sideMissions.filter { $0.person == selectedPerson }
    }

    /// 目前檢視的人是否就是已開啟提醒的本人。
    var isSelectedActivated: Bool {
        selectedPerson != nil && selectedPerson == activatedPerson
    }

    /// 已開啟提醒本人的值勤區塊（通知 / Live Activity 依此）。
    private var activatedBlocks: [TaskBlock] {
        guard let activatedPerson else { return [] }
        return BlockBuilder.blocks(for: activatedPerson, in: schedule.schedule)
    }

    // MARK: - 載入

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
        LiveActivityController.sync(person: activatedPerson, schedule: schedule)
        await rescheduleTask?.value
    }

    // MARK: - 檢視（不啟動提醒）

    func select(_ person: String) {
        guard people.contains(person) else { return }
        selectedPerson = person
        SharedStore.selectedPerson = person
    }

    func clearSelection() {
        selectedPerson = nil
        SharedStore.selectedPerson = nil
    }

    // MARK: - 開啟 / 關閉提醒（本人）

    /// 把目前檢視的人設為本人並開啟提醒（請求授權、排通知、啟動 Live Activity）。
    func activateSelected() async {
        guard let selectedPerson else { return }
        activatedPerson = selectedPerson
        SharedStore.activatedPerson = selectedPerson

        _ = await NotificationScheduler.shared.requestAuthorization()
        WidgetCenter.shared.reloadAllTimelines()
        rescheduleNotifications()
        LiveActivityController.sync(person: activatedPerson, schedule: schedule)

        #if DEBUG
        // 測試模式：開啟提醒後 15 秒送一則確認用推播，方便當場驗證通知有通。
        if TestClock.testTodayEnabled {
            await NotificationScheduler.shared.scheduleTestNotification(after: 15)
        }
        #endif
    }

    /// 關閉提醒：取消通知、結束 Live Activity。
    func deactivate() {
        activatedPerson = nil
        SharedStore.activatedPerson = nil
        WidgetCenter.shared.reloadAllTimelines()
        rescheduleNotifications()          // blocks 為空 → 清掉所有通知
        LiveActivityController.endAll()
    }

    // MARK: - Private

    private func rescheduleNotifications() {
        rescheduleTask?.cancel()
        let blocks = activatedBlocks
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
