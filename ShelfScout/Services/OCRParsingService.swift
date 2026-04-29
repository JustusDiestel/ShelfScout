import Foundation

struct OCRParseResult: Equatable {
    var possibleTitle: String?
    var price: Decimal?
    var priceCandidates: [String]
    var currency: String?
    var barcode: String?
    var weightOrSize: String?
    var dimensions: String?
    var fragments: [String]
}

enum OCRParsingService {
    static func parse(_ text: String) -> OCRParseResult {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !isGeneratedImageSeparator($0) }
        let priceCandidates = detectPriceCandidates(in: text)

        return OCRParseResult(
            possibleTitle: possibleTitle(from: lines),
            price: priceCandidates.count == 1 ? decimal(fromPriceText: priceCandidates[0]) : nil,
            priceCandidates: priceCandidates,
            currency: detectCurrency(in: text),
            barcode: detectEAN(in: text),
            weightOrSize: firstMatch(in: text, pattern: #"(?i)\b\d+(?:[.,]\d+)?\s?(?:kg|g|mg|l|ml|oz|lb)\b"#),
            dimensions: firstMatch(in: text, pattern: #"(?i)\b\d+(?:[.,]\d+)?\s?[x×]\s?\d+(?:[.,]\d+)?(?:\s?[x×]\s?\d+(?:[.,]\d+)?)?\s?(?:cm|mm|m|in)\b"#),
            fragments: Array(lines.prefix(8))
        )
    }

    static func detectPrice(in text: String) -> Decimal? {
        detectPriceCandidates(in: text).compactMap(decimal(fromPriceText:)).first
    }

    static func detectPriceCandidates(in text: String) -> [String] {
        let patterns = [
            #"(?i)(?:[$€£]\s*)\d{1,5}(?:[.,]\d{2})?"#,
            #"(?i)\b\d{1,5}[.,]\d{2}\s*(?:[$€£]|eur|usd|gbp)?\b"#,
            #"(?i)\b\d{1,5}\s*(?:[$€£]|eur|usd|gbp)\b"#
        ]

        var candidates: [String] = []
        for pattern in patterns {
            candidates.append(contentsOf: matches(in: text, pattern: pattern))
        }
        return candidates.removingDuplicates()
    }

    static func decimal(fromPriceText raw: String) -> Decimal? {
        let cleaned = raw
            .replacingOccurrences(of: ",", with: ".")
            .filter { $0.isNumber || $0 == "." }
        return Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX"))
    }

    static func detectCurrency(in text: String) -> String? {
        let lowercased = text.lowercased()
        if text.contains("€") || lowercased.contains("eur") { return "EUR" }
        if text.contains("$") || lowercased.contains("usd") { return "USD" }
        if text.contains("£") || lowercased.contains("gbp") { return "GBP" }
        return nil
    }

    static func detectEAN(in text: String) -> String? {
        let pattern = #"\b\d(?:[\s-]?\d){7,13}\b"#
        guard let raw = firstMatch(in: text, pattern: pattern) else { return nil }
        let digits = raw.filter(\.isNumber)
        return (8...14).contains(digits.count) ? digits : nil
    }

    static func firstMatch(in text: String, pattern: String) -> String? {
        matches(in: text, pattern: pattern).first
    }

    static func matches(in text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let swiftRange = Range(match.range, in: text) else { return nil }
            return String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static func possibleTitle(from lines: [String]) -> String? {
        lines.first { line in
            line.count >= 3 &&
            line.count <= 80 &&
            isMeaningfulTitle(line) &&
            detectPrice(in: line) == nil &&
            detectEAN(in: line) == nil
        }
    }

    static func isMeaningfulTitle(_ title: String) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()
        guard trimmed.count >= 3, trimmed.contains(where: \.isLetter) else { return false }
        if ["photo", "untitled", "image", "image1", "image2", "image3", "image4"].contains(lowercased) { return false }
        if trimmed.contains("/") || trimmed.contains("\\") { return false }
        if lowercased.range(of: #"^image\s*\d+$"#, options: .regularExpression) != nil { return false }
        if lowercased.range(of: #"^img[_-]?\d+"#, options: .regularExpression) != nil { return false }
        if lowercased.range(of: #"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"#, options: .regularExpression) != nil { return false }
        return !isGeneratedImageSeparator(trimmed)
    }

    private static func isGeneratedImageSeparator(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespacesAndNewlines)
            .range(of: #"(?i)^image\s+\d+$"#, options: .regularExpression) != nil
    }
}
