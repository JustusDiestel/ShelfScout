import XCTest
@testable import ShelfScout

final class QuickResearchServiceTests: XCTestCase {
    func testBuildsEncodedMarketplaceURLOnlyForNonEmptyQuery() {
        let url = QuickResearchService.url(for: .amazon, query: "glass jar 250 ml")
        XCTAssertEqual(url?.absoluteString, "https://www.amazon.de/s?k=glass%20jar%20250%20ml")
        XCTAssertNil(QuickResearchService.url(for: .etsy, query: "   "))
    }

    func testInstagramUsesGoogleSiteSearch() {
        let url = QuickResearchService.url(for: .instagram, query: "folding box")
        XCTAssertEqual(url?.absoluteString, "https://www.google.com/search?q=site%3Ainstagram.com+folding%20box")
    }
}
