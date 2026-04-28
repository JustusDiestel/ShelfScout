import UIKit

enum ImageCardExportService {
    static func writeImageCard(for scout: ProductScout) throws -> URL {
        let image = makeImageCard(for: scout)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(scout.displayTitle) Share Card.jpg")
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw AppError.message("The share image could not be generated.")
        }
        try data.write(to: url, options: .atomic)
        return url
    }

    static func makeImageCard(for scout: ProductScout) -> UIImage {
        let size = CGSize(width: 1080, height: 1350)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let padding: CGFloat = 72
            let photoRect = CGRect(x: padding, y: 72, width: 936, height: 560)
            if let photo = ImageStorageService.load(path: scout.productPhotoLocalPath) {
                photo.draw(in: photoRect)
            } else {
                UIColor.secondarySystemBackground.setFill()
                UIBezierPath(roundedRect: photoRect, cornerRadius: 24).fill()
                draw("No Photo", in: photoRect.insetBy(dx: 24, dy: 240), font: .systemFont(ofSize: 40), color: .secondaryLabel)
            }

            draw("ShelfScout", at: CGPoint(x: padding, y: 680), font: .boldSystemFont(ofSize: 34), color: .secondaryLabel)
            draw(scout.displayTitle, in: CGRect(x: padding, y: 735, width: 936, height: 140), font: .boldSystemFont(ofSize: 58))
            draw("Score \(scout.scoutScore)/100", at: CGPoint(x: padding, y: 910), font: .boldSystemFont(ofSize: 46))
            draw("Risk: \(scout.riskLevel)", at: CGPoint(x: 560, y: 910), font: .boldSystemFont(ofSize: 46))
            draw("Observed: \(AppFormatters.money(scout.observedStorePrice, currency: scout.currency))", at: CGPoint(x: padding, y: 1015), font: .systemFont(ofSize: 38))
            draw("Sale estimate: \(AppFormatters.money(scout.estimatedSalePrice, currency: scout.currency))", at: CGPoint(x: padding, y: 1075), font: .systemFont(ofSize: 38))
            draw(scout.notes.isEmpty ? "Local scouting estimate for later review." : scout.notes, in: CGRect(x: padding, y: 1160, width: 936, height: 110), font: .systemFont(ofSize: 32), color: .secondaryLabel)
        }
    }

    private static func draw(_ text: String, at point: CGPoint, font: UIFont, color: UIColor = .label) {
        (text as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
    }

    private static func draw(_ text: String, in rect: CGRect, font: UIFont, color: UIColor = .label) {
        (text as NSString).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font, .foregroundColor: color], context: nil)
    }
}
