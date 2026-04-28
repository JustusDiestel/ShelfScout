import Foundation

struct ClassificationLabel: Codable, Equatable, Identifiable {
    var id: String { label }
    var label: String
    var confidence: Double
}
