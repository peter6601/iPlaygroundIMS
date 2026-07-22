import XCTest
@testable import IMS

final class PlaceholderTests: XCTestCase {
    func testAppGroupIDDefined() {
        XCTAssertEqual(IMSShared.appGroupID, "group.io.iplayground.ims")
    }
}
