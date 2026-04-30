import Foundation
import UIKit

enum ImportService {
    static func importShelfScout(from url: URL) throws -> [ProductScout] {
        let access = url.startAccessingSecurityScopedResource()
        defer {
            if access { url.stopAccessingSecurityScopedResource() }
        }
        let data = try Data(contentsOf: url)
        let products = try ShelfScoutFileService.decodeProducts(from: data)
        return try products.map { try ShelfScoutFileService.makeModel(from: $0) }
    }

    static func importCSV(from url: URL) throws -> [ProductScout] {
        let access = url.startAccessingSecurityScopedResource()
        defer {
            if access { url.stopAccessingSecurityScopedResource() }
        }
        let text = try String(contentsOf: url, encoding: .utf8)
        let rows = parseCSV(text)
        guard let header = rows.first, !header.isEmpty else { return [] }
        return rows.dropFirst().map { row in
            let dictionary = Dictionary(uniqueKeysWithValues: zip(header, row))
            let scout = ProductScout()
            scout.title = dictionary["title"] ?? ""
            scout.category = dictionary["category"] ?? ""
            scout.storeName = dictionary["storeName"] ?? ""
            scout.locationLabel = dictionary["locationLabel"] ?? ""
            scout.observedStorePrice = Decimal(string: dictionary["observedStorePrice"] ?? "")
            scout.estimatedPurchasePrice = Decimal(string: dictionary["estimatedPurchasePrice"] ?? "")
            scout.estimatedSalePrice = Decimal(string: dictionary["estimatedSalePrice"] ?? "")
            scout.status = dictionary["status"] ?? ProductScoutStatus.interesting.rawValue
            scout.notes = dictionary["notes"] ?? ""
            scout.researchQuery = dictionary["researchQuery"] ?? ProductScout.defaultResearchQuery(title: scout.title, category: scout.category)
            scout.amazonChecked = boolValue(dictionary["amazonChecked"])
            scout.ebayChecked = boolValue(dictionary["ebayChecked"])
            scout.googleShoppingChecked = boolValue(dictionary["googleShoppingChecked"])
            scout.googleImagesChecked = boolValue(dictionary["googleImagesChecked"])
            scout.alibabaChecked = boolValue(dictionary["alibabaChecked"])
            scout.aliexpressChecked = boolValue(dictionary["aliexpressChecked"])
            scout.etsyChecked = boolValue(dictionary["etsyChecked"])
            scout.tiktokChecked = boolValue(dictionary["tiktokChecked"])
            scout.instagramChecked = boolValue(dictionary["instagramChecked"])
            scout.similarProductsFound = boolValue(dictionary["similarProductsFound"])
            scout.estimatedCompetitionLevel = dictionary["estimatedCompetitionLevel"]
            scout.competitorNotes = dictionary["competitorNotes"]
            scout.classifierSuggestedCategory = emptyToNil(dictionary["classifierSuggestedCategory"])
            let tags = splitList(dictionary["classifierSuggestedTags"])
            if !tags.isEmpty {
                scout.classifierSuggestedTagsJSON = ProductScout.encodeJSON(tags)
            }
            let indicators = splitList(dictionary["classifierSuggestedRiskIndicators"])
            if !indicators.isEmpty {
                scout.classifierSuggestedRiskIndicatorsJSON = ProductScout.encodeJSON(indicators)
            }
            scout.classifierConfidence = Double(dictionary["classifierConfidence"] ?? "")
            if let classifierDate = dictionary["classifierLastRunAt"], let date = ISO8601DateFormatter().date(from: classifierDate) {
                scout.classifierLastRunAt = date
            }
            if let dateString = dictionary["dateSeen"], let date = ISO8601DateFormatter().date(from: dateString) {
                scout.dateSeen = date
            }
            return scout
        }
    }

    static func parseCSV(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var insideQuotes = false
        var index = text.startIndex

        while index < text.endIndex {
            let character = text[index]
            if character == "\"" {
                let next = text.index(after: index)
                if insideQuotes, next < text.endIndex, text[next] == "\"" {
                    field.append("\"")
                    index = next
                } else {
                    insideQuotes.toggle()
                }
            } else if character == ",", !insideQuotes {
                row.append(field)
                field = ""
            } else if character == "\n", !insideQuotes {
                row.append(field)
                rows.append(row)
                row = []
                field = ""
            } else if character != "\r" {
                field.append(character)
            }
            index = text.index(after: index)
        }
        row.append(field)
        if !row.allSatisfy(\.isEmpty) { rows.append(row) }
        return rows
    }

    private static func boolValue(_ value: String?) -> Bool {
        switch value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "true", "yes", "1": true
        default: false
        }
    }

    private static func emptyToNil(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func splitList(_ value: String?) -> [String] {
        (value ?? "")
            .components(separatedBy: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
