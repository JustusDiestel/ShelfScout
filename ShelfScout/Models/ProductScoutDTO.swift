import Foundation

struct ProductScoutDTO: Codable, Identifiable, Equatable {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date

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

    var productPhotoLocalPath: String?
    var productPhotoJPEGBase64: String?
    var imageLocalPaths: [String]
    var productPhotoJPEGBase64s: [String]
    var primaryImageIndex: Int

    var recognizedText: String
    var recognizedTextsByImageJSON: String
    var combinedRecognizedText: String
    var ocrLastRunAt: Date?
    var detectedPriceCandidatesJSON: String
    var detectedBarcode: String?
    var detectedWeight: String?
    var detectedDimensions: String?

    init(from scout: ProductScout, photoBase64: String? = nil) {
        id = scout.id
        createdAt = scout.createdAt
        updatedAt = scout.updatedAt
        title = scout.title
        category = scout.category
        productDescription = scout.productDescription
        notes = scout.notes
        status = scout.status
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
        imageLocalPaths = scout.imageLocalPaths
        productPhotoJPEGBase64s = ImageStorageService.jpegBase64s(paths: scout.imageLocalPaths)
        primaryImageIndex = scout.primaryImageIndex
        recognizedText = scout.recognizedText
        recognizedTextsByImageJSON = scout.recognizedTextsByImageJSON
        combinedRecognizedText = scout.combinedRecognizedText.isEmpty ? scout.recognizedText : scout.combinedRecognizedText
        ocrLastRunAt = scout.ocrLastRunAt
        detectedPriceCandidatesJSON = scout.detectedPriceCandidatesJSON
        detectedBarcode = scout.detectedBarcode
        detectedWeight = scout.detectedWeight
        detectedDimensions = scout.detectedDimensions
    }

