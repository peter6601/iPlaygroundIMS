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

    // ContentState 正確帶入當下與下一場
    func testContentStateMapping() {
        let s = schedule([
            raw("外場", "D1", "9:00", "10:00"),
            raw("中控", "D1", "10:30", "11:00"),
        ])
        let slot = MissionActivityState.currentSlot(person: "X", schedule: s, now: at("D1", "9:30"))!
        let state = MissionActivityState.make(from: slot)
        XCTAssertEqual(state.currentRole, "外場")
        XCTAssertEqual(state.nextRole, "中控")
        XCTAssertEqual(state.nextStartLabel, "7/25 10:30")
    }
}
