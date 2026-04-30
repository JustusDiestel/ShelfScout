import XCTest
@testable import ShelfScout

final class ShelfScoutFileServiceTests: XCTestCase {
    func testShelfScoutJSONRoundTrip() throws {
        let scout = ProductScout(title: "Test Product", category: "Kitchen", notes: "Local only")
        scout.researchQuery = "test product marketplace"
        scout.amazonChecked = true
        scout.estimatedCompetitionLevel = CompetitionLevel.medium.rawValue
        scout.competitorNotes = "Saw a few similar items."
        scout.classifierSuggestedCategory = "Kitchen"
        scout.classifierSuggestedTagsJSON = ProductScout.encodeJSON(["kitchen", "bottle"])
        scout.classifierSuggestedRiskIndicatorsJSON = ProductScout.encodeJSON(["possibleFoodContact"])
        scout.classifierConfidence = 0.72
        scout.classifierLastRunAt = Date(timeIntervalSince1970: 1_800_000_000)
        let data = try ShelfScoutFileService.documentData(for: scout)
        let decoded = try ShelfScoutFileService.decodeProducts(from: data)

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].title, "Test Product")
        XCTAssertEqual(decoded[0].category, "Kitchen")
        XCTAssertEqual(decoded[0].notes, "Local only")
        XCTAssertEqual(decoded[0].researchQuery, "test product marketplace")
        XCTAssertTrue(decoded[0].amazonChecked)
        XCTAssertEqual(decoded[0].estimatedCompetitionLevel, CompetitionLevel.medium.rawValue)
        XCTAssertEqual(decoded[0].competitorNotes, "Saw a few similar items.")
        XCTAssertEqual(decoded[0].classifierSuggestedCategory, "Kitchen")
        XCTAssertEqual(decoded[0].classifierSuggestedTags, ["kitchen", "bottle"])
        XCTAssertEqual(decoded[0].classifierSuggestedRiskIndicators, ["possibleFoodContact"])
        XCTAssertEqual(decoded[0].classifierConfidence, 0.72)
        XCTAssertEqual(decoded[0].classifierLastRunAt, Date(timeIntervalSince1970: 1_800_000_000))
    }

    func testOlderShelfScoutJSONDefaultsResearchFields() throws {
        let json = """
        {
          "schemaVersion": 1,
          "app": "ShelfScout",
          "product": {
            "id": "\(UUID().uuidString)",
            "createdAt": "2026-04-28T00:00:00Z",
            "updatedAt": "2026-04-28T00:00:00Z",
            "title": "Lunch Box",
            "category": "Kitchen",
            "productDescription": "",
            "storeName": "",
            "locationLabel": "",
            "locationPermissionUsed": false,
            "dateSeen": "2026-04-28T00:00:00Z",
            "currency": "EUR",
            "recognizedText": "",
            "notes": "",
            "status": "Interesting",
            "isSmallAndLight": false,
            "isEasyToExplain": false,
            "hasClearUseCase": false,
            "hasElectronics": false,
            "hasBattery": false,
            "touchesFood": false,
            "isForChildren": false,
            "isCosmetic": false,
            "isMedicalOrHealthRelated": false,
            "isTextile": false,
            "isFragile": false,
            "hasBrandOrDesignRisk": false,
            "hasManyCompetitors": false
          }
        }
        """

        let decoded = try ShelfScoutFileService.decodeProducts(from: Data(json.utf8))
        XCTAssertEqual(decoded[0].researchQuery, "Lunch Box")
        XCTAssertFalse(decoded[0].amazonChecked)
        XCTAssertFalse(decoded[0].similarProductsFound)
        XCTAssertEqual(decoded[0].estimatedCompetitionLevel, CompetitionLevel.unknown.rawValue)
        XCTAssertEqual(decoded[0].competitorNotes, "")
        XCTAssertNil(decoded[0].classifierSuggestedCategory)
        XCTAssertEqual(decoded[0].classifierSuggestedTags, [])
        XCTAssertEqual(decoded[0].classifierSuggestedRiskIndicators, [])
        XCTAssertNil(decoded[0].classifierConfidence)
        XCTAssertNil(decoded[0].classifierLastRunAt)
    }
}
