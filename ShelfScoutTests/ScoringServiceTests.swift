import XCTest
@testable import ShelfScout

final class ScoringServiceTests: XCTestCase {
    func testPositiveMarginAndLowRiskScoresHigher() {
        let scout = ProductScout(
            observedStorePrice: 3.99,
            estimatedPurchasePrice: 2,
            estimatedSalePrice: 10,
            isSmallAndLight: true,
            isEasyToExplain: true,
            hasClearUseCase: true
        )

        XCTAssertGreaterThanOrEqual(ScoringService.score(for: scout), 80)
        XCTAssertEqual(ScoringService.riskLevel(for: scout), .low)
    }

    func testHighRiskBeginnerAvoidance() {
        let scout = ProductScout(
            estimatedPurchasePrice: 8,
            estimatedSalePrice: 6,
            hasElectronics: true,
            hasBattery: true,
            touchesFood: true,
            isForChildren: true,
            isMedicalOrHealthRelated: true,
            hasBrandOrDesignRisk: true
        )

        XCTAssertEqual(ScoringService.riskLevel(for: scout), .avoid)
        XCTAssertLessThan(ScoringService.score(for: scout), 50)
    }
}
