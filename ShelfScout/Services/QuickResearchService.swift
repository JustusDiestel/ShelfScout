import Foundation

enum QuickResearchPlatform: String, CaseIterable, Identifiable {
    case amazon
    case ebay
    case googleShopping
    case googleImages
    case alibaba
    case aliexpress
    case etsy
    case tiktok
    case instagram

    var id: String { rawValue }

    var title: String {
        switch self {
        case .amazon: "Search Amazon"
        case .ebay: "Search eBay"
        case .googleShopping: "Search Google Shopping"
        case .googleImages: "Search Google Images"
        case .alibaba: "Search Alibaba"
        case .aliexpress: "Search AliExpress"
        case .etsy: "Search Etsy"
        case .tiktok: "Search TikTok"
        case .instagram: "Search Instagram"
        }
    }

    var checkedLabel: String {
        switch self {
        case .amazon: "Amazon"
        case .ebay: "eBay"
        case .googleShopping: "Google Shopping"
        case .googleImages: "Google Images"
        case .alibaba: "Alibaba"
        case .aliexpress: "AliExpress"
        case .etsy: "Etsy"
        case .tiktok: "TikTok"
        case .instagram: "Instagram"
        }
    }
}

enum QuickResearchService {
    static func url(for platform: QuickResearchPlatform, query: String) -> URL? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isMeaningfulResearchQuery(trimmed) else { return nil }

        var components = URLComponents()
        components.scheme = "https"

        switch platform {
        case .amazon:
            components.host = "www.amazon.de"
            components.path = "/s"
            components.queryItems = [URLQueryItem(name: "k", value: trimmed)]
        case .ebay:
            components.host = "www.ebay.de"
            components.path = "/sch/i.html"
            components.queryItems = [URLQueryItem(name: "_nkw", value: trimmed)]
        case .googleShopping:
            components.host = "www.google.com"
            components.path = "/search"
            components.queryItems = [URLQueryItem(name: "tbm", value: "shop"), URLQueryItem(name: "q", value: trimmed)]
        case .googleImages:
            components.host = "www.google.com"
            components.path = "/search"
            components.queryItems = [URLQueryItem(name: "tbm", value: "isch"), URLQueryItem(name: "q", value: trimmed)]
        case .alibaba:
            components.host = "www.alibaba.com"
            components.path = "/trade/search"
            components.queryItems = [URLQueryItem(name: "SearchText", value: trimmed)]
        case .aliexpress:
            components.host = "www.aliexpress.com"
            components.path = "/wholesale"
            components.queryItems = [URLQueryItem(name: "SearchText", value: trimmed)]
        case .etsy:
            components.host = "www.etsy.com"
            components.path = "/search"
            components.queryItems = [URLQueryItem(name: "q", value: trimmed)]
        case .tiktok:
            components.host = "www.tiktok.com"
            components.path = "/search"
            components.queryItems = [URLQueryItem(name: "q", value: trimmed)]
        case .instagram:
            components.host = "www.google.com"
            components.path = "/search"
            components.queryItems = [URLQueryItem(name: "q", value: "site:instagram.com \(trimmed)")]
        }
        return components.url
    }

    static func resolvedQuery(for scout: ProductScout) -> String {
        let manual = scout.researchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if isMeaningfulResearchQuery(manual) { return manual }

        let title = scout.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if isMeaningfulResearchQuery(title) { return title }

        let category = scout.category.trimmingCharacters(in: .whitespacesAndNewlines)
        let keywords = usefulOCRKeywords(from: scout.combinedRecognizedText.isEmpty ? scout.recognizedText : scout.combinedRecognizedText)
        let categoryAndKeywords = ([category] + keywords.prefix(3)).filter(isMeaningfulResearchQuery).joined(separator: " ")
        if isMeaningfulResearchQuery(categoryAndKeywords) { return categoryAndKeywords }

        let ocrOnly = keywords.prefix(4).joined(separator: " ")
        return isMeaningfulResearchQuery(ocrOnly) ? ocrOnly : ""
    }

    static func isMeaningfulResearchQuery(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return false }
        let lowercased = trimmed.lowercased()
        let invalidExact = ["photo", "untitled", "image", "image1", "image2", "image3", "image4"]
        if invalidExact.contains(lowercased) { return false }
        if lowercased.range(of: #"^image\s*\d+$"#, options: .regularExpression) != nil { return false }
        if lowercased.range(of: #"^img[_-]?\d+"#, options: .regularExpression) != nil { return false }
        if lowercased.range(of: #"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"#, options: .regularExpression) != nil { return false }
        if trimmed.contains("/") || trimmed.contains("\\") { return false }
        if ["jpg", "jpeg", "png", "heic"].contains(URL(filePath: trimmed).pathExtension.lowercased()) { return false }
        return trimmed.contains { $0.isLetter }
    }

    static func checkedPlatforms(for scout: ProductScout) -> [String] {
        [
            scout.amazonChecked ? QuickResearchPlatform.amazon.checkedLabel : nil,
            scout.ebayChecked ? QuickResearchPlatform.ebay.checkedLabel : nil,
            scout.googleShoppingChecked ? QuickResearchPlatform.googleShopping.checkedLabel : nil,
            scout.googleImagesChecked ? QuickResearchPlatform.googleImages.checkedLabel : nil,
            scout.alibabaChecked ? QuickResearchPlatform.alibaba.checkedLabel : nil,
            scout.aliexpressChecked ? QuickResearchPlatform.aliexpress.checkedLabel : nil,
            scout.etsyChecked ? QuickResearchPlatform.etsy.checkedLabel : nil,
            scout.tiktokChecked ? QuickResearchPlatform.tiktok.checkedLabel : nil,
            scout.instagramChecked ? QuickResearchPlatform.instagram.checkedLabel : nil
        ].compactMap { $0 }
    }

    private static func usefulOCRKeywords(from text: String) -> [String] {
        text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { word in
                word.count >= 3 &&
                word.count <= 28 &&
                word.rangeOfCharacter(from: .letters) != nil &&
                isMeaningfulResearchQuery(word)
            }
            .removingDuplicates()
    }
}
