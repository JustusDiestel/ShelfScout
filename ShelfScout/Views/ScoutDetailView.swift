import SwiftData
import SwiftUI
import UIKit

struct ScoutDetailView: View {
    let scout: ProductScout
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var shareItems: [Any] = []
    @State private var showingShare = false
    @State private var showingEditor = false
    @State private var showingDeleteConfirmation = false
    @State private var alertMessage: String?

    var body: some View {
        List {
            Section {
                ScoutPhotoView(path: scout.productPhotoLocalPath)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Text(scout.displayTitle)
                    .font(.title2.bold())
                Text(scout.productDescription)
                    .foregroundStyle(.secondary)
            }

            Section("Score") {
                LabeledContent("Scout Score", value: "\(scout.scoutScore)/100")
                LabeledContent("Risk Level", value: scout.riskLevel)
                LabeledContent("Beginner Friendliness", value: scout.beginnerFriendliness)
                Text("This is a local scouting estimate and does not replace legal, safety, tax, customs, or compliance review.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Store") {
                LabeledContent("Store", value: scout.storeName.isEmpty ? "Not set" : scout.storeName)
                LabeledContent("Location", value: scout.locationLabel.isEmpty ? "Not set" : scout.locationLabel)
                LabeledContent("Date seen", value: AppFormatters.date.string(from: scout.dateSeen))
                LabeledContent("Observed price", value: AppFormatters.money(scout.observedStorePrice, currency: scout.currency))
            }

            Section("Estimate") {
                LabeledContent("Purchase", value: AppFormatters.money(scout.estimatedPurchasePrice, currency: scout.currency))
                LabeledContent("Sale", value: AppFormatters.money(scout.estimatedSalePrice, currency: scout.currency))
                LabeledContent("Gross profit", value: AppFormatters.money(scout.estimatedGrossProfit, currency: scout.currency))
                LabeledContent("Margin", value: AppFormatters.percent(scout.estimatedMarginPercent))
            }

            if scout.hasClassifierSuggestions {
                localSuggestionsSection
            }

            quickResearchSection

            Section("Exports") {
                Button("Share PDF Scout Card", systemImage: "doc.richtext") { exportPDF() }
                Button("Share Image Card", systemImage: "photo") { exportImage() }
                Button("Share CSV Row", systemImage: "tablecells") { exportCSV() }
                Button("Share .shelfscout File", systemImage: "doc.badge.gearshape") { exportShelfScout() }
            }

            Section("Notes") {
                Text(scout.notes.isEmpty ? "No notes." : scout.notes)
            }

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
        .sheet(isPresented: $showingShare) {
            ShareSheet(items: shareItems)
        }
        .alert("ShelfScout", isPresented: Binding(get: { alertMessage != nil }, set: { _ in alertMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
        .confirmationDialog("Delete this scout?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                ImageStorageService.delete(path: scout.productPhotoLocalPath)
                modelContext.delete(scout)
                dismiss()
            }
        }
    }

    private var quickResearchSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Research")
                    .font(.headline)
                Text("Open marketplace searches to manually check similar products. ShelfScout does not collect search results.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Research links open external websites. ShelfScout does not collect search results.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            LabeledContent("Research query", value: scout.resolvedResearchQuery.isEmpty ? "Not set" : scout.resolvedResearchQuery)

            if scout.resolvedResearchQuery.isEmpty {
                Text("Add a research query in Edit before opening external search links.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(QuickResearchPlatform.allCases) { platform in
                Button(platform.title, systemImage: "safari") {
                    openResearch(platform)
                }
                .disabled(scout.resolvedResearchQuery.isEmpty)
                .accessibilityLabel(platform.title)
            }

            LabeledContent("Platforms checked", value: checkedPlatformsText)
            LabeledContent("Similar products found", value: scout.similarProductsFound ? "Yes" : "No")
            LabeledContent("Competition level", value: scout.estimatedCompetitionLevel)
            if !scout.competitorNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(scout.competitorNotes)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var localSuggestionsSection: some View {
        Section("Local Suggestions") {
            if let category = scout.classifierSuggestedCategory {
                LabeledContent("Suggested category", value: category)
            }
            if !scout.classifierSuggestedTags.isEmpty {
                LabeledContent("Suggested tags", value: scout.classifierSuggestedTags.joined(separator: ", "))
            }
            if !scout.classifierSuggestedRiskIndicators.isEmpty {
                LabeledContent("Possible risk indicators", value: scout.classifierSuggestedRiskIndicators.joined(separator: ", "))
            }
            LabeledContent("Confidence", value: AppFormatters.percent(scout.classifierConfidence.map { Decimal($0 * 100) }))
            if let lastRun = scout.classifierLastRunAt {
                LabeledContent("Last analyzed", value: AppFormatters.date.string(from: lastRun))
            }
            Text("Generated locally from the product photo. Review manually.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func present(_ url: URL) {
        shareItems = [url]
        showingShare = true
    }

    private func exportPDF() {
        do { present(try PDFExportService.writePDF(for: scout)) } catch { alertMessage = error.localizedDescription }
    }

    private func exportImage() {
        do { present(try ImageCardExportService.writeImageCard(for: scout)) } catch { alertMessage = error.localizedDescription }
    }

    private func exportCSV() {
        do { present(try CSVExportService.writeCSV(for: [scout], filename: "\(scout.displayTitle).csv")) } catch { alertMessage = error.localizedDescription }
    }

    private func exportShelfScout() {
        do { present(try ShelfScoutFileService.writeDocument(for: scout)) } catch { alertMessage = error.localizedDescription }
    }

    private var checkedPlatformsText: String {
        let platforms = QuickResearchService.checkedPlatforms(for: scout)
        return platforms.isEmpty ? "None" : platforms.joined(separator: ", ")
    }

    private func openResearch(_ platform: QuickResearchPlatform) {
        guard let url = QuickResearchService.url(for: platform, query: scout.resolvedResearchQuery) else {
            alertMessage = "Add a research query before opening external search links."
            return
        }
        UIApplication.shared.open(url)
    }
}
