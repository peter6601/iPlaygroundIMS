import Foundation

/// 活動日的顯示與判斷工具。
enum DayInfo {
    static let all = ["D0", "D1", "D2"]

    static func label(_ day: String) -> String {
        switch day {
        case "D0": return "D0 · 7/24"
        case "D1": return "D1 · 7/25"
        case "D2": return "D2 · 7/26"
        default: return day
        }
    }

    static func shortLabel(_ day: String) -> String {
        switch day {
        case "D0": return "7/24"
        case "D1": return "7/25"
        case "D2": return "7/26"
        default: return day
        }
    }

    /// 依台北時間決定預設顯示的日期（對齊網站邏輯）。
    static func defaultDay(now: Date = Date()) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Taipei")!
        let comps = cal.dateComponents([.month, .day], from: now)
        let monthDay = (comps.month ?? 0) * 100 + (comps.day ?? 0)
        if monthDay <= 724 { return "D0" }
        if monthDay == 725 { return "D1" }
        return "D2"
    }
}
