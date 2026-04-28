import Foundation
import SwiftData

@Model
final class ProductScout {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var title: String
    var category: String
    var productDescription: String
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
    var productPhotoLocalPath: String?
    var recognizedText: String
    var detectedBarcodeOrEAN: String?
    var notes: String
    var status: String
    var researchQuery: String = ""
    var amazonChecked: Bool = false
    var ebayChecked: Bool = false
    var googleShoppingChecked: Bool = false
    var googleImagesChecked: Bool = false
    var alibabaChecked: Bool = false
    var aliexpressChecked: Bool = false
    var etsyChecked: Bool = false
    var tiktokChecked: Bool = false
    var instagramChecked: Bool = false
    var similarProductsFound: Bool = false
    var estimatedCompetitionLevel: String = CompetitionLevel.unknown.rawValue
    var competitorNotes: String = ""
    var classifierSuggestedCategory: String?
    var classifierSuggestedTags: [String] = []
    var classifierSuggestedRiskIndicators: [String] = []
    var classifierTopLabelsJSON: String = ""
    var classifierConfidence: Double?
    var classifierLastRunAt: Date?

    var isSmallAndLight: Bool
    var isEasyToExplain: Bool
    var hasClearUseCase: Bool
    var hasElectronics: Bool
    var hasBattery: Bool
    var touchesFood: Bool
    var isForChildren: Bool
    var isCosmetic: Bool
    var isMedicalOrHealthRelated: Bool
    var isTextile: Bool
    var isFragile: Bool
    var hasBrandOrDesignRisk: Bool
    var hasManyCompetitors: Bool

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        title: String = "",
        category: String = "",
        productDescription: String = "",
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
        productPhotoLocalPath: String? = nil,
        recognizedText: String = "",
        detectedBarcodeOrEAN: String? = nil,
        notes: String = "",
        status: String = ProductScoutStatus.interesting.rawValue,
        researchQuery: String? = nil,
        amazonChecked: Bool = false,
        ebayChecked: Bool = false,
        googleShoppingChecked: Bool = false,
        googleImagesChecked: Bool = false,
        alibabaChecked: Bool = false,
        aliexpressChecked: Bool = false,
        etsyChecked: Bool = false,
        tiktokChecked: Bool = false,
        instagramChecked: Bool = false,
        similarProductsFound: Bool = false,
        estimatedCompetitionLevel: String = CompetitionLevel.unknown.rawValue,
        competitorNotes: String = "",
        classifierSuggestedCategory: String? = nil,
        classifierSuggestedTags: [String] = [],
        classifierSuggestedRiskIndicators: [String] = [],
        classifierTopLabelsJSON: String = "",
        classifierConfidence: Double? = nil,
        classifierLastRunAt: Date? = nil,
        isSmallAndLight: Bool = false,
        isEasyToExplain: Bool = false,
        hasClearUseCase: Bool = false,
        hasElectronics: Bool = false,
        hasBattery: Bool = false,
        touchesFood: Bool = false,
        isForChildren: Bool = false,
        isCosmetic: Bool = false,
        isMedicalOrHealthRelated: Bool = false,
        isTextile: Bool = false,
        isFragile: Bool = false,
        hasBrandOrDesignRisk: Bool = false,
        hasManyCompetitors: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.category = category
        self.productDescription = productDescription
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
        self.productPhotoLocalPath = productPhotoLocalPath
        self.recognizedText = recognizedText
        self.detectedBarcodeOrEAN = detectedBarcodeOrEAN
        self.notes = notes
        self.status = status
        self.researchQuery = researchQuery ?? ProductScout.defaultResearchQuery(title: title, category: category)
        self.amazonChecked = amazonChecked
        self.ebayChecked = ebayChecked
        self.googleShoppingChecked = googleShoppingChecked
        self.googleImagesChecked = googleImagesChecked
        self.alibabaChecked = alibabaChecked
        self.aliexpressChecked = aliexpressChecked
        self.etsyChecked = etsyChecked
        self.tiktokChecked = tiktokChecked
        self.instagramChecked = instagramChecked
        self.similarProductsFound = similarProductsFound
        self.estimatedCompetitionLevel = CompetitionLevel(rawValue: estimatedCompetitionLevel)?.rawValue ?? CompetitionLevel.unknown.rawValue
        self.competitorNotes = competitorNotes
        self.classifierSuggestedCategory = classifierSuggestedCategory
        self.classifierSuggestedTags = classifierSuggestedTags
        self.classifierSuggestedRiskIndicators = classifierSuggestedRiskIndicators
        self.classifierTopLabelsJSON = classifierTopLabelsJSON
        self.classifierConfidence = classifierConfidence
        self.classifierLastRunAt = classifierLastRunAt
        self.isSmallAndLight = isSmallAndLight
        self.isEasyToExplain = isEasyToExplain
        self.hasClearUseCase = hasClearUseCase
        self.hasElectronics = hasElectronics
        self.hasBattery = hasBattery
        self.touchesFood = touchesFood
        self.isForChildren = isForChildren
        self.isCosmetic = isCosmetic
        self.isMedicalOrHealthRelated = isMedicalOrHealthRelated
        self.isTextile = isTextile
        self.isFragile = isFragile
        self.hasBrandOrDesignRisk = hasBrandOrDesignRisk
        self.hasManyCompetitors = hasManyCompetitors
    }
}

