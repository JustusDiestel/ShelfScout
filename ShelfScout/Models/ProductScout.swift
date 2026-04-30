import Foundation
import SwiftData

@Model
final class ProductScout {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date

    var productPhotoLocalPath: String?
    var imageLocalPathsJSON: String
    var primaryImageIndex: Int

    var title: String
    var category: String
    var productDescription: String
    var notes: String
    var status: String

    var storeName: String
    var locationLabel: String
    var latitude: Double?
    var longitude: Double?
    var locationPermissionUsed: Bool
    var dateSeen: Date

    var observedStorePrice: Decimal?
    var estimatedPurchasePrice: Decimal?
    var estimatedSalePrice: Decimal?
    var currency: String

    var recognizedText: String
    var recognizedTextsByImageJSON: String
    var combinedRecognizedText: String
    var ocrLastRunAt: Date?
    var detectedPriceCandidatesJSON: String
    var detectedBarcode: String?
    var detectedWeight: String?
    var detectedDimensions: String?

    var researchQuery: String
    var amazonChecked: Bool
    var ebayChecked: Bool
    var googleShoppingChecked: Bool
    var googleImagesChecked: Bool
    var alibabaChecked: Bool
    var aliexpressChecked: Bool
    var etsyChecked: Bool
    var tiktokChecked: Bool
    var instagramChecked: Bool

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        productPhotoLocalPath: String? = nil,
        imageLocalPathsJSON: String = "",
        primaryImageIndex: Int = 0,
        title: String = "",
        category: String = "",
        productDescription: String = "",
        notes: String = "",
        status: String = ProductScoutStatus.interesting.rawValue,
        storeName: String = "",
        locationLabel: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationPermissionUsed: Bool = false,
        dateSeen: Date = Date(),
        observedStorePrice: Decimal? = nil,
        estimatedPurchasePrice: Decimal? = nil,
        estimatedSalePrice: Decimal? = nil,
        currency: String = Locale.current.currency?.identifier ?? "USD",
        recognizedText: String = "",
        recognizedTextsByImageJSON: String = "",
        combinedRecognizedText: String = "",
        ocrLastRunAt: Date? = nil,
        detectedPriceCandidatesJSON: String = "",
        detectedBarcode: String? = nil,
        detectedWeight: String? = nil,
        detectedDimensions: String? = nil,
        researchQuery: String = "",
        amazonChecked: Bool = false,
        ebayChecked: Bool = false,
        googleShoppingChecked: Bool = false,
        googleImagesChecked: Bool = false,
        alibabaChecked: Bool = false,
        aliexpressChecked: Bool = false,
        etsyChecked: Bool = false,
        tiktokChecked: Bool = false,
        instagramChecked: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.productPhotoLocalPath = productPhotoLocalPath
        self.imageLocalPathsJSON = imageLocalPathsJSON
        self.primaryImageIndex = primaryImageIndex
        self.title = title
        self.category = category
        self.productDescription = productDescription
        self.notes = notes
        self.status = status
        self.storeName = storeName
        self.locationLabel = locationLabel
        self.latitude = latitude
        self.longitude = longitude
        self.locationPermissionUsed = locationPermissionUsed
        self.dateSeen = dateSeen
        self.observedStorePrice = observedStorePrice
        self.estimatedPurchasePrice = estimatedPurchasePrice
        self.estimatedSalePrice = estimatedSalePrice
        self.currency = currency
        self.recognizedText = recognizedText
        self.recognizedTextsByImageJSON = recognizedTextsByImageJSON
        self.combinedRecognizedText = combinedRecognizedText.isEmpty ? recognizedText : combinedRecognizedText
        self.ocrLastRunAt = ocrLastRunAt
        self.detectedPriceCandidatesJSON = detectedPriceCandidatesJSON
        self.detectedBarcode = detectedBarcode
        self.detectedWeight = detectedWeight
        self.detectedDimensions = detectedDimensions
        self.researchQuery = researchQuery
        self.amazonChecked = amazonChecked
        self.ebayChecked = ebayChecked
        self.googleShoppingChecked = googleShoppingChecked
        self.googleImagesChecked = googleImagesChecked
        self.alibabaChecked = alibabaChecked
        self.aliexpressChecked = aliexpressChecked
        self.etsyChecked = etsyChecked
        self.tiktokChecked = tiktokChecked
        self.instagramChecked = instagramChecked
    }
}

extension ProductScout {
    static let maxImageCount = 4

