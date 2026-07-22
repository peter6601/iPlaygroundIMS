import Foundation

#if DEBUG
/// 測試輔助：以環境變數 `IMS_TEST_TODAY` 開啟「今日測試」模式。
/// 開啟後 D0 的日期會被視為「今天」（Asia/Taipei），並注入 DinDin 今天下午的測試任務，
/// 方便在真機上當天就驗證通知 / Live Activity / 動態島。
///
/// 注意：Widget extension 是獨立行程、拿不到這個環境變數，所以 Widget 仍會用真實 D0 日期；
/// 通知與 Live Activity 由 App 端計算，會正確使用「今天」。
enum TestClock {
    static var testTodayEnabled: Bool {
        ProcessInfo.processInfo.environment["IMS_TEST_TODAY"] != nil
    }

    /// 今天（Asia/Taipei）的年月日。
    static func todayYMD() -> (year: Int, month: Int, day: Int) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Asia/Taipei")!
        let c = cal.dateComponents([.year, .month, .day], from: Date())
        return (c.year ?? 2026, c.month ?? 7, c.day ?? 22)
    }

    /// DinDin 今天下午 15:00–20:00 的測試任務（掛在 D0）。
    static let dinDinTodayTasks: [RawTask] = [
        RawTask(person: "DinDin", role: "場佈支援", day: "D0", start: "15:00", end: "16:00",
                content: "測試任務", duty: "（測試）負責場佈支援，地點：中庭展廳。"),
        RawTask(person: "DinDin", role: "外場負責人", day: "D0", start: "16:00", end: "17:30",
                content: "測試任務", duty: "（測試）外場動線與人力調度。"),
        RawTask(person: "DinDin", role: "便當發放", day: "D0", start: "17:30", end: "18:30",
                content: "測試任務", duty: "（測試）便當桌登記與發放。"),
        RawTask(person: "DinDin", role: "中控室", day: "D0", start: "18:30", end: "20:00",
                content: "測試任務", duty: "（測試）中控室畫面與計時。"),
    ]
}
#endif
