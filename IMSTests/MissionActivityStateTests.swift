import XCTest
@testable import IMS

final class MissionActivityStateTests: XCTestCase {

    private func schedule(_ tasks: [RawTask]) -> OfflineSchedule {
        OfflineSchedule(people: ["X"], schedule: tasks)
    }
    private func raw(_ role: String, _ day: String, _ start: String, _ end: String) -> RawTask {
        RawTask(person: "X", role: role, day: day, start: start, end: end)
    }
    private func at(_ day: String, _ hhmm: String) -> Date {
        TaskBlock(role: "", day: day, start: hhmm, end: hhmm, contents: [], duty: "", endPending: false).startDate
    }

    // 進行中 → 需要 Live Activity
    func testActiveWhenTaskInProgress() {
        let s = schedule([raw("外場", "D1", "9:00", "10:00")])
        XCTAssertTrue(MissionActivityState.hasActiveWork(person: "X", schedule: s, now: at("D1", "9:30")))
    }

    // 下一場在 3 小時內 → 需要
    func testActiveWhenNextSoon() {
        let s = schedule([raw("外場", "D1", "9:00", "10:00")])
        XCTAssertTrue(MissionActivityState.hasActiveWork(person: "X", schedule: s, now: at("D1", "7:00")))
    }

    // 下一場還很遠（兩天前）→ 不需要
    func testInactiveWhenNextFarAway() {
        let s = schedule([raw("外場", "D1", "9:00", "10:00")])
        XCTAssertFalse(MissionActivityState.hasActiveWork(person: "X", schedule: s, now: at("D0", "9:00")))
    }

    // 任務全部結束 → 不需要
    func testInactiveWhenAllDone() {
        let s = schedule([raw("外場", "D1", "9:00", "10:00")])
        XCTAssertFalse(MissionActivityState.hasActiveWork(person: "X", schedule: s, now: at("D2", "9:00")))
    }

    // 進行中：焦點=當下任務，帶時間與 duty，並預告下一場
    func testContentStateCurrent() {
        let s = OfflineSchedule(people: ["X"], schedule: [
            RawTask(person: "X", role: "外場", day: "D1", start: "9:00", end: "10:00",
                    content: "", duty: "外場動線調度。"),
            RawTask(person: "X", role: "中控", day: "D1", start: "10:30", end: "11:00"),
        ])
        let slot = MissionActivityState.currentSlot(person: "X", schedule: s, now: at("D1", "9:30"))!
        let state = MissionActivityState.make(from: slot)
        XCTAssertEqual(state.focusRole, "外場")
        XCTAssertTrue(state.isCurrent)
        XCTAssertEqual(state.focusTimeLabel, "9:00–10:00")
        XCTAssertEqual(state.focusDuty, "外場動線調度。")
        XCTAssertEqual(state.upNext, "中控 · 10:30")
    }

    // 下一場：焦點=下一個任務，NEXT 狀態、無倒數
    func testContentStateNext() {
        let s = schedule([raw("場佈", "D1", "9:00", "10:00")])
        let slot = MissionActivityState.currentSlot(person: "X", schedule: s, now: at("D1", "8:00"))!
        let state = MissionActivityState.make(from: slot)
        XCTAssertEqual(state.focusRole, "場佈")
        XCTAssertFalse(state.isCurrent)
        XCTAssertEqual(state.focusTimeLabel, "9:00–10:00")
        XCTAssertNil(state.focusEndDate)
    }
}
