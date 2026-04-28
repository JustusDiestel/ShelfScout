import XCTest
@testable import ShelfScout

final class CSVExportServiceTests: XCTestCase {
    func testEscapingCommasQuotesAndNewlines() {
        XCTAssertEqual(CSVExportService.escape("plain"), "plain")
        XCTAssertEqual(CSVExportService.escape("with,comma"), "\"with,comma\"")
        XCTAssertEqual(CSVExportService.escape("a \"quote\""), "\"a \"\"quote\"\"\"")
        XCTAssertEqual(CSVExportService.escape("two\nlines"), "\"two\nlines\"")
    }
}
