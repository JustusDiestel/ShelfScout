import SwiftData
import SwiftUI

@main
struct ShelfScoutApp: App {
    private let modelContainer = PersistenceConfiguration.makeModelContainer()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(modelContainer)
    }
}

