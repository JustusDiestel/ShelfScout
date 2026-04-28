import Foundation

enum CSVExportService {
    static let headers = [
        "title", "category", "storeName", "locationLabel", "dateSeen",
        "observedStorePrice", "estimatedPurchasePrice", "estimatedSalePrice",
        "estimatedGrossProfit", "estimatedMarginPercent", "riskLevel",
        "scoutScore", "status", "notes", "researchQuery", "amazonChecked",
        "ebayChecked", "googleShoppingChecked", "googleImagesChecked",
        "alibabaChecked", "aliexpressChecked", "etsyChecked", "tiktokChecked",
        "instagramChecked", "similarProductsFound", "estimatedCompetitionLevel",
        "competitorNotes", "classifierSuggestedCategory", "classifierSuggestedTags",
        "classifierSuggestedRiskIndicators", "classifierConfidence", "classifierLastRunAt"
    ]

    static func csv(for scouts: [ProductScout]) -> String {
        var rows = [headers.map(escape).joined(separator: ",")]
        rows += scouts.map { scout in
            [
                scout.title,
                scout.category,
                scout.storeName,
                scout.locationLabel,
                ISO8601DateFormatter().string(from: scout.dateSeen),
                AppFormatters.decimalString(scout.observedStorePrice),
                AppFormatters.decimalString(scout.estimatedPurchasePrice),
                AppFormatters.decimalString(scout.estimatedSalePrice),
                AppFormatters.decimalString(scout.estimatedGrossProfit),
                AppFormatters.decimalString(scout.estimatedMarginPercent),
                scout.riskLevel,
                String(scout.scoutScore),
                scout.status,
                scout.notes,
                scout.resolvedResearchQuery,
                String(scout.amazonChecked),
                String(scout.ebayChecked),
                String(scout.googleShoppingChecked),
                String(scout.googleImagesChecked),
                String(scout.alibabaChecked),
                String(scout.aliexpressChecked),
                String(scout.etsyChecked),
                String(scout.tiktokChecked),
                String(scout.instagramChecked),
                String(scout.similarProductsFound),
                scout.estimatedCompetitionLevel,
                scout.competitorNotes,
                scout.classifierSuggestedCategory ?? "",
                scout.classifierSuggestedTags.joined(separator: "; "),
                scout.classifierSuggestedRiskIndicators.joined(separator: "; "),
                scout.classifierConfidence.map { String($0) } ?? "",
                scout.classifierLastRunAt.map { ISO8601DateFormatter().string(from: $0) } ?? ""
            ].map(escape).joined(separator: ",")
        }
        return rows.joined(separator: "\n")
    }

    static func writeCSV(for scouts: [ProductScout], filename: String = "ShelfScout.csv") throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try csv(for: scouts).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}
