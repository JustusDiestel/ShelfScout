import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ProductScout.updatedAt, order: .reverse) private var scouts: [ProductScout]
    @State private var showingImporter = false
    @State private var importTypes: [UTType] = [.shelfScoutProduct]
    @State private var message: String?
    @State private var selectedScoutID: UUID?

    var body: some View {
        NavigationStack {
            List {
                Section("PDF Export") {
                    Button("Export All as PDF", systemImage: "doc.on.doc") {
                        do { present(try PDFExportService.writePDF(for: scouts, filename: "ShelfScout Scouts.pdf")) } catch { message = error.localizedDescription }
                    }
                    .disabled(scouts.isEmpty)

                    if scouts.isEmpty {
                        Text("Create a scout before exporting PDFs.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Selected scout", selection: $selectedScoutID) {
                            ForEach(scouts) { scout in
                                Text(scout.displayTitle).tag(Optional(scout.id))
                            }
                        }

                        Button("Export Selected as PDF", systemImage: "doc.richtext") {
                            guard let scout = selectedScout else {
                                message = "Select a scout before exporting a PDF."
                                return
                            }
                            do { present(try PDFExportService.writePDF(for: scout)) } catch { message = error.localizedDescription }
                        }
                    }
                }

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
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: importTypes) { result in
                handleImport(result)
            }
            .onAppear {
                syncSelectedScout()
            }
            .onChange(of: scouts.map(\.id)) { _, _ in
                syncSelectedScout()
            }
            .alert("ShelfScout", isPresented: Binding(get: { message != nil }, set: { _ in message = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
        }
    }

    private func present(_ url: URL) {
        do {
            try SharePresenter.present(items: [ExportFileValidator.validate(url)])
        } catch {
            message = error.localizedDescription
        }
    }

    private var selectedScout: ProductScout? {
        guard let selectedScoutID else { return scouts.first }
        return scouts.first(where: { $0.id == selectedScoutID }) ?? scouts.first
    }

    private func syncSelectedScout() {
        guard !scouts.isEmpty else {
            selectedScoutID = nil
            return
        }

        if let selectedScoutID, scouts.contains(where: { $0.id == selectedScoutID }) {
            return
        }
        selectedScoutID = scouts.first?.id
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
        let path = try ImageStorageService.save(image)
        scout.addImageLocalPath(path)
        return [scout]
    }

    private func runOCR(for scout: ProductScout) async {
        await ScoutEditorViewModel().analyzeAllImages(for: scout, runClassifier: false)
    }
}
