import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProductScout.updatedAt, order: .reverse) private var scouts: [ProductScout]
    @State private var shareItems: [Any] = []
    @State private var showingShare = false
    @State private var showingImporter = false
    @State private var importTypes: [UTType] = [.shelfScoutProduct]
    @State private var message: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Export") {
                    Button("Export all as CSV", systemImage: "tablecells") {
                        do { present(try CSVExportService.writeCSV(for: scouts)) } catch { message = error.localizedDescription }
                    }
                    Button("Export all as .shelfscout archive", systemImage: "archivebox") {
                        do { present(try ShelfScoutFileService.writeArchive(for: scouts)) } catch { message = error.localizedDescription }
                    }
                }

                Section("Import") {
                    Button("Import .shelfscout", systemImage: "doc.badge.plus") {
                        importTypes = [.shelfScoutProduct, .json]
                        showingImporter = true
                    }
                    Button("Import CSV", systemImage: "tablecells.badge.ellipsis") {
                        importTypes = [.commaSeparatedText, .plainText]
                        showingImporter = true
                    }
                    Button("Import image", systemImage: "photo.badge.plus") {
                        importTypes = [.image]
                        showingImporter = true
                    }
                }

                Section("Recent scouts") {
                    if scouts.isEmpty {
                        Text("No local scouts available to export yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(scouts.prefix(8)) { scout in
                            NavigationLink(scout.displayTitle) {
                                ScoutDetailView(scout: scout)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Export / Files")
            .sheet(isPresented: $showingShare) {
                ShareSheet(items: shareItems)
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: importTypes) { result in
                handleImport(result)
            }
            .alert("ShelfScout", isPresented: Binding(get: { message != nil }, set: { _ in message = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
        }
    }

    private func present(_ url: URL) {
        shareItems = [url]
        showingShare = true
    }

    private func handleImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let ext = url.pathExtension.lowercased()
            let imported: [ProductScout]
            let shouldRunOCR: Bool
            if ext == "shelfscout" || ext == "json" {
                imported = try ImportService.importShelfScout(from: url)
                shouldRunOCR = false
            } else if ext == "csv" || ext == "txt" {
                imported = try ImportService.importCSV(from: url)
                shouldRunOCR = false
            } else {
                imported = try importImage(from: url)
                shouldRunOCR = true
            }
            imported.forEach { modelContext.insert($0) }
            if shouldRunOCR {
                Task {
                    for scout in imported {
                        await runOCR(for: scout)
                    }
                }
            }
            message = "Imported \(imported.count) scout\(imported.count == 1 ? "" : "s")."
        } catch {
            message = "The file could not be imported. \(error.localizedDescription)"
        }
    }

    private func importImage(from url: URL) throws -> [ProductScout] {
        let access = url.startAccessingSecurityScopedResource()
        defer {
            if access { url.stopAccessingSecurityScopedResource() }
        }
        let data = try Data(contentsOf: url)
        guard let image = UIImage(data: data) else {
            throw AppError.message("The selected image could not be opened.")
        }
        let scout = ProductScout()
        scout.productPhotoLocalPath = try ImageStorageService.save(image)
        return [scout]
    }

    private func runOCR(for scout: ProductScout) async {
        guard let image = ImageStorageService.load(path: scout.productPhotoLocalPath) else { return }
        do {
            let text = try await OCRService().recognizeText(from: image)
            scout.recognizedText = text
            let parsed = OCRParsingService.parse(text)
            scout.title = parsed.possibleTitle ?? scout.title
            if scout.researchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                scout.researchQuery = ProductScout.defaultResearchQuery(title: scout.title, category: scout.category)
            }
            scout.observedStorePrice = parsed.price ?? scout.observedStorePrice
            scout.detectedBarcodeOrEAN = parsed.barcode ?? scout.detectedBarcodeOrEAN
            scout.updatedAt = Date()
        } catch {
            message = "Imported the image, but OCR could not read it. You can edit the scout manually."
        }
    }
}
