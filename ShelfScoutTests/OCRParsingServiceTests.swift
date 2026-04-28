import XCTest
@testable import ShelfScout

final class OCRParsingServiceTests: XCTestCase {
    func testDetectsPriceEANWeightAndDimensions() {
        let text = """
        Folding Lunch Box
        € 3,99
        4006381333931
        250 g
        20 x 10 x 5 cm
        """

        let result = OCRParsingService.parse(text)
        XCTAssertEqual(result.possibleTitle, "Folding Lunch Box")
        XCTAssertEqual(result.price, Decimal(string: "3.99"))
        XCTAssertEqual(result.barcode, "4006381333931")
        XCTAssertEqual(result.weightOrSize, "250 g")
        XCTAssertEqual(result.dimensions, "20 x 10 x 5 cm")
    }
}
