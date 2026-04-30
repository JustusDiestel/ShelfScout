import SwiftData
import SwiftUI

enum ScoutSort: String, CaseIterable, Identifiable {
    case date = "Date"
    case category = "Category"

    var id: String { rawValue }
}

struct ScoutListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProductScout.updatedAt, order: .reverse) private var scouts: [ProductScout]

    @State private var searchText = ""
    @State private var statusFilter = "All"
    @State private var sort = ScoutSort.date

    var body: some View {
        NavigationStack {
            List {
                if filteredScouts.isEmpty {
                    ContentUnavailableView(
                        "No scouts yet",
                        systemImage: "magnifyingglass",
                        description: Text("Create a scout manually, take a product photo, or import an image.")
                    )
                } else {
                    ForEach(filteredScouts) { scout in
                        NavigationLink {
                            ScoutDetailView(scout: scout)
                        } label: {
                            ScoutCardView(scout: scout)
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("ShelfScout")
            .searchable(text: $searchText, prompt: "Search scouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Status", selection: $statusFilter) {
                            Text("All").tag("All")

                            ForEach(ProductScoutStatus.allCases) { status in
                                Text(status.rawValue).tag(status.rawValue)
                            }
                        }

                        Picker("Sort", selection: $sort) {
                            ForEach(ScoutSort.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }

    private var filteredScouts: [ProductScout] {
        var results = scouts

        if statusFilter != "All" {
            results = results.filter { $0.status == statusFilter }
        }

        if !searchText.isEmpty {
            results = results.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText) ||
                $0.storeName.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sort {
        case .date:
            return results.sorted { $0.updatedAt > $1.updatedAt }

        case .category:
            return results.sorted { $0.category < $1.category }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let scout = filteredScouts[index]
            ImageStorageService.delete(paths: scout.imageLocalPaths)
            modelContext.delete(scout)
        }
    }
}

struct ScoutCardView: View {
    let scout: ProductScout

    var body: some View {
        HStack(spacing: 12) {
            ScoutPhotoView(path: scout.primaryImagePath)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("Product photo")

            VStack(alignment: .leading, spacing: 5) {
                Text(scout.displayTitle)
                    .font(.headline)

                Text([scout.storeName, scout.category]
                    .filter { !$0.isEmpty }
                    .joined(separator: " · "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack {
                    Text(AppFormatters.money(
                        scout.observedStorePrice,
                        currency: scout.currency
                    ))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}