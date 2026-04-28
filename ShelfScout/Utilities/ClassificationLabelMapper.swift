import Foundation

enum ClassificationLabelMapper {
    static func map(labels: [ClassificationLabel]) -> ProductClassificationResult {
        let category = suggestedCategory(from: labels)
        let risks = suggestedRiskIndicators(from: labels)
        let tags = suggestedTags(from: labels, category: category, risks: risks)
        return ProductClassificationResult(
            suggestedCategory: category,
            suggestedTags: tags,
            suggestedRiskIndicators: risks,
            topLabels: labels,
            confidence: labels.first?.confidence ?? 0,
            createdAt: Date()
        )
    }

    static func suggestedCategory(from labels: [ClassificationLabel]) -> String? {
        let text = combined(labels)
        let mappings: [(String, [String])] = [
            ("Electronics", ["laptop", "charger", "remote", "speaker", "headphones", "phone", "camera", "computer", "keyboard"]),
            ("Kitchen", ["bottle", "cup", "plate", "spoon", "lunchbox", "kitchen", "jar", "mug", "pan"]),
            ("Toy", ["toy", "doll", "teddy", "puzzle", "game"]),
            ("Textile", ["shirt", "shoe", "bag", "fabric", "textile", "cloth", "dress"]),
            ("Beauty", ["perfume", "lipstick", "cream", "makeup", "cosmetic"]),
            ("Sports", ["ball", "sport", "fitness", "yoga"]),
            ("Pet", ["pet", "dog", "cat"]),
            ("Tool", ["tool", "hammer", "drill", "screwdriver"]),
            ("Car", ["car", "auto", "vehicle"]),
            ("Travel", ["travel", "suitcase", "luggage"]),
            ("Garden", ["garden", "plant", "watering"]),
            ("Office", ["office", "pen", "desk", "notebook"]),
            ("Home", ["home", "lamp", "vase", "decor", "furniture"])
        ]

        return mappings.first { _, keywords in
            keywords.contains { text.contains($0) }
        }?.0 ?? (labels.isEmpty ? nil : "Other")
    }

    static func suggestedRiskIndicators(from labels: [ClassificationLabel]) -> [String] {
        let text = combined(labels)
        var indicators: [String] = []
        if containsAny(text, ["laptop", "charger", "remote", "speaker", "headphones", "phone", "electronic"]) {
            indicators.append("possibleElectronics")
        }
        if containsAny(text, ["battery", "charger", "power bank", "remote"]) {
            indicators.append("possibleBattery")
        }
        if containsAny(text, ["bottle", "cup", "plate", "spoon", "lunchbox", "jar", "mug"]) {
            indicators.append("possibleFoodContact")
        }
        if containsAny(text, ["toy", "doll", "teddy", "puzzle"]) {
            indicators.append("possibleChildrenProduct")
        }
        if containsAny(text, ["perfume", "lipstick", "cream", "makeup", "cosmetic"]) {
            indicators.append("possibleCosmetic")
        }
        if containsAny(text, ["shirt", "shoe", "bag", "fabric", "textile", "cloth", "dress"]) {
            indicators.append("possibleTextile")
        }
        if containsAny(text, ["glass", "ceramic", "vase", "mirror"]) {
            indicators.append("possibleFragile")
        }
        if containsAny(text, ["logo", "brand", "character"]) {
            indicators.append("possibleBrandDesignRisk")
        }
        return indicators.removingDuplicates()
    }

    private static func suggestedTags(from labels: [ClassificationLabel], category: String?, risks: [String]) -> [String] {
        let labelTags = labels.prefix(3).map { $0.label.lowercased() }
        return ([category?.lowercased()] + labelTags + risks.map { $0.replacingOccurrences(of: "possible", with: "").lowercased() })
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .removingDuplicates()
    }

    private static func combined(_ labels: [ClassificationLabel]) -> String {
        labels.map(\.label).joined(separator: " ").lowercased()
    }

    private static func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
}
