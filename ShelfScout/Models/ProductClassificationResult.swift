import Foundation

// Placeholder - Classification functionality has been removed
struct ProductClassificationResult: Codable, Equatable {
    var suggestedCategory: String?
    var suggestedTags: [String]
    var suggestedRiskIndicators: [String]
    var topLabels: [ClassificationLabel]
    var confidence: Double
    var createdAt: Date
}

