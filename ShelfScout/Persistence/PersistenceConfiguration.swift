import SwiftData

enum PersistenceConfiguration {
    static let schema = Schema([ProductScout.self])

    static func makeModelContainer() -> ModelContainer {
        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("ShelfScout could not open its local SwiftData store: \(error)")
        }
    }
}
