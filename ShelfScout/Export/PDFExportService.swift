import PDFKit
import UIKit

enum PDFExportService {
    static func writePDF(for scout: ProductScout) throws -> URL {
        let safeTitle = scout.displayTitle.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeTitle) Scout Card.pdf")
        let data = makePDF(for: scout)
        try data.write(to: url, options: .atomic)
        return url
    }

    static func makePDF(for scout: ProductScout) -> Data {
        let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: page)

        return renderer.pdfData { context in
            context.beginPage()
            UIColor.systemBackground.setFill()
            context.fill(page)

            var y: CGFloat = 42
            draw("ShelfScout", at: CGPoint(x: 40, y: y), font: .boldSystemFont(ofSize: 28))
            draw("Local product scouting estimate", at: CGPoint(x: 40, y: y + 34), font: .systemFont(ofSize: 12), color: .darkGray)
            y += 70

            if let image = ImageStorageService.load(path: scout.productPhotoLocalPath) {
                image.draw(in: CGRect(x: 395, y: 42, width: 150, height: 150))
            }

            draw(scout.displayTitle, at: CGPoint(x: 40, y: y), font: .boldSystemFont(ofSize: 22))
            y += 34
            y = drawTable([
                ("Category", scout.category),
                ("Store", scout.storeName),
                ("Location", scout.locationLabel),
                ("Date seen", AppFormatters.date.string(from: scout.dateSeen)),
                ("Observed price", AppFormatters.money(scout.observedStorePrice, currency: scout.currency)),
                ("Purchase estimate", AppFormatters.money(scout.estimatedPurchasePrice, currency: scout.currency)),
                ("Sale estimate", AppFormatters.money(scout.estimatedSalePrice, currency: scout.currency)),
                ("Gross profit", AppFormatters.money(scout.estimatedGrossProfit, currency: scout.currency)),
                ("Margin", AppFormatters.percent(scout.estimatedMarginPercent)),
                ("Scout Score", "\(scout.scoutScore)/100"),
                ("Risk Level", scout.riskLevel),
                ("Beginner Friendliness", scout.beginnerFriendliness)
            ], startY: y)

            y += 18
            drawSection("Notes", body: scout.notes.isEmpty ? "No notes." : scout.notes, y: &y)
            drawSection("Risk checklist summary", body: riskSummary(for: scout), y: &y)
            drawSection("Research Checklist", body: researchSummary(for: scout), y: &y)
            if scout.hasClassifierSuggestions {
                drawSection("Local Photo Suggestions", body: classifierSummary(for: scout), y: &y)
            }
            if y > 700 {
                context.beginPage()
                UIColor.systemBackground.setFill()
                context.fill(page)
                y = 42
            }
            drawSection(
                "Disclaimer",
                body: "This document is a local scouting estimate. It is not legal, tax, customs, product safety, or business advice.",
                y: &y
            )
        }
    }

    private static func drawTable(_ rows: [(String, String)], startY: CGFloat) -> CGFloat {
        var y = startY
        for row in rows {
            UIColor.separator.setStroke()
            UIBezierPath(rect: CGRect(x: 40, y: y - 7, width: 515, height: 1)).stroke()
            draw(row.0, at: CGPoint(x: 40, y: y), font: .boldSystemFont(ofSize: 10), color: .darkGray)
            draw(row.1.isEmpty ? "Not set" : row.1, at: CGPoint(x: 190, y: y), font: .systemFont(ofSize: 11))
            y += 24
        }
        return y
    }

    private static func drawSection(_ title: String, body: String, y: inout CGFloat) {
        draw(title, at: CGPoint(x: 40, y: y), font: .boldSystemFont(ofSize: 14))
        y += 20
        let rect = CGRect(x: 40, y: y, width: 515, height: 80)
        drawMultiline(body, in: rect, font: .systemFont(ofSize: 11), color: .darkGray)
        y += 92
    }

    private static func riskSummary(for scout: ProductScout) -> String {
        let risks = [
            scout.hasElectronics ? "Electronics" : nil,
            scout.hasBattery ? "Battery" : nil,
            scout.touchesFood ? "Food contact" : nil,
            scout.isForChildren ? "Children's product" : nil,
            scout.isCosmetic ? "Cosmetic" : nil,
            scout.isMedicalOrHealthRelated ? "Medical/health" : nil,
            scout.isTextile ? "Textile" : nil,
            scout.isFragile ? "Fragile" : nil,
            scout.hasBrandOrDesignRisk ? "Brand/design risk" : nil,
            scout.hasManyCompetitors ? "Many competitors" : nil
        ].compactMap { $0 }
        return risks.isEmpty ? "No beginner risk flags selected." : risks.joined(separator: ", ")
    }

    private static func researchSummary(for scout: ProductScout) -> String {
        let platforms = QuickResearchService.checkedPlatforms(for: scout)
        return [
            "Research query: \(scout.resolvedResearchQuery.isEmpty ? "Not set" : scout.resolvedResearchQuery)",
            "Platforms checked: \(platforms.isEmpty ? "None" : platforms.joined(separator: ", "))",
            "Similar products found: \(scout.similarProductsFound ? "Yes" : "No")",
            "Competition level: \(scout.estimatedCompetitionLevel)",
            "Competitor notes: \(scout.competitorNotes.isEmpty ? "None" : scout.competitorNotes)"
        ].joined(separator: "\n")
    }

    private static func classifierSummary(for scout: ProductScout) -> String {
        [
            "Suggested category: \(scout.classifierSuggestedCategory ?? "Not set")",
            "Suggested tags: \(scout.classifierSuggestedTags.isEmpty ? "None" : scout.classifierSuggestedTags.joined(separator: ", "))",
            "Possible risk indicators: \(scout.classifierSuggestedRiskIndicators.isEmpty ? "None" : scout.classifierSuggestedRiskIndicators.joined(separator: ", "))",
            "Confidence: \(AppFormatters.percent(scout.classifierConfidence.map { Decimal($0 * 100) }))",
            "Generated locally from the product photo. Review manually."
        ].joined(separator: "\n")
    }

    private static func draw(_ text: String, at point: CGPoint, font: UIFont, color: UIColor = .label) {
        (text as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
    }

    private static func drawMultiline(_ text: String, in rect: CGRect, font: UIFont, color: UIColor = .label) {
        (text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font, .foregroundColor: color], context: nil)
    }
}
