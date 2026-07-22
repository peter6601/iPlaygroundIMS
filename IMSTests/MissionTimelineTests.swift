import XCTest
@testable import IMS

final class MissionTimelineTests: XCTestCase {

    private func schedule(_ tasks: [RawTask]) -> OfflineSchedule {
        OfflineSchedule(people: ["X"], schedule: tasks)
    }

    private func raw(_ role: String, _ day: String, _ start: String, _ end: String) -> RawTask {
        RawTask(person: "X", role: role, day: day, start: start, end: end)
    }

    /// 台北時間某日某時的 Date。
    private func at(_ day: String, _ hhmm: String) -> Date {
        TaskBlock(role: "", day: day, start: hhmm, end: hhmm,
                  contents: [], duty: "", endPending: false).startDate
    }

    func testNoPersonReturnsSinglePrompt() {
        let slots = MissionTimeline.slots(person: nil, schedule: schedule([]), now: Date())
        XCTAssertEqual(slots.count, 1)
        XCTAssertNil(slots[0].current)
    }

    // 活動當中：now 落在第一個 block 內 → current 正確、next 正確
    func testCurrentAndNextDuringEvent() {
        let s = schedule([
            raw("外場", "D1", "9:00", "10:00"),
            raw("中控", "D1", "10:30", "11:00"),
        ])
        let now = at("D1","9:30")
        let slots = MissionTimeline.slots(person: "X", schedule: s, now: now)
        let first = slots[0]
        XCTAssertEqual(first.current?.role, "外場")
        XCTAssertEqual(first.next?.role, "中控")
    }

    // 邊界切換：應在每個 block 的開始與結束各有一個切片
    func testBoundariesProduceSwitchingSlots() {
        let s = schedule([
            raw("外場", "D1", "9:00", "10:00"),
            raw("中控", "D1", "10:30", "11:00"),
        ])
        let now = at("D1","8:00")
        let slots = MissionTimeline.slots(person: "X", schedule: s, now: now)
        // 在 10:15（外場結束後、中控前）應為休息：current nil、next=中控
        let gapDate = at("D1","10:15")
        let gapSlot = slots.min { abs($0.date.timeIntervalSince(gapDate)) < abs($1.date.timeIntervalSince(gapDate)) }
        // 最接近 10:15 的切片是 10:00（外場結束），此時 current nil
        XCTAssertNil(gapSlot?.current)
        XCTAssertEqual(gapSlot?.next?.role, "中控")
    }

    // 全部任務已過 → 最後切片 current/next 皆 nil
    func testAllPastYieldsEmpty() {
        let s = schedule([raw("外場", "D1", "9:00", "10:00")])
        let now = at("D2","9:00")
        let slots = MissionTimeline.slots(person: "X", schedule: s, now: now)
        XCTAssertNil(slots.last?.current)
        XCTAssertNil(slots.last?.next)
    }
}
