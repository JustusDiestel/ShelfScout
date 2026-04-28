import Foundation

struct ProductScoutDTO: Codable, Identifiable, Equatable {
    var id: UUID
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
    var productPhotoJPEGBase64: String?
    var recognizedText: String
    var detectedBarcodeOrEAN: String?
    var notes: String
    var status: String
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
    var similarProductsFound: Bool
    var estimatedCompetitionLevel: String
    var competitorNotes: String
    var classifierSuggestedCategory: String?
    var classifierSuggestedTags: [String]
    var classifierSuggestedRiskIndicators: [String]
    var classifierTopLabelsJSON: String
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

    init(from scout: ProductScout, photoBase64: String? = nil) {
        id = scout.id
        createdAt = scout.createdAt
        updatedAt = scout.updatedAt
        title = scout.title
        category = scout.category
        productDescription = scout.productDescription
        storeName = scout.storeName
        locationLabel = scout.locationLabel
        latitude = scout.latitude
        longitude = scout.longitude
        locationPermissionUsed = scout.locationPermissionUsed
        dateSeen = scout.dateSeen
        observedStorePrice = scout.observedStorePrice
        estimatedPurchasePrice = scout.estimatedPurchasePrice
        estimatedSalePrice = scout.estimatedSalePrice
        currency = scout.currency
        productPhotoLocalPath = scout.productPhotoLocalPath
        productPhotoJPEGBase64 = photoBase64
        recognizedText = scout.recognizedText
        detectedBarcodeOrEAN = scout.detectedBarcodeOrEAN
        notes = scout.notes
        status = scout.status
        researchQuery = scout.resolvedResearchQuery
        amazonChecked = scout.amazonChecked
        ebayChecked = scout.ebayChecked
        googleShoppingChecked = scout.googleShoppingChecked
        googleImagesChecked = scout.googleImagesChecked
        alibabaChecked = scout.alibabaChecked
        aliexpressChecked = scout.aliexpressChecked
        etsyChecked = scout.etsyChecked
        tiktokChecked = scout.tiktokChecked
        instagramChecked = scout.instagramChecked
        similarProductsFound = scout.similarProductsFound
        estimatedCompetitionLevel = scout.estimatedCompetitionLevel
        competitorNotes = scout.competitorNotes
        classifierSuggestedCategory = scout.classifierSuggestedCategory
        classifierSuggestedTags = scout.classifierSuggestedTags
        classifierSuggestedRiskIndicators = scout.classifierSuggestedRiskIndicators
        classifierTopLabelsJSON = scout.classifierTopLabelsJSON
        classifierConfidence = scout.classifierConfidence
        classifierLastRunAt = scout.classifierLastRunAt
        isSmallAndLight = scout.isSmallAndLight
        isEasyToExplain = scout.isEasyToExplain
        hasClearUseCase = scout.hasClearUseCase
        hasElectronics = scout.hasElectronics
        hasBattery = scout.hasBattery
        touchesFood = scout.touchesFood
        isForChildren = scout.isForChildren
        isCosmetic = scout.isCosmetic
        isMedicalOrHealthRelated = scout.isMedicalOrHealthRelated
        isTextile = scout.isTextile
        isFragile = scout.isFragile
        hasBrandOrDesignRisk = scout.hasBrandOrDesignRisk
        hasManyCompetitors = scout.hasManyCompetitors
    }

