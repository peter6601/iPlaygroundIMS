import XCTest
@testable import IMS

final class NotificationPlanTests: XCTestCase {

    private func block(_ role: String, _ day: String, _ start: String, _ end: String) -> TaskBlock {
        TaskBlock(role: role, day: day, start: start, end: end, contents: [], duty: "", endPending: false)
    }

    // D1 09:40 開始 → 提前 10 分 = 09:30 台北時間
    func testFireDateIsTenMinutesBeforeStart() {
        let b = block("外場負責人", "D1", "9:40", "10:20")
        let expected = b.startDate.addingTimeInterval(-10 * 60)
        XCTAssertEqual(NotificationPlan.fireDate(for: b), expected)
    }

    // 只保留 fireDate 還在未來的 block
    func testUpcomingFiltersPast() {
        let past = block("A", "D1", "9:40", "10:20")       // 2026-07-25
        let future = block("B", "D2", "9:40", "10:20")     // 2026-07-26
        // now 設在 D1 之後、D2 之前
        let now = block("x", "D1", "23:00", "23:30").startDate
        let upcoming = NotificationPlan.upcoming([past, future], now: now)
        XCTAssertEqual(upcoming.map(\.role), ["B"])
    }

    // 每日摘要：取當天最早 block，提前 30 分；過去的日子不排
    func testDaySummaries() {
        let blocks = [
            block("早班", "D1", "8:00", "9:00"),
            block("午班", "D1", "13:00", "14:00"),
            block("D2班", "D2", "9:00", "10:00"),
        ]
        // now 在 D1 開始前
        let now = block("x", "D1", "6:00", "6:30").startDate
        let summaries = NotificationPlan.daySummaries(blocks, now: now)
        XCTAssertEqual(summaries.count, 2)
        let d1 = summaries.first { $0.day == "D1" }!
        XCTAssertEqual(d1.firstStart, "8:00")
        // 摘要提前 30 分 = 07:30
        XCTAssertEqual(d1.fireDate, block("x", "D1", "8:00", "8:00").startDate.addingTimeInterval(-30 * 60))
    }

    func testDaySummariesSkipsPastDays() {
        let blocks = [block("D1班", "D1", "8:00", "9:00")]
        let now = block("x", "D2", "8:00", "8:00").startDate  // D1 已過
        XCTAssertTrue(NotificationPlan.daySummaries(blocks, now: now).isEmpty)
    }
}
