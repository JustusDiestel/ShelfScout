import Foundation

enum ScoringService {
    static func estimatedGrossProfit(purchase: Decimal?, sale: Decimal?) -> Decimal? {
        guard let purchase, let sale else { return nil }
        return sale - purchase
    }

    static func estimatedMarginPercent(purchase: Decimal?, sale: Decimal?) -> Decimal? {
        guard let profit = estimatedGrossProfit(purchase: purchase, sale: sale), let sale, sale > 0 else {
            return nil
        }
        return (profit / sale) * 100
    }

    static func score(for scout: ProductScout) -> Int {
        var score = 50

        if scout.hasClearUseCase { score += 8 }
        if scout.isEasyToExplain { score += 8 }
        if scout.isSmallAndLight { score += 7 }

        if let observed = scout.observedStorePrice {
            if observed <= 5 { score += 6 }
            else if observed <= 15 { score += 3 }
            else if observed >= 75 { score -= 5 }
        }

        if let margin = scout.estimatedMarginPercent {
            if margin >= 50 { score += 12 }
            else if margin >= 30 { score += 8 }
            else if margin >= 15 { score += 4 }
            else if margin >= 0 { score -= 4 }
            else { score -= 14 }
        }

        if !scout.hasElectronics { score += 3 } else { score -= 10 }
        if !scout.hasBattery { score += 3 } else { score -= 10 }
        if !scout.touchesFood { score += 3 } else { score -= 12 }
        if !scout.isForChildren { score += 3 } else { score -= 13 }
        if !scout.isCosmetic { score += 3 } else { score -= 12 }
        if !scout.isMedicalOrHealthRelated { score += 3 } else { score -= 16 }
        if scout.isTextile { score -= 7 }
        if !scout.isFragile { score += 3 } else { score -= 8 }
        if !scout.hasBrandOrDesignRisk { score += 4 } else { score -= 14 }
        if scout.hasManyCompetitors { score -= 6 }

        return min(100, max(0, score))
    }

    static func riskLevel(for scout: ProductScout) -> RiskLevel {
        var risk = 0
        if scout.hasElectronics { risk += 2 }
        if scout.hasBattery { risk += 2 }
        if scout.touchesFood { risk += 3 }
        if scout.isForChildren { risk += 3 }
        if scout.isCosmetic { risk += 3 }
        if scout.isMedicalOrHealthRelated { risk += 4 }
        if scout.isTextile { risk += 2 }
        if scout.isFragile { risk += 1 }
        if scout.hasBrandOrDesignRisk { risk += 3 }
        if scout.hasManyCompetitors { risk += 1 }

        if scout.isMedicalOrHealthRelated || risk >= 9 { return .avoid }
        if risk >= 6 { return .high }
        if risk >= 3 { return .medium }
        return .low
    }

    static func beginnerFriendliness(for scout: ProductScout) -> String {
        switch riskLevel(for: scout) {
        case .low:
            return score(for: scout) >= 70 ? "Beginner-friendly estimate" : "Promising, needs review"
        case .medium:
            return "Review before pursuing"
        case .high:
            return "Higher complexity"
        case .avoid:
            return "Avoid for beginners"
        }
    }
}
