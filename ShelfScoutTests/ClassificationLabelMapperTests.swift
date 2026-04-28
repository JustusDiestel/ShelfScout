import XCTest
@testable import ShelfScout

final class ClassificationLabelMapperTests: XCTestCase {
    func testKitchenFoodContactMapping() {
        let labels = [
            ClassificationLabel(label: "glass bottle", confidence: 0.81),
            ClassificationLabel(label: "kitchen jar", confidence: 0.42)
        ]

        let result = ClassificationLabelMapper.map(labels: labels)
        XCTAssertEqual(result.suggestedCategory, "Kitchen")
        XCTAssertTrue(result.suggestedTags.contains("kitchen"))
        XCTAssertTrue(result.suggestedRiskIndicators.contains("possibleFoodContact"))
        XCTAssertTrue(result.suggestedRiskIndicators.contains("possibleFragile"))
        XCTAssertEqual(result.confidence, 0.81)
    }

    func testElectronicsMapping() {
        let labels = [ClassificationLabel(label: "phone charger", confidence: 0.66)]
        let result = ClassificationLabelMapper.map(labels: labels)

        XCTAssertEqual(result.suggestedCategory, "Electronics")
        XCTAssertTrue(result.suggestedRiskIndicators.contains("possibleElectronics"))
        XCTAssertTrue(result.suggestedRiskIndicators.contains("possibleBattery"))
    }
}