    func makeModel(photoPath: String? = nil, imagePaths: [String] = []) -> ProductScout {
        let restoredImagePaths = imagePaths.isEmpty ? (photoPath.map { [$0] } ?? []) : imagePaths

        return ProductScout(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            productPhotoLocalPath: restoredImagePaths.first ?? photoPath ?? productPhotoLocalPath,
            imageLocalPathsJSON: ProductScout.encodeJSON(restoredImagePaths),
            primaryImageIndex: min(max(primaryImageIndex, 0), max(restoredImagePaths.count - 1, 0)),
            title: title,
            category: category,
            productDescription: productDescription,
            notes: notes,
            status: status,
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
            recognizedText: recognizedText,
            recognizedTextsByImageJSON: recognizedTextsByImageJSON,
            combinedRecognizedText: combinedRecognizedText,
            ocrLastRunAt: ocrLastRunAt,
            detectedPriceCandidatesJSON: detectedPriceCandidatesJSON,
            detectedBarcode: detectedBarcode,
            detectedWeight: detectedWeight,
            detectedDimensions: detectedDimensions
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case updatedAt

        case title
        case category
        case productDescription
        case shortDescription
        case notes
        case status

        case storeName
        case locationLabel
        case latitude
        case longitude
        case locationPermissionUsed
        case dateSeen

        case observedStorePrice
        case estimatedPurchasePrice
        case estimatedSalePrice
        case currency

        case productPhotoLocalPath
        case productPhotoJPEGBase64
        case imageLocalPaths
        case productPhotoJPEGBase64s
        case primaryImageIndex

        case recognizedText
        case recognizedTextsByImageJSON
        case combinedRecognizedText
        case ocrLastRunAt
        case detectedPriceCandidatesJSON
        case detectedBarcode
        case detectedBarcodeOrEAN
        case detectedWeight
        case detectedDimensions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt

        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""

        productDescription = try container.decodeIfPresent(String.self, forKey: .productDescription)
            ?? container.decodeIfPresent(String.self, forKey: .shortDescription)
            ?? ""

        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? ProductScoutStatus.interesting.rawValue

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

        imageLocalPaths = try container.decodeIfPresent([String].self, forKey: .imageLocalPaths)
            ?? productPhotoLocalPath.map { [$0] }
            ?? []

        let decodedBase64s = try container.decodeIfPresent([String].self, forKey: .productPhotoJPEGBase64s)
        productPhotoJPEGBase64s = decodedBase64s ?? productPhotoJPEGBase64.map { [$0] } ?? []

        primaryImageIndex = try container.decodeIfPresent(Int.self, forKey: .primaryImageIndex) ?? 0

        recognizedText = try container.decodeIfPresent(String.self, forKey: .recognizedText) ?? ""
        recognizedTextsByImageJSON = try container.decodeIfPresent(String.self, forKey: .recognizedTextsByImageJSON) ?? ""
        combinedRecognizedText = try container.decodeIfPresent(String.self, forKey: .combinedRecognizedText) ?? recognizedText
        ocrLastRunAt = try container.decodeIfPresent(Date.self, forKey: .ocrLastRunAt)

        detectedPriceCandidatesJSON = try container.decodeIfPresent(String.self, forKey: .detectedPriceCandidatesJSON) ?? ""

        detectedBarcode = try container.decodeIfPresent(String.self, forKey: .detectedBarcode)
            ?? container.decodeIfPresent(String.self, forKey: .detectedBarcodeOrEAN)

        detectedWeight = try container.decodeIfPresent(String.self, forKey: .detectedWeight)
        detectedDimensions = try container.decodeIfPresent(String.self, forKey: .detectedDimensions)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)

        try container.encode(title, forKey: .title)
        try container.encode(category, forKey: .category)
        try container.encode(productDescription, forKey: .productDescription)
        try container.encode(notes, forKey: .notes)
        try container.encode(status, forKey: .status)

        try container.encode(storeName, forKey: .storeName)
        try container.encode(locationLabel, forKey: .locationLabel)
        try container.encodeIfPresent(latitude, forKey: .latitude)
        try container.encodeIfPresent(longitude, forKey: .longitude)
        try container.encode(locationPermissionUsed, forKey: .locationPermissionUsed)
        try container.encode(dateSeen, forKey: .dateSeen)

        try container.encodeIfPresent(observedStorePrice, forKey: .observedStorePrice)
        try container.encodeIfPresent(estimatedPurchasePrice, forKey: .estimatedPurchasePrice)
        try container.encodeIfPresent(estimatedSalePrice, forKey: .estimatedSalePrice)
        try container.encode(currency, forKey: .currency)

        try container.encodeIfPresent(productPhotoLocalPath, forKey: .productPhotoLocalPath)
        try container.encodeIfPresent(productPhotoJPEGBase64, forKey: .productPhotoJPEGBase64)
        try container.encode(imageLocalPaths, forKey: .imageLocalPaths)
        try container.encode(productPhotoJPEGBase64s, forKey: .productPhotoJPEGBase64s)
        try container.encode(primaryImageIndex, forKey: .primaryImageIndex)

        try container.encode(recognizedText, forKey: .recognizedText)
        try container.encode(recognizedTextsByImageJSON, forKey: .recognizedTextsByImageJSON)
        try container.encode(combinedRecognizedText, forKey: .combinedRecognizedText)
        try container.encodeIfPresent(ocrLastRunAt, forKey: .ocrLastRunAt)
        try container.encode(detectedPriceCandidatesJSON, forKey: .detectedPriceCandidatesJSON)
        try container.encodeIfPresent(detectedBarcode, forKey: .detectedBarcode)
        try container.encodeIfPresent(detectedWeight, forKey: .detectedWeight)
        try container.encodeIfPresent(detectedDimensions, forKey: .detectedDimensions)

        // Do not encode legacy aliases:
        // - shortDescription
        // - detectedBarcodeOrEAN
        // They are decode-only keys for backwards compatibility.
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
