import Foundation

struct OCRParseResult: Equatable {
    var possibleTitle: String?
    var price: Decimal?
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
            .filter { !$0.isEmpty }

        return OCRParseResult(
            possibleTitle: possibleTitle(from: lines),
            price: detectPrice(in: text),
            barcode: detectEAN(in: text),
            weightOrSize: firstMatch(in: text, pattern: #"(?i)\b\d+(?:[.,]\d+)?\s?(?:kg|g|mg|l|ml|oz|lb)\b"#),
            dimensions: firstMatch(in: text, pattern: #"(?i)\b\d+(?:[.,]\d+)?\s?[x×]\s?\d+(?:[.,]\d+)?(?:\s?[x×]\s?\d+(?:[.,]\d+)?)?\s?(?:cm|mm|m|in)\b"#),
            fragments: Array(lines.prefix(8))
        )
    }

    static func detectPrice(in text: String) -> Decimal? {
        let patterns = [
            #"(?i)(?:[$€£]\s*)\d{1,5}(?:[.,]\d{2})?"#,
            #"(?i)\b\d{1,5}[.,]\d{2}\s*(?:[$€£]|eur|usd|gbp)?\b"#
        ]

        for pattern in patterns {
            guard let raw = firstMatch(in: text, pattern: pattern) else { continue }
            let cleaned = raw
                .replacingOccurrences(of: ",", with: ".")
                .filter { $0.isNumber || $0 == "." }
            if let decimal = Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX")) {
                return decimal
            }
        }
        return nil
    }

    static func detectEAN(in text: String) -> String? {
        let pattern = #"\b\d(?:[\s-]?\d){7,13}\b"#
        guard let raw = firstMatch(in: text, pattern: pattern) else { return nil }
        let digits = raw.filter(\.isNumber)
        return (8...14).contains(digits.count) ? digits : nil
    }

    static func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let swiftRange = Range(match.range, in: text) else { return nil }
        return String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func possibleTitle(from lines: [String]) -> String? {
        lines.first { line in
            line.count >= 3 &&
            line.count <= 80 &&
            detectPrice(in: line) == nil &&
            detectEAN(in: line) == nil
        }
    }
}
