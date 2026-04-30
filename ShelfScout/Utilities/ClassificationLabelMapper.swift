import Foundation

// Placeholder - Classification functionality has been removed
enum ClassificationLabelMapper {
    static func map(labels: [ClassificationLabel]) -> ProductClassificationResult {
        return ProductClassificationResult(
            suggestedCategory: nil,
            suggestedTags: [],
            suggestedRiskIndicators: [],
            topLabels: [],
            confidence: 0,
            createdAt: Date()
        )
    }
}

