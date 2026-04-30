import SwiftUI

struct LocalSuggestionsView: View {
    @Bindable var scout: ProductScout

    var body: some View {
        Section("Local Suggestions") {
            Text("Local image analysis features have been removed.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
