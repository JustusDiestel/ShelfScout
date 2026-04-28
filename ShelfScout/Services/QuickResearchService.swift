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
        guard !trimmed.isEmpty, let encodedQuery = encode(trimmed) else { return nil }

        let urlString: String
        switch platform {
        case .amazon:
            urlString = "https://www.amazon.de/s?k=\(encodedQuery)"
        case .ebay:
            urlString = "https://www.ebay.de/sch/i.html?_nkw=\(encodedQuery)"
        case .googleShopping:
            urlString = "https://www.google.com/search?tbm=shop&q=\(encodedQuery)"
        case .googleImages:
            urlString = "https://www.google.com/search?tbm=isch&q=\(encodedQuery)"
        case .alibaba:
            urlString = "https://www.alibaba.com/trade/search?SearchText=\(encodedQuery)"
        case .aliexpress:
            urlString = "https://www.aliexpress.com/wholesale?SearchText=\(encodedQuery)"
        case .etsy:
            urlString = "https://www.etsy.com/search?q=\(encodedQuery)"
        case .tiktok:
            urlString = "https://www.tiktok.com/search?q=\(encodedQuery)"
        case .instagram:
            urlString = "https://www.google.com/search?q=site%3Ainstagram.com+\(encodedQuery)"
        }
        return URL(string: urlString)
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

    private static func encode(_ query: String) -> String? {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&+=?/#%")
        return query.addingPercentEncoding(withAllowedCharacters: allowed)
    }
}
