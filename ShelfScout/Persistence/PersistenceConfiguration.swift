import SwiftData

enum PersistenceConfiguration {
    static let schema = Schema([ProductScout.self])

    static func makeModelContainer() -> ModelContainer {
        do {
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            // Wenn die Migration fehlschlägt, starte mit leerer Datenbank
            print("SwiftData migration error, starting with fresh database: \(error)")
            do {
                // Versuche in-memory Container als Fallback
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )

                return try ModelContainer(
                    for: schema,
                    configurations: [modelConfiguration]
                )
            } catch {
                fatalError("ShelfScout could not open its local SwiftData store: \(error)")
            }
        }
    }
}
