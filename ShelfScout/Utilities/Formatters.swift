import Foundation

enum AppFormatters {
    static let date: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static func decimalString(_ value: Decimal?, maximumFractionDigits: Int = 2) -> String {
        guard let value else { return "" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.minimumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    static func money(_ value: Decimal?, currency: String) -> String {
        guard let value else { return "Not set" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value) \(currency)"
    }

    static func percent(_ value: Decimal?) -> String {
        guard let value else { return "Not set" }
        return "\(decimalString(value, maximumFractionDigits: 1))%"
    }
}
