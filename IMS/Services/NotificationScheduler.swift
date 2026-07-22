import Foundation

/// 本地通知排程器。實際的授權與排程邏輯在 Task 6 以 TDD 補齊；
/// 此處先提供介面讓 AppState 可編譯。
@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private init() {}

    func reschedule(blocks: [TaskBlock]) async {
        // Task 6 實作
    }
}
