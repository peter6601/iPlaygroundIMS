import XCTest
@testable import IMS

final class BlockBuilderTests: XCTestCase {

    private func raw(_ role: String, _ day: String, _ start: String, _ end: String,
                    content: String = "", duty: String = "") -> RawTask {
        RawTask(person: "X", role: role, day: day, start: start, end: end,
                content: content, duty: duty)
    }

    // 同一天同 role 連續時段 → 合併成一個 block
    func testMergesConsecutiveSameRole() {
        let tasks = [
            raw("中控室1", "D1", "9:00", "9:40"),
            raw("中控室1", "D1", "9:40", "10:20"),
            raw("主持人", "D1", "10:30", "11:00"),
        ]
        let blocks = BlockBuilder.blocks(for: "X", in: tasks)
        XCTAssertEqual(blocks.count, 2)
        let control = blocks.first { $0.role == "中控室1" }
        XCTAssertEqual(control?.start, "9:00")
        XCTAssertEqual(control?.end, "10:20")
    }

    // 同時段的不同 role（一人身兼多職）→ 各自獨立
    func testConcurrentRolesStaySeparate() {
        let tasks = [
            raw("外場負責人", "D1", "8:00", "9:00"),
            raw("報到桌佈置", "D1", "8:00", "8:30"),
        ]
        let blocks = BlockBuilder.blocks(for: "X", in: tasks)
        XCTAssertEqual(blocks.count, 2)
        XCTAssertEqual(Set(blocks.map(\.role)), ["外場負責人", "報到桌佈置"])
    }

    // 休息時段夾在同 role 中間 → 被吸收成一個 block，且 contents 不含休息
    func testAbsorbsBreaksWithinSameRole() {
        let tasks = [
            raw("外場負責人", "D1", "9:40", "10:20", content: "session(40)"),
            raw("外場負責人", "D1", "10:20", "10:30", content: "休息(10)"),
            raw("外場負責人", "D1", "10:30", "10:50", content: "session(40)"),
        ]
        let blocks = BlockBuilder.blocks(for: "X", in: tasks)
        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks[0].start, "9:40")
        XCTAssertEqual(blocks[0].end, "10:50")
        XCTAssertFalse(blocks[0].contents.contains { $0.contains("休息") })
    }

    // 同 role 但中間有真實空檔（非相連）→ 不合併
    func testGenuineGapNotMerged() {
        let tasks = [
            raw("攝影", "D1", "9:00", "10:00"),
            raw("攝影", "D1", "14:00", "15:00"),
        ]
        let blocks = BlockBuilder.blocks(for: "X", in: tasks)
        XCTAssertEqual(blocks.count, 2)
    }

    // 完全重複的兩筆（同 start/end 不同 content）→ 合併成一個、contents 去重
    func testDedupesIdenticalRanges() {
        let tasks = [
            raw("場佈｜中庭展廳", "D0", "18:00", "23:59", content: "排贊助商桌子"),
            raw("場佈｜中庭展廳", "D0", "18:00", "23:59", content: "協助贊助商場佈"),
        ]
        let blocks = BlockBuilder.blocks(for: "X", in: tasks)
        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks[0].contents.count, 2)
    }

    // 只回傳指定人員的任務
    func testFiltersByPerson() {
        let tasks = [
            RawTask(person: "A", role: "r", day: "D1", start: "9:00", end: "9:30"),
            RawTask(person: "B", role: "r", day: "D1", start: "9:00", end: "9:30"),
        ]
        XCTAssertEqual(BlockBuilder.blocks(for: "A", in: tasks).count, 1)
    }

    // 台北時區日期換算：D1 08:00 = 2026-07-25 08:00 (+08) = 2026-07-25T00:00:00Z
    func testStartDateInTaipei() {
        let block = BlockBuilder.blocks(for: "X", in: [raw("r", "D1", "8:00", "9:00")])[0]
        let fmt = ISO8601DateFormatter()
        fmt.timeZone = TimeZone(identifier: "UTC")
        XCTAssertEqual(fmt.string(from: block.startDate), "2026-07-25T00:00:00Z")
        XCTAssertEqual(fmt.string(from: block.endDate), "2026-07-25T01:00:00Z")
    }

    // 排序：依 day、再依 start
    func testBlocksSortedByDayThenStart() {
        let tasks = [
            raw("b", "D2", "9:00", "9:30"),
            raw("a", "D1", "10:00", "10:30"),
            raw("c", "D1", "8:00", "8:30"),
        ]
        let blocks = BlockBuilder.blocks(for: "X", in: tasks)
        XCTAssertEqual(blocks.map { "\($0.day) \($0.start)" },
                       ["D1 8:00", "D1 10:00", "D2 9:00"])
    }
}