    func makeModel(photoPath: String? = nil) -> ProductScout {
        ProductScout(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            title: title,
            category: category,
            productDescription: productDescription,
            storeName: storeName,
            locationLabel: locationLabel,
            latitude: latitude,
            longitude: longitude,
            locationPermissionUsed: locationPermissionUsed,
            dateSeen: dateSeen,
            observedStorePrice: observedStorePrice,
            estimatedPurchasePrice: estimatedPurchasePrice,
            estimatedSalePrice: estimatedSalePrice,
            currency: currency,
            productPhotoLocalPath: photoPath ?? productPhotoLocalPath,
            recognizedText: recognizedText,
            detectedBarcodeOrEAN: detectedBarcodeOrEAN,
            notes: notes,
            status: status,
            researchQuery: researchQuery,
            amazonChecked: amazonChecked,
            ebayChecked: ebayChecked,
            googleShoppingChecked: googleShoppingChecked,
            googleImagesChecked: googleImagesChecked,
            alibabaChecked: alibabaChecked,
            aliexpressChecked: aliexpressChecked,
            etsyChecked: etsyChecked,
            tiktokChecked: tiktokChecked,
            instagramChecked: instagramChecked,
            similarProductsFound: similarProductsFound,
            estimatedCompetitionLevel: estimatedCompetitionLevel,
            competitorNotes: competitorNotes,
            classifierSuggestedCategory: classifierSuggestedCategory,
            classifierSuggestedTags: classifierSuggestedTags,
            classifierSuggestedRiskIndicators: classifierSuggestedRiskIndicators,
            classifierTopLabelsJSON: classifierTopLabelsJSON,
            classifierConfidence: classifierConfidence,
            classifierLastRunAt: classifierLastRunAt,
            isSmallAndLight: isSmallAndLight,
            isEasyToExplain: isEasyToExplain,
            hasClearUseCase: hasClearUseCase,
            hasElectronics: hasElectronics,
            hasBattery: hasBattery,
            touchesFood: touchesFood,
            isForChildren: isForChildren,
            isCosmetic: isCosmetic,
            isMedicalOrHealthRelated: isMedicalOrHealthRelated,
            isTextile: isTextile,
            isFragile: isFragile,
            hasBrandOrDesignRisk: hasBrandOrDesignRisk,
            hasManyCompetitors: hasManyCompetitors
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, createdAt, updatedAt, title, category, productDescription, storeName, locationLabel
        case latitude, longitude, locationPermissionUsed, dateSeen, observedStorePrice
        case estimatedPurchasePrice, estimatedSalePrice, currency, productPhotoLocalPath
        case productPhotoJPEGBase64, recognizedText, detectedBarcodeOrEAN, notes, status
        case researchQuery, amazonChecked, ebayChecked, googleShoppingChecked, googleImagesChecked
        case alibabaChecked, aliexpressChecked, etsyChecked, tiktokChecked, instagramChecked
        case similarProductsFound, estimatedCompetitionLevel, competitorNotes
        case classifierSuggestedCategory, classifierSuggestedTags, classifierSuggestedRiskIndicators
        case classifierTopLabelsJSON, classifierConfidence, classifierLastRunAt
        case isSmallAndLight, isEasyToExplain, hasClearUseCase, hasElectronics, hasBattery
        case touchesFood, isForChildren, isCosmetic, isMedicalOrHealthRelated, isTextile
        case isFragile, hasBrandOrDesignRisk, hasManyCompetitors
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        productDescription = try container.decodeIfPresent(String.self, forKey: .productDescription) ?? ""
        storeName = try container.decodeIfPresent(String.self, forKey: .storeName) ?? ""
        locationLabel = try container.decodeIfPresent(String.self, forKey: .locationLabel) ?? ""
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        locationPermissionUsed = try container.decodeIfPresent(Bool.self, forKey: .locationPermissionUsed) ?? false
        dateSeen = try container.decodeIfPresent(Date.self, forKey: .dateSeen) ?? Date()
        observedStorePrice = try container.decodeIfPresent(Decimal.self, forKey: .observedStorePrice)
        estimatedPurchasePrice = try container.decodeIfPresent(Decimal.self, forKey: .estimatedPurchasePrice)
        estimatedSalePrice = try container.decodeIfPresent(Decimal.self, forKey: .estimatedSalePrice)
        currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "USD"
        productPhotoLocalPath = try container.decodeIfPresent(String.self, forKey: .productPhotoLocalPath)
        productPhotoJPEGBase64 = try container.decodeIfPresent(String.self, forKey: .productPhotoJPEGBase64)
        recognizedText = try container.decodeIfPresent(String.self, forKey: .recognizedText) ?? ""
        detectedBarcodeOrEAN = try container.decodeIfPresent(String.self, forKey: .detectedBarcodeOrEAN)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? ProductScoutStatus.interesting.rawValue
        researchQuery = try container.decodeIfPresent(String.self, forKey: .researchQuery)
            ?? ProductScout.defaultResearchQuery(title: title, category: category)
        amazonChecked = try container.decodeIfPresent(Bool.self, forKey: .amazonChecked) ?? false
        ebayChecked = try container.decodeIfPresent(Bool.self, forKey: .ebayChecked) ?? false
        googleShoppingChecked = try container.decodeIfPresent(Bool.self, forKey: .googleShoppingChecked) ?? false
        googleImagesChecked = try container.decodeIfPresent(Bool.self, forKey: .googleImagesChecked) ?? false
        alibabaChecked = try container.decodeIfPresent(Bool.self, forKey: .alibabaChecked) ?? false
        aliexpressChecked = try container.decodeIfPresent(Bool.self, forKey: .aliexpressChecked) ?? false
        etsyChecked = try container.decodeIfPresent(Bool.self, forKey: .etsyChecked) ?? false
        tiktokChecked = try container.decodeIfPresent(Bool.self, forKey: .tiktokChecked) ?? false
        instagramChecked = try container.decodeIfPresent(Bool.self, forKey: .instagramChecked) ?? false
        similarProductsFound = try container.decodeIfPresent(Bool.self, forKey: .similarProductsFound) ?? false
        let competitionLevel = try container.decodeIfPresent(String.self, forKey: .estimatedCompetitionLevel) ?? CompetitionLevel.unknown.rawValue
        estimatedCompetitionLevel = CompetitionLevel(rawValue: competitionLevel)?.rawValue ?? CompetitionLevel.unknown.rawValue
        competitorNotes = try container.decodeIfPresent(String.self, forKey: .competitorNotes) ?? ""
        classifierSuggestedCategory = try container.decodeIfPresent(String.self, forKey: .classifierSuggestedCategory)
        classifierSuggestedTags = try container.decodeIfPresent([String].self, forKey: .classifierSuggestedTags) ?? []
        classifierSuggestedRiskIndicators = try container.decodeIfPresent([String].self, forKey: .classifierSuggestedRiskIndicators) ?? []
        classifierTopLabelsJSON = try container.decodeIfPresent(String.self, forKey: .classifierTopLabelsJSON) ?? ""
        classifierConfidence = try container.decodeIfPresent(Double.self, forKey: .classifierConfidence)
        classifierLastRunAt = try container.decodeIfPresent(Date.self, forKey: .classifierLastRunAt)
        isSmallAndLight = try container.decodeIfPresent(Bool.self, forKey: .isSmallAndLight) ?? false
        isEasyToExplain = try container.decodeIfPresent(Bool.self, forKey: .isEasyToExplain) ?? false
        hasClearUseCase = try container.decodeIfPresent(Bool.self, forKey: .hasClearUseCase) ?? false
        hasElectronics = try container.decodeIfPresent(Bool.self, forKey: .hasElectronics) ?? false
        hasBattery = try container.decodeIfPresent(Bool.self, forKey: .hasBattery) ?? false
        touchesFood = try container.decodeIfPresent(Bool.self, forKey: .touchesFood) ?? false
        isForChildren = try container.decodeIfPresent(Bool.self, forKey: .isForChildren) ?? false
        isCosmetic = try container.decodeIfPresent(Bool.self, forKey: .isCosmetic) ?? false
        isMedicalOrHealthRelated = try container.decodeIfPresent(Bool.self, forKey: .isMedicalOrHealthRelated) ?? false
        isTextile = try container.decodeIfPresent(Bool.self, forKey: .isTextile) ?? false
        isFragile = try container.decodeIfPresent(Bool.self, forKey: .isFragile) ?? false
        hasBrandOrDesignRisk = try container.decodeIfPresent(Bool.self, forKey: .hasBrandOrDesignRisk) ?? false
        hasManyCompetitors = try container.decodeIfPresent(Bool.self, forKey: .hasManyCompetitors) ?? false
    }
}

struct ShelfScoutDocument: Codable, Equatable {
    var schemaVersion: Int
    var app: String
    var product: ProductScoutDTO

    init(product: ProductScoutDTO) {
        schemaVersion = 1
        app = "ShelfScout"
        self.product = product
    }
}

struct ShelfScoutArchive: Codable, Equatable {
    var schemaVersion: Int
    var app: String
    var products: [ProductScoutDTO]

    init(products: [ProductScoutDTO]) {
        schemaVersion = 1
        app = "ShelfScout"
        self.products = products
    }
}
