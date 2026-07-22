import Foundation
import UserNotifications

/// 通知排程的純邏輯（可單元測試，不碰系統 API）。
enum NotificationPlan {
    /// 任務開始前多久提醒。
    static let leadTime: TimeInterval = 10 * 60
    /// 每日第一個任務前多久發「今日開始」摘要。
    static let daySummaryLead: TimeInterval = 30 * 60
    /// 系統 pending 通知上限保護（實際每人遠低於此）。
    static let maxNotifications = 60

    static func fireDate(for block: TaskBlock) -> Date {
        block.startDate.addingTimeInterval(-leadTime)
    }

    /// 只保留提醒時間還在未來的 block，並依 fireDate 排序。
    static func upcoming(_ blocks: [TaskBlock], now: Date) -> [TaskBlock] {
        blocks
            .filter { fireDate(for: $0) > now }
            .sorted { fireDate(for: $0) < fireDate(for: $1) }
    }

    struct DaySummary: Equatable {
        let day: String
        let fireDate: Date
        let firstStart: String
        let count: Int
    }

    /// 每個「還沒開始」的活動日，產生一則今日摘要（第一個任務前 30 分）。
    static func daySummaries(_ blocks: [TaskBlock], now: Date) -> [DaySummary] {
        let byDay = Dictionary(grouping: blocks, by: \.day)
        return byDay.compactMap { day, dayBlocks -> DaySummary? in
            guard let first = dayBlocks.min(by: { $0.startDate < $1.startDate }) else { return nil }
            let fire = first.startDate.addingTimeInterval(-daySummaryLead)
            guard fire > now else { return nil }
            return DaySummary(day: day, fireDate: fire, firstStart: first.start, count: dayBlocks.count)
        }
        .sorted { $0.fireDate < $1.fireDate }
    }
}

/// 本地通知排程器：授權、依選定人員的值勤區塊預排提醒。
@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    /// 選定人員後請求通知授權。
    @discardableResult
    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// 清掉舊的、依 blocks 重排所有未來提醒。
    func reschedule(blocks: [TaskBlock], now: Date = Date()) async {
        center.removeAllPendingNotificationRequests()
        guard !blocks.isEmpty else { return }

        // 沒授權就先要求（第一次選人時觸發系統彈窗）
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = await requestAuthorization()
        }

        var requests: [UNNotificationRequest] = []

        // 每日摘要
        for summary in NotificationPlan.daySummaries(blocks, now: now) {
            let content = UNMutableNotificationContent()
            content.title = "今天有 \(summary.count) 段任務"
            content.body = "第一個任務 \(summary.firstStart) 開始，記得提前到場。"
            content.sound = .default
            requests.append(request(id: "day-\(summary.day)", fireDate: summary.fireDate, content: content))
        }

        // 各任務提醒（提前 10 分）
        for block in NotificationPlan.upcoming(blocks, now: now) {
            let content = UNMutableNotificationContent()
            content.title = "10 分鐘後 · \(block.role)"
            content.body = notificationBody(for: block)
            content.sound = .default
            requests.append(request(id: block.id, fireDate: NotificationPlan.fireDate(for: block), content: content))
        }

        // 上限保護：保留最早的前 N 則
        let capped = Array(requests.prefix(NotificationPlan.maxNotifications))
        for req in capped {
            try? await center.add(req)
        }
    }

    private func notificationBody(for block: TaskBlock) -> String {
        let time = block.endPending ? "\(block.start) 開始" : "\(block.start)–\(block.end)"
        let detail = block.duty.isEmpty ? block.contents.prefix(3).joined(separator: "、") : block.duty
        return detail.isEmpty ? time : "\(time)\n\(detail)"
    }

    private func request(id: String, fireDate: Date, content: UNNotificationContent) -> UNNotificationRequest {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Taipei")!
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        return UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    }

    #if DEBUG
    /// 手動驗證用：排一則 N 秒後的測試通知。
    func scheduleTestNotification(after seconds: TimeInterval = 8) async {
        _ = await requestAuthorization()
        let content = UNMutableNotificationContent()
        content.title = "測試提醒 · 中控室1"
        content.body = "9:00–10:30\n負責執行「中控」相關工作與現場交接。"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: "test", content: content, trigger: trigger))
    }
    #endif
}
