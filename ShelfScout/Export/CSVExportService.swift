import Foundation

enum CSVExportService {
    static let headers = [
        "title", "category", "status", "storeName", "locationLabel", "dateSeen",
        "observedStorePrice", "estimatedPurchasePrice", "estimatedSalePrice",
        "estimatedGrossProfit", "estimatedMarginPercent", "currency",
        "detectedBarcode", "detectedWeight", "detectedDimensions", "notes", "imageCount"
    ]

    static func csv(for scouts: [ProductScout]) -> String {
        var rows = [headers.map(escape).joined(separator: ",")]
        rows += scouts.map(row)
        return rows.joined(separator: "\n")
    }

    private static func row(for scout: ProductScout) -> String {
        let formatter = ISO8601DateFormatter()
        let values: [String] = [
            scout.title,
            scout.category,
            scout.status,
            scout.storeName,
            scout.locationLabel,
            formatter.string(from: scout.dateSeen),
            AppFormatters.decimalString(scout.observedStorePrice),
            AppFormatters.decimalString(scout.estimatedPurchasePrice),
            AppFormatters.decimalString(scout.estimatedSalePrice),
            AppFormatters.decimalString(scout.estimatedGrossProfit),
            AppFormatters.decimalString(scout.estimatedMarginPercent),
            scout.currency,
            scout.detectedBarcode ?? "",
            scout.detectedWeight ?? "",
            scout.detectedDimensions ?? "",
            scout.notes,
            String(scout.imageLocalPaths.count)
        ]
        return values.map(escape).joined(separator: ",")
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