    var estimatedGrossProfit: Decimal? {
        ScoringService.estimatedGrossProfit(purchase: estimatedPurchasePrice, sale: estimatedSalePrice)
    }

    var estimatedMarginPercent: Decimal? {
        ScoringService.estimatedMarginPercent(purchase: estimatedPurchasePrice, sale: estimatedSalePrice)
    }

    var displayTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled scout" : title
    }

    var imageLocalPaths: [String] {
        let paths = decodedImageLocalPaths()
        if !paths.isEmpty { return paths }
        return productPhotoLocalPath.map { [$0] } ?? []
    }

    var primaryImagePath: String? {
        let paths = imageLocalPaths
        guard !paths.isEmpty else { return nil }
        let safeIndex = min(max(primaryImageIndex, 0), paths.count - 1)
        return paths[safeIndex]
    }

    var imageCountText: String {
        "Images \(imageLocalPaths.count)/\(Self.maxImageCount)"
    }

    var recognizedTextsByImage: [String] {
        decodeJSON([String].self, from: recognizedTextsByImageJSON) ?? []
    }

    var detectedPriceCandidates: [String] {
        decodeJSON([String].self, from: detectedPriceCandidatesJSON) ?? []
    }

    func setImageLocalPaths(_ paths: [String]) {
        let limited = Array(paths.prefix(Self.maxImageCount))
        imageLocalPathsJSON = Self.encodeJSON(limited)
        if limited.isEmpty {
            productPhotoLocalPath = nil
            primaryImageIndex = 0
        } else {
            primaryImageIndex = min(max(primaryImageIndex, 0), limited.count - 1)
            productPhotoLocalPath = limited[primaryImageIndex]
        }
    }

    func addImageLocalPath(_ path: String) {
        guard imageLocalPaths.count < Self.maxImageCount else { return }
        setImageLocalPaths(imageLocalPaths + [path])
    }

    func removeImage(at index: Int) -> String? {
        var paths = imageLocalPaths
        guard paths.indices.contains(index) else { return nil }
        let removed = paths.remove(at: index)
        if primaryImageIndex >= paths.count {
            primaryImageIndex = max(paths.count - 1, 0)
        }
        setImageLocalPaths(paths)
        return removed
    }

    func moveImage(from source: IndexSet, to destination: Int) {
        var paths = imageLocalPaths
        paths.move(fromOffsets: source, toOffset: destination)
        primaryImageIndex = 0
        setImageLocalPaths(paths)
    }

    func setPrimaryImage(at index: Int) {
        var paths = imageLocalPaths
        guard paths.indices.contains(index) else { return }
        let primary = paths.remove(at: index)
        paths.insert(primary, at: 0)
        primaryImageIndex = 0
        setImageLocalPaths(paths)
    }

    func setRecognizedTextsByImage(_ texts: [String]) {
        recognizedTextsByImageJSON = Self.encodeJSON(texts)
        let combined = texts.enumerated().map { index, text in
            "Image \(index + 1)\n\(text.trimmingCharacters(in: .whitespacesAndNewlines))"
        }
        .joined(separator: "\n\n")
        recognizedText = combined
        combinedRecognizedText = combined
    }

    func setDetectedPriceCandidates(_ candidates: [String]) {
        detectedPriceCandidatesJSON = Self.encodeJSON(candidates.removingDuplicates())
    }

    private func decodedImageLocalPaths() -> [String] {
        decodeJSON([String].self, from: imageLocalPathsJSON).map { Array($0.prefix(Self.maxImageCount)) } ?? []
    }

    private func decodeJSON<T: Decodable>(_ type: T.Type, from json: String) -> T? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func encodeJSON<T: Encodable>(_ value: T) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let json = String(data: data, encoding: .utf8) else {
            return ""
        }
        return json
    }
}

enum ProductScoutStatus: String, CaseIterable, Identifiable, Codable {
    case interesting = "Interesting"
    case later = "Later"
    case favorite = "Favorite"
    case rejected = "Rejected"

    var id: String { rawValue }
}

enum ProductCategory: String, CaseIterable, Identifiable, Codable {
    case home = "Home"
    case kitchen = "Kitchen"
    case office = "Office"
    case beauty = "Beauty"
    case textile = "Textile"
    case electronics = "Electronics"
    case toy = "Toy"
    case sports = "Sports"
    case pet = "Pet"
    case tool = "Tool"
    case car = "Car"
    case travel = "Travel"
    case garden = "Garden"
    case other = "Other"

    var id: String { rawValue }
}
