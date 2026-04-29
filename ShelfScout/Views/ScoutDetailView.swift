import SwiftData
import SwiftUI

struct ScoutDetailView: View {
    let scout: ProductScout
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditor = false
    @State private var showingDeleteConfirmation = false
    @State private var alertMessage: String?

    var body: some View {
        List {
            Section {
                if scout.imageLocalPaths.isEmpty {
                    ScoutPhotoView(path: nil)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    detailImageGrid
                }
                Text(scout.displayTitle)
                    .font(.title2.bold())
                if !scout.productDescription.isEmpty {
                    Text(scout.productDescription)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Product") {
                LabeledContent("Category", value: scout.category.isEmpty ? "Not set" : scout.category)
                LabeledContent("Status", value: scout.status)
            }

            Section("Store & Location") {
                LabeledContent("Store", value: scout.storeName.isEmpty ? "Not set" : scout.storeName)
                LabeledContent("Location", value: scout.locationLabel.isEmpty ? "Not set" : scout.locationLabel)
                LabeledContent("Date seen", value: AppFormatters.date.string(from: scout.dateSeen))
            }

            Section("Price Estimate") {
                LabeledContent("Observed price", value: AppFormatters.money(scout.observedStorePrice, currency: scout.currency))
                LabeledContent("Purchase", value: AppFormatters.money(scout.estimatedPurchasePrice, currency: scout.currency))
                LabeledContent("Sale", value: AppFormatters.money(scout.estimatedSalePrice, currency: scout.currency))
                LabeledContent("Gross profit", value: AppFormatters.money(scout.estimatedGrossProfit, currency: scout.currency))
                LabeledContent("Margin", value: AppFormatters.percent(scout.estimatedMarginPercent))
            }

            if hasDetectedValues {
                Section("Detected Values") {
                    if !scout.detectedPriceCandidates.isEmpty {
                        LabeledContent("Price candidates", value: scout.detectedPriceCandidates.joined(separator: ", "))
                    }
                    if let barcode = scout.detectedBarcode {
                        LabeledContent("Barcode", value: barcode)
                    }
                    if let weight = scout.detectedWeight {
                        LabeledContent("Weight", value: weight)
                    }
                    if let dimensions = scout.detectedDimensions {
                        LabeledContent("Dimensions", value: dimensions)
                    }
                }
            }

            Section("Exports") {
                Button("Share PDF Scout Card", systemImage: "doc.richtext") { exportPDF() }
                Button("Share .shelfscout File", systemImage: "doc.badge.gearshape") { exportShelfScout() }
            }

            Section("Notes") {
                Text(scout.notes.isEmpty ? "No notes." : scout.notes)
            }

            #if DEBUG
            debugSection
            #endif

            Section {
                Button("Delete Scout", systemImage: "trash", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            }
        }
        .navigationTitle("Scout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") { showingEditor = true }
        }
        .sheet(isPresented: $showingEditor) {
            NavigationStack { ScoutEditorView(scout: scout) }
        }
        .alert("ShelfScout", isPresented: Binding(get: { alertMessage != nil }, set: { _ in alertMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
        .confirmationDialog("Delete this scout?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                ImageStorageService.delete(paths: scout.imageLocalPaths)
                modelContext.delete(scout)
                dismiss()
            }
        }
    }

    private var hasDetectedValues: Bool {
        !scout.detectedPriceCandidates.isEmpty ||
            scout.detectedBarcode != nil ||
            scout.detectedWeight != nil ||
            scout.detectedDimensions != nil
    }

    private var detailImageGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: scout.imageLocalPaths.count == 1 ? 1 : 2), spacing: 8) {
            ForEach(Array(scout.imageLocalPaths.enumerated()), id: \.offset) { index, path in
                ScoutPhotoView(path: path)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(4 / 3, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .accessibilityLabel(index == 0 ? "Primary product image" : "Product image \(index + 1)")
            }
        }
    }

    private func present(_ url: URL) {
        do {
            try SharePresenter.present(items: [ExportFileValidator.validate(url)])
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func exportPDF() {
        do { present(try PDFExportService.writePDF(for: scout)) } catch { alertMessage = error.localizedDescription }
    }

    private func exportShelfScout() {
        do { present(try ShelfScoutFileService.writeDocument(for: scout)) } catch { alertMessage = error.localizedDescription }
    }

    #if DEBUG
    private var debugSection: some View {
        Section("Debug") {
            LabeledContent("Scout ID", value: scout.id.uuidString)
            LabeledContent("Image count", value: "\(scout.imageLocalPaths.count)")
            Text("Images: \(scout.imageLocalPaths.map { URL(filePath: $0).lastPathComponent }.joined(separator: ", "))")
                .font(.caption)
            LabeledContent("Last OCR run", value: scout.ocrLastRunAt.map { AppFormatters.date.string(from: $0) } ?? "Not set")
        }
    }
    #endif
}
