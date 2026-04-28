import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ScoutListView()
                .tabItem { Label("Scouts", systemImage: "rectangle.stack") }

            NewScoutView()
                .tabItem { Label("New Scout", systemImage: "plus.circle.fill") }

            ExportView()
                .tabItem { Label("Files", systemImage: "square.and.arrow.up") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
