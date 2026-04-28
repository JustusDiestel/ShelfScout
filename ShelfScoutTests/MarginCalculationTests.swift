import XCTest
@testable import ShelfScout

final class MarginCalculationTests: XCTestCase {
    func testGrossProfitAndMargin() {
        XCTAssertEqual(ScoringService.estimatedGrossProfit(purchase: 4, sale: 10), 6)
        XCTAssertEqual(ScoringService.estimatedMarginPercent(purchase: 4, sale: 10), 60)
    }

    func testMissingOrZeroSaleReturnsNilMargin() {
        XCTAssertNil(ScoringService.estimatedMarginPercent(purchase: 4, sale: nil))
        XCTAssertNil(ScoringService.estimatedMarginPercent(purchase: 4, sale: 0))
    }
}
