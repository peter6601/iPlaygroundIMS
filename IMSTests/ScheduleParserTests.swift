import XCTest
@testable import IMS

final class ScheduleParserTests: XCTestCase {

    private func fixture(_ name: String, ext: String = "js") throws -> String {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: name, withExtension: ext) else {
            throw XCTSkip("找不到測試資料 \(name).\(ext)")
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    func testParsesBundledSchedule() throws {
        let scheduleJS = try fixture("schedule.bundle")
        let correctionsJS = try fixture("corrections.bundle")

        let parsed = try ScheduleParser.parse(scheduleJS: scheduleJS, correctionsJS: correctionsJS)

        XCTAssertGreaterThan(parsed.people.count, 25, "應解析出工作人員名單")
        XCTAssertTrue(parsed.people.contains("DinDin"))
        XCTAssertFalse(parsed.people.contains("工作坊講者"))
        XCTAssertFalse(parsed.schedule.isEmpty)
    }

    /// corrections.js 會把原始 D1/D2 排班中非講者的 Ethan 改名為 ggt。
    /// 若 corrections 沒有執行，schedule 裡不會出現任何 ggt。
    func testCorrectionsAreApplied() throws {
        let scheduleJS = try fixture("schedule.bundle")
        let correctionsJS = try fixture("corrections.bundle")

        let parsed = try ScheduleParser.parse(scheduleJS: scheduleJS, correctionsJS: correctionsJS)

        XCTAssertTrue(parsed.schedule.contains { $0.person == "ggt" },
                      "corrections.js 應已將部分 Ethan 改名為 ggt")
    }

    /// corrections.js 執行失敗時，仍應能只用 schedule.js 解析成功。
    func testCorruptCorrectionsFallsBackToScheduleOnly() throws {
        let scheduleJS = try fixture("schedule.bundle")

        let parsed = try ScheduleParser.parse(scheduleJS: scheduleJS,
                                              correctionsJS: "this is not valid js ((")

        XCTAssertTrue(parsed.people.contains("DinDin"))
        XCTAssertFalse(parsed.schedule.isEmpty)
        // 未套修正 → 不應出現 ggt
        XCTAssertFalse(parsed.schedule.contains { $0.person == "ggt" })
    }

    /// corrections.js 會產生 sideMissions，以及帶 duty 字串的場務任務。
    func testCapturesDutyAndSideMissions() throws {
        let scheduleJS = try fixture("schedule.bundle")
        let correctionsJS = try fixture("corrections.bundle")

        let parsed = try ScheduleParser.parse(scheduleJS: scheduleJS, correctionsJS: correctionsJS)

        XCTAssertFalse(parsed.sideMissions.isEmpty, "應解析出支線任務")
        XCTAssertTrue(parsed.sideMissions.contains { $0.person == "DinDin" })
        XCTAssertTrue(parsed.schedule.contains { !$0.duty.isEmpty },
                      "corrections 補的場務任務應帶有 duty 說明")
    }

    func testMissingScheduleThrows() {
        XCTAssertThrowsError(
            try ScheduleParser.parse(scheduleJS: "var x = 1;", correctionsJS: nil)
        )
    }
}
