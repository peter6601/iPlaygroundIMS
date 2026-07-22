import Foundation

/// 一段合併後的「值勤區塊」：同一天、同一 role 的連續時段合併為一。
/// 這是通知與 Widget 的基本單位（一個 block = 一則提醒 / 一格 timeline）。
struct TaskBlock: Identifiable, Hashable, Codable {
    let role: String
    let day: String          // "D0" | "D1" | "D2"
    let start: String        // "8:00"
    let end: String
    let contents: [String]   // 去掉休息、去重後的議程/工作內容
    let duty: String         // corrections.js 組好的「去哪做什麼」說明；議程類為空
    let endPending: Bool

    var id: String { "\(day)|\(role)|\(start)|\(end)" }

    /// 活動日期對應（Asia/Taipei）。
    static let dayDates: [String: (year: Int, month: Int, day: Int)] = [
        "D0": (2026, 7, 24),
        "D1": (2026, 7, 25),
        "D2": (2026, 7, 26),
    ]

    private static let taipei = TimeZone(identifier: "Asia/Taipei")!

    private func date(from hhmm: String) -> Date {
        let ymd: (year: Int, month: Int, day: Int)
        #if DEBUG
        if TestClock.testTodayEnabled, day == "D0" {
            ymd = TestClock.todayYMD()
        } else if let d = Self.dayDates[day] {
            ymd = d
        } else {
            return .distantFuture
        }
        #else
        guard let d = Self.dayDates[day] else { return .distantFuture }
        ymd = d
        #endif
        let parts = hhmm.split(separator: ":").compactMap { Int($0) }
        let hour = parts.first ?? 0
        let minute = parts.count > 1 ? parts[1] : 0
        var comps = DateComponents()
        comps.year = ymd.year; comps.month = ymd.month; comps.day = ymd.day
        comps.hour = hour; comps.minute = minute
        comps.timeZone = Self.taipei
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = Self.taipei
        return cal.date(from: comps) ?? .distantFuture
    }

    var startDate: Date { date(from: start) }
    var endDate: Date { date(from: end) }
}
