import XCTest
@testable import IMS

final class RosterBuilderTests: XCTestCase {

    private func s(_ tasks: [RawTask]) -> OfflineSchedule {
        OfflineSchedule(people: [], schedule: tasks)
    }
    private func raw(_ person: String, _ role: String, _ day: String, _ start: String, _ end: String,
                    content: String = "") -> RawTask {
        RawTask(person: person, role: role, day: day, start: start, end: end, content: content)
    }

    // 指定時段列出各職務的人
    func testRosterAtTime() {
        let sch = s([
            raw("憲憲", "中控室2", "D1", "15:30", "15:50"),
            raw("Andy", "中控室1", "D1", "15:30", "15:50"),
            raw("DinDin", "外場負責人", "D1", "15:30", "15:50"),
            raw("柏謙", "計時＋舉牌", "D1", "15:30", "15:50"),
            raw("別人", "中控室2", "D1", "16:00", "16:20"),  // 不同時段，不該出現
        ])
        let groups = RosterBuilder.roster(day: "D1", start: "15:30", in: sch)
        let byCat = Dictionary(uniqueKeysWithValues: groups.map { ($0.category, $0.people) })
        XCTAssertEqual(byCat["中控室"], ["Andy", "憲憲"])
        XCTAssertEqual(byCat["負責人"], ["DinDin"])
        XCTAssertEqual(byCat["計時／舉牌"], ["柏謙"])
        XCTAssertNil(byCat["中控室"]?.contains("別人") == true ? "x" : nil)
    }

    // 跨在時段內（start <= t < end）
    func testActiveWindowInclusive() {
        let sch = s([raw("A", "外場負責人", "D1", "15:00", "16:00")])
        XCTAssertFalse(RosterBuilder.roster(day: "D1", start: "16:00", in: sch).isEmpty == false)
        XCTAssertFalse(RosterBuilder.roster(day: "D1", start: "15:00", in: sch).isEmpty)
        XCTAssertFalse(RosterBuilder.roster(day: "D1", start: "15:30", in: sch).isEmpty)
    }

    // 休息時段的內容不列入
    func testSkipsBreaks() {
        let sch = s([raw("A", "中控室2", "D1", "15:00", "15:10", content: "休息(10)")])
        XCTAssertTrue(RosterBuilder.roster(day: "D1", start: "15:00", in: sch).isEmpty)
    }

    // 時段清單去重、排序
    func testSlotsDistinctSorted() {
        let sch = s([
            raw("A", "中控室2", "D1", "15:30", "15:50"),
            raw("B", "外場負責人", "D1", "15:30", "15:50"),  // 同時段
            raw("C", "中控室2", "D1", "9:00", "9:40"),
        ])
        let slots = RosterBuilder.slots(day: "D1", in: sch)
        XCTAssertEqual(slots.map(\.start), ["9:00", "15:30"])
    }

    // 職務分類
    func testCategory() {
        XCTAssertEqual(RosterBuilder.category(for: "中控室2"), "中控室")
        XCTAssertEqual(RosterBuilder.category(for: "便當組4"), "便當組")
        XCTAssertEqual(RosterBuilder.category(for: "外場負責人"), "負責人")
        XCTAssertEqual(RosterBuilder.category(for: "計時＋舉牌"), "計時／舉牌")
        XCTAssertEqual(RosterBuilder.category(for: "攝影 （講者）"), "攝影")
    }
}
