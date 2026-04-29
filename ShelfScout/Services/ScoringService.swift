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
}
