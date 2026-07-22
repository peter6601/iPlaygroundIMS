import Foundation
import ActivityKit

/// Live Activity 的資料定義：靜態部分是人員，動態部分是當下/下一個任務。
struct MissionActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var currentRole: String?
        var currentEndDate: Date?
        var currentEndLabel: String?    // "18:00"，endPending 時用文字
        var nextRole: String?
        var nextStartLabel: String?     // "7/25 10:30"
        var endPending: Bool
    }

    var person: String
}