extension ProductScout {
    var estimatedGrossProfit: Decimal? {
        ScoringService.estimatedGrossProfit(purchase: estimatedPurchasePrice, sale: estimatedSalePrice)
    }

    var estimatedMarginPercent: Decimal? {
        ScoringService.estimatedMarginPercent(purchase: estimatedPurchasePrice, sale: estimatedSalePrice)
    }

    var riskLevel: String {
        ScoringService.riskLevel(for: self).rawValue
    }

    var scoutScore: Int {
        ScoringService.score(for: self)
    }

    var beginnerFriendliness: String {
        ScoringService.beginnerFriendliness(for: self)
    }

    var displayTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled scout" : title
    }

    var resolvedResearchQuery: String {
        let trimmed = researchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? ProductScout.defaultResearchQuery(title: title, category: category) : trimmed
    }

    static func defaultResearchQuery(title: String, category: String) -> String {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty { return trimmedTitle }
        return category.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var classifierTopLabels: [ClassificationLabel] {
        guard let data = classifierTopLabelsJSON.data(using: .utf8),
              let labels = try? JSONDecoder().decode([ClassificationLabel].self, from: data) else {
            return []
        }
        return labels
    }

    var hasClassifierSuggestions: Bool {
        classifierSuggestedCategory != nil ||
        !classifierSuggestedTags.isEmpty ||
        !classifierSuggestedRiskIndicators.isEmpty ||
        classifierConfidence != nil ||
        classifierLastRunAt != nil
    }

    func applyClassificationResult(_ result: ProductClassificationResult) {
        classifierSuggestedCategory = result.suggestedCategory
        classifierSuggestedTags = result.suggestedTags
        classifierSuggestedRiskIndicators = result.suggestedRiskIndicators
        classifierConfidence = result.confidence
        classifierLastRunAt = result.createdAt
        if let data = try? JSONEncoder().encode(result.topLabels),
           let json = String(data: data, encoding: .utf8) {
            classifierTopLabelsJSON = json
        } else {
            classifierTopLabelsJSON = ""
        }
    }

    func clearClassificationSuggestions() {
        classifierSuggestedCategory = nil
        classifierSuggestedTags = []
        classifierSuggestedRiskIndicators = []
        classifierTopLabelsJSON = ""
        classifierConfidence = nil
        classifierLastRunAt = nil
    }
}

enum ProductScoutStatus: String, CaseIterable, Identifiable, Codable {
    case interesting = "Interesting"
    case later = "Later"
    case favorite = "Favorite"
    case rejected = "Rejected"

    var id: String { rawValue }
}

enum RiskLevel: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case avoid = "Avoid for beginners"
}

enum CompetitionLevel: String, CaseIterable, Identifiable, Codable {
    case unknown = "Unknown"
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }
}
