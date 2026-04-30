import PDFKit
import UIKit

enum PDFExportService {
    static func writePDF(for scout: ProductScout) throws -> URL {
        let filename = exportFilename(
            productName: scout.displayTitle,
            fileExtension: "pdf"
        )

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)

        try makePDF(for: [scout]).write(to: url, options: .atomic)
        return url
    }

    static func writePDF(for scouts: [ProductScout], filename: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename.replacingOccurrences(of: "/", with: "-"))
        try makePDF(for: scouts).write(to: url, options: .atomic)
        return url
    }

    private static func exportFilename(
        productName: String,
        fileExtension: String,
        date: Date = Date()
    ) -> String {
        let safeProductName = sanitizeFilenamePart(
            productName.isEmpty ? "Unbenanntes_Produkt" : productName
        )

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let dateString = formatter.string(from: date)

        return "\(safeProductName)_ShelfScout_\(dateString).\(fileExtension)"
    }

    private static func sanitizeFilenamePart(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
            .components(separatedBy: CharacterSet(charactersIn: "/\\?%*|\"<>:"))
            .joined()
    }

    static func makePDF(for scouts: [ProductScout]) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { context in
            for scout in scouts {
                render(scout, context: context, pageRect: pageRect)
            }
        }
    }

    private static func render(_ scout: ProductScout, context: UIGraphicsPDFRendererContext, pageRect: CGRect) {
        beginPage(context, pageRect)
        let margin: CGFloat = 40
        let contentWidth = pageRect.width - margin * 2
        var y: CGFloat = 42

        draw("ShelfScout", at: CGPoint(x: margin, y: y), font: .boldSystemFont(ofSize: 28))
        draw(scout.displayTitle, at: CGPoint(x: margin, y: y + 34), font: .boldSystemFont(ofSize: 20))
        draw("Date seen: \(AppFormatters.date.string(from: scout.dateSeen))", at: CGPoint(x: margin, y: y + 60), font: .systemFont(ofSize: 11), color: .darkGray)
        y += 88

        y = drawImageGrid(paths: scout.imageLocalPaths, startY: y, contentWidth: contentWidth)
        y += 18

        y = drawTable([
            ("Category", scout.category),
            ("Status", scout.status),
            ("Store", scout.storeName),
            ("Location", scout.locationLabel),
            ("Observed price", AppFormatters.money(scout.observedStorePrice, currency: scout.currency)),
            ("Purchase estimate", AppFormatters.money(scout.estimatedPurchasePrice, currency: scout.currency)),
            ("Sale estimate", AppFormatters.money(scout.estimatedSalePrice, currency: scout.currency)),
            ("Gross profit", AppFormatters.money(scout.estimatedGrossProfit, currency: scout.currency)),
            ("Margin", AppFormatters.percent(scout.estimatedMarginPercent))
        ], startY: y, context: context, pageRect: pageRect, title: "Scout Details")
        y += 16

        if hasDetectedValues(scout) {
            y = drawTable([
                ("Price candidates", scout.detectedPriceCandidates.joined(separator: ", ")),
                ("Barcode", scout.detectedBarcode ?? ""),
                ("Weight", scout.detectedWeight ?? ""),
                ("Dimensions", scout.detectedDimensions ?? "")
            ], startY: y, context: context, pageRect: pageRect, title: "Detected Helper Values")
            y += 16
        }

        if !scout.productDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            drawSection("Short Description", body: scout.productDescription, y: &y, context: context, pageRect: pageRect, width: contentWidth)
        }
        drawSection("Notes", body: scout.notes.isEmpty ? "No notes." : scout.notes, y: &y, context: context, pageRect: pageRect, width: contentWidth)
    }

    private static func beginPage(_ context: UIGraphicsPDFRendererContext, _ pageRect: CGRect) {
        context.beginPage()
        UIColor.systemBackground.setFill()
        context.fill(pageRect)
    }

    private static func drawTable(
        _ rows: [(String, String)],
        startY: CGFloat,
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        title: String
    ) -> CGFloat {
        var y = startY
        if y > pageRect.maxY - 88 {
            beginPage(context, pageRect)
            y = 42
        }
        draw(title, at: CGPoint(x: 40, y: y), font: .boldSystemFont(ofSize: 14))
        y += 22
        for row in rows {
            if y > pageRect.maxY - 72 {
                beginPage(context, pageRect)
                y = 42
            }
            UIColor.separator.setStroke()
            UIBezierPath(rect: CGRect(x: 40, y: y - 7, width: 515, height: 1)).stroke()
            draw(row.0, at: CGPoint(x: 40, y: y), font: .boldSystemFont(ofSize: 10), color: .darkGray)
            draw(row.1.isEmpty ? "Not set" : row.1, at: CGPoint(x: 190, y: y), font: .systemFont(ofSize: 11))
            y += 24
        }
        return y
    }

    private static func drawImageGrid(paths: [String], startY: CGFloat, contentWidth: CGFloat) -> CGFloat {
        let images = paths.prefix(ProductScout.maxImageCount).compactMap { ImageStorageService.load(path: $0) }
        guard !images.isEmpty else {
            drawMultiline("No product images attached.", in: CGRect(x: 40, y: startY, width: contentWidth, height: 32), font: .systemFont(ofSize: 11), color: .darkGray)
            return startY + 42
        }

        let gap: CGFloat = 8
        let cellWidth = (contentWidth - gap) / 2
        let frames: [CGRect]
        switch images.count {
        case 1:
            frames = [CGRect(x: 40, y: startY, width: contentWidth, height: 230)]
        case 2:
            frames = [
                CGRect(x: 40, y: startY, width: cellWidth, height: 180),
                CGRect(x: 40 + cellWidth + gap, y: startY, width: cellWidth, height: 180)
            ]
        case 3:
            frames = [
                CGRect(x: 40, y: startY, width: contentWidth, height: 190),
                CGRect(x: 40, y: startY + 198, width: cellWidth, height: 150),
                CGRect(x: 40 + cellWidth + gap, y: startY + 198, width: cellWidth, height: 150)
            ]
        default:
            frames = [
                CGRect(x: 40, y: startY, width: cellWidth, height: 150),
                CGRect(x: 40 + cellWidth + gap, y: startY, width: cellWidth, height: 150),
                CGRect(x: 40, y: startY + 158, width: cellWidth, height: 150),
                CGRect(x: 40 + cellWidth + gap, y: startY + 158, width: cellWidth, height: 150)
            ]
        }

        for (image, frame) in zip(images, frames) {
            UIColor.separator.setStroke()
            UIBezierPath(roundedRect: frame, cornerRadius: 8).stroke()
            drawAspectFill(image, in: frame.insetBy(dx: 1, dy: 1), cornerRadius: 8)
        }
        return (frames.map(\.maxY).max() ?? startY) + 2
    }

    private static func drawSection(
        _ title: String,
        body: String,
        y: inout CGFloat,
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        width: CGFloat
    ) {
        let measuredHeight = max(44, multilineHeight(for: body, width: width, font: .systemFont(ofSize: 11)))
        let requiredHeight = 20 + measuredHeight + 12
        if y + requiredHeight > pageRect.maxY - 42 {
            beginPage(context, pageRect)
            y = 42
        }
        draw(title, at: CGPoint(x: 40, y: y), font: .boldSystemFont(ofSize: 14))
        y += 20
        drawMultiline(body, in: CGRect(x: 40, y: y, width: width, height: measuredHeight), font: .systemFont(ofSize: 11), color: .darkGray)
        y += measuredHeight + 12
    }

    private static func hasDetectedValues(_ scout: ProductScout) -> Bool {
        !scout.detectedPriceCandidates.isEmpty ||
            scout.detectedBarcode != nil ||
            scout.detectedWeight != nil ||
            scout.detectedDimensions != nil
    }

    private static func draw(_ text: String, at point: CGPoint, font: UIFont, color: UIColor = .label) {
        (text as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
    }

    private static func drawMultiline(_ text: String, in rect: CGRect, font: UIFont, color: UIColor = .label) {
        (text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font, .foregroundColor: color], context: nil)
    }

    private static func multilineHeight(for text: String, width: CGFloat, font: UIFont) -> CGFloat {
        let bounds = (text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(bounds.height)
    }

    private static func drawAspectFill(_ image: UIImage, in rect: CGRect, cornerRadius: CGFloat) {
        guard image.size.width > 0, image.size.height > 0 else { return }
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        defer { context?.restoreGState() }
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
        let scale = max(rect.width / image.size.width, rect.height / image.size.height)
        let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        image.draw(in: CGRect(x: rect.midX - drawSize.width / 2, y: rect.midY - drawSize.height / 2, width: drawSize.width, height: drawSize.height))
    }
}
