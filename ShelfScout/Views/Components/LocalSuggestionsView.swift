import SwiftUI

private struct RiskSuggestionChange: Identifiable {
    var id: String { fieldName }
    var fieldName: String
    var apply: () -> Void
}

struct LocalSuggestionsView: View {
    @Bindable var scout: ProductScout
    @State private var message: String?
    @State private var pendingRiskChanges: [RiskSuggestionChange] = []
    @State private var showingRiskConfirmation = false

    var body: some View {
        Section("Local Suggestions") {
            Text("Suggestions are generated on this iPhone from attached product images. They may be inaccurate and should be reviewed manually.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if !scout.hasClassifierSuggestions {
                Text("Use Analyze All Images Locally in Image Analysis to generate suggestions.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if scout.hasClassifierSuggestions {
                if let category = scout.classifierSuggestedCategory {
                    LabeledContent("Suggested category", value: category)
                }
                if !scout.classifierSuggestedTags.isEmpty {
                    LabeledContent("Suggested tags", value: scout.classifierSuggestedTags.joined(separator: ", "))
                }
                if !scout.classifierSuggestedRiskIndicators.isEmpty {
                    LabeledContent("Possible risk indicators", value: scout.classifierSuggestedRiskIndicators.joined(separator: ", "))
                }
                LabeledContent("Confidence", value: confidenceText)

                let labels = Array(scout.classifierTopLabels.prefix(3))
                if !labels.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Top labels")
                            .font(.subheadline.weight(.semibold))
                        ForEach(labels) { label in
                            Text("\(label.label) · \(AppFormatters.percent(Decimal(label.confidence * 100)))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Button("Use Suggested Category", systemImage: "tag") {
                    if let category = scout.classifierSuggestedCategory {
                        scout.category = category
                    }
                }
                .disabled(scout.classifierSuggestedCategory == nil)

                Button("Add Suggested Tags", systemImage: "text.badge.plus") {
                    addSuggestedTags()
                }
                .disabled(scout.classifierSuggestedTags.isEmpty)

                Button("Apply Risk Suggestions", systemImage: "checklist") {
                    prepareRiskConfirmation()
                }
                .disabled(scout.classifierSuggestedRiskIndicators.isEmpty)

                Button("Clear Suggestions", systemImage: "xmark.circle", role: .destructive) {
                    scout.clearClassificationSuggestions()
                    message = nil
                }
            }
        }
        .sheet(isPresented: $showingRiskConfirmation) {
            NavigationStack {
                List {
                    Section {
                        Text("Review manually before applying. These suggestions may be inaccurate.")
                            .foregroundStyle(.secondary)
                    }
                    Section("Checklist fields to change") {
                        ForEach(pendingRiskChanges) { change in
                            Text(change.fieldName)
                        }
                    }
                }
                .navigationTitle("Apply Risk Suggestions")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingRiskConfirmation = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Apply") {
                            pendingRiskChanges.forEach { $0.apply() }
                            pendingRiskChanges = []
                            showingRiskConfirmation = false
                        }
                    }
                }
            }
        }
    }

    private var confidenceText: String {
        guard let confidence = scout.classifierConfidence else { return "Not set" }
        return AppFormatters.percent(Decimal(confidence * 100))
    }

    private func addSuggestedTags() {
        let tags = scout.classifierSuggestedTags.filter { tag in
            !scout.notes.localizedCaseInsensitiveContains(tag)
        }
        guard !tags.isEmpty else { return }
        let addition = "Suggested tags: \(tags.joined(separator: ", "))"
        scout.notes = [scout.notes, addition]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private func prepareRiskConfirmation() {
        pendingRiskChanges = riskChanges()
        if pendingRiskChanges.isEmpty {
            message = "No new checklist fields would be changed."
        } else {
            showingRiskConfirmation = true
        }
    }

    private func riskChanges() -> [RiskSuggestionChange] {
        var changes: [RiskSuggestionChange] = []
        let indicators = Set(scout.classifierSuggestedRiskIndicators)
        if indicators.contains("possibleElectronics"), !scout.hasElectronics {
            changes.append(RiskSuggestionChange(fieldName: "Electronics") { scout.hasElectronics = true })
        }
        if indicators.contains("possibleBattery"), !scout.hasBattery {
            changes.append(RiskSuggestionChange(fieldName: "Battery") { scout.hasBattery = true })
        }
        if indicators.contains("possibleFoodContact"), !scout.touchesFood {
            changes.append(RiskSuggestionChange(fieldName: "Food contact") { scout.touchesFood = true })
        }
        if indicators.contains("possibleChildrenProduct"), !scout.isForChildren {
            changes.append(RiskSuggestionChange(fieldName: "Children's product") { scout.isForChildren = true })
        }
        if indicators.contains("possibleCosmetic"), !scout.isCosmetic {
            changes.append(RiskSuggestionChange(fieldName: "Cosmetic") { scout.isCosmetic = true })
        }
        if indicators.contains("possibleTextile"), !scout.isTextile {
            changes.append(RiskSuggestionChange(fieldName: "Textile") { scout.isTextile = true })
        }
        if indicators.contains("possibleFragile"), !scout.isFragile {
            changes.append(RiskSuggestionChange(fieldName: "Fragile") { scout.isFragile = true })
        }
        if indicators.contains("possibleBrandDesignRisk"), !scout.hasBrandOrDesignRisk {
            changes.append(RiskSuggestionChange(fieldName: "Brand/design risk") { scout.hasBrandOrDesignRisk = true })
        }
        return changes
    }
}
