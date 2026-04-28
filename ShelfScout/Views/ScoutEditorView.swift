import PhotosUI
import SwiftData
import SwiftUI

struct ScoutEditorView: View {
    @Bindable var scout: ProductScout
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PhotoLibrarySavePreference.storageKey) private var photoSavePreferenceRaw = PhotoLibrarySavePreference.askEveryTime.rawValue
    @StateObject private var viewModel = ScoutEditorViewModel()
    @StateObject private var locationService = LocationService()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var pendingPhotosImage: UIImage?
    @State private var showingSaveToPhotosConfirmation = false
    @State private var alertMessage: String?
    private let photoLibrarySaveService = PhotoLibrarySaveService()

    var body: some View {
        Form {
            basicInfo
            seenInStore
            estimate
            assessment
            researchChecklist
            LocalSuggestionsView(scout: scout)
            riskCheck
            ocrSource
            scorePreview
        }
        .navigationTitle("Edit Scout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    save()
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker { image in
                Task { await viewModel.applyImage(image, to: scout) }
                handleCapturedPhotoSavePreference(image)
            }
            .ignoresSafeArea()
        }
        .confirmationDialog("Save a copy to Photos", isPresented: $showingSaveToPhotosConfirmation, titleVisibility: .visible) {
            Button("Save a copy to Photos") {
                if let image = pendingPhotosImage {
                    Task { await saveCopyToPhotos(image) }
                }
                pendingPhotosImage = nil
            }
            Button("Keep in ShelfScout Only", role: .cancel) {
                pendingPhotosImage = nil
                viewModel.message = "Photo was saved in ShelfScout only."
            }
        } message: {
            Text("Photos saved to Apple Photos may sync with iCloud depending on your personal iCloud settings.")
        }
        .alert("ShelfScout", isPresented: Binding(
            get: { alertMessage != nil || viewModel.message != nil },
            set: { _ in alertMessage = nil; viewModel.message = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? viewModel.message ?? "")
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task { await viewModel.loadPhotoPickerItem(newValue, into: scout) }
        }
    }

    private var basicInfo: some View {
        Section("Basic Info") {
            ScoutPhotoView(path: scout.productPhotoLocalPath)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            HStack {
                Button("Take Photo", systemImage: "camera") {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showingCamera = true
                    } else {
                        alertMessage = "Camera is not available here. You can choose an image or continue manually."
                    }
                }
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose Image", systemImage: "photo")
                }
            }

            TextField("Product name", text: $scout.title)
            TextField("Category", text: $scout.category)
            TextField("Short description", text: $scout.productDescription, axis: .vertical)
            TextField("Notes", text: $scout.notes, axis: .vertical)
            Picker("Status", selection: $scout.status) {
                ForEach(ProductScoutStatus.allCases) { status in
                    Text(status.rawValue).tag(status.rawValue)
                }
            }
        }
    }

    private var seenInStore: some View {
        Section("Seen in Store") {
            TextField("Store name", text: $scout.storeName)
            TextField("Location label", text: $scout.locationLabel)
            DatePicker("Date/time seen", selection: $scout.dateSeen)
            DecimalField(title: "Observed store price", value: $scout.observedStorePrice)
            TextField("Currency", text: $scout.currency)
                .textInputAutocapitalization(.characters)
            Button("Add current location", systemImage: "location") {
                Task { await addCurrentLocation() }
            }
            Button("Remove location", systemImage: "location.slash", role: .destructive) {
                scout.locationLabel = ""
                scout.latitude = nil
                scout.longitude = nil
            }
        }
    }

    private var estimate: some View {
        Section("Estimate") {
            DecimalField(title: "Estimated purchase price", value: $scout.estimatedPurchasePrice)
            DecimalField(title: "Estimated sale price", value: $scout.estimatedSalePrice)
            LabeledContent("Estimated gross profit", value: AppFormatters.money(scout.estimatedGrossProfit, currency: scout.currency))
            LabeledContent("Estimated margin", value: AppFormatters.percent(scout.estimatedMarginPercent))
        }
    }

    private var assessment: some View {
        Section("Quick Product Assessment") {
            Toggle("Clear use case?", isOn: $scout.hasClearUseCase)
            Toggle("Easy to explain?", isOn: $scout.isEasyToExplain)
            Toggle("Small and light?", isOn: $scout.isSmallAndLight)
            Toggle("Many competitors?", isOn: $scout.hasManyCompetitors)
            Toggle("Brand/design risk?", isOn: $scout.hasBrandOrDesignRisk)
        }
    }

    private var riskCheck: some View {
        Section("Beginner Risk Check") {
            Toggle("Electronics?", isOn: $scout.hasElectronics)
            Toggle("Battery?", isOn: $scout.hasBattery)
            Toggle("Food contact?", isOn: $scout.touchesFood)
            Toggle("Children's product?", isOn: $scout.isForChildren)
            Toggle("Cosmetic?", isOn: $scout.isCosmetic)
            Toggle("Medical/health?", isOn: $scout.isMedicalOrHealthRelated)
            Toggle("Textile?", isOn: $scout.isTextile)
            Toggle("Fragile?", isOn: $scout.isFragile)
        }
    }

    private var researchChecklist: some View {
        Section("Research Checklist") {
            TextField("Research query", text: $scout.researchQuery)
            Text("Used to create external marketplace search links.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("Use product name as query", systemImage: "text.magnifyingglass") {
                scout.researchQuery = ProductScout.defaultResearchQuery(title: scout.title, category: scout.category)
            }
            Toggle("Amazon checked", isOn: $scout.amazonChecked)
            Toggle("eBay checked", isOn: $scout.ebayChecked)
            Toggle("Google Shopping checked", isOn: $scout.googleShoppingChecked)
            Toggle("Google Images checked", isOn: $scout.googleImagesChecked)
            Toggle("Alibaba checked", isOn: $scout.alibabaChecked)
            Toggle("AliExpress checked", isOn: $scout.aliexpressChecked)
            Toggle("Etsy checked", isOn: $scout.etsyChecked)
            Toggle("TikTok checked", isOn: $scout.tiktokChecked)
            Toggle("Instagram checked", isOn: $scout.instagramChecked)
            Toggle("Similar products found", isOn: $scout.similarProductsFound)
            Picker("Competition level", selection: $scout.estimatedCompetitionLevel) {
                ForEach(CompetitionLevel.allCases) { level in
                    Text(level.rawValue).tag(level.rawValue)
                }
            }
            TextField("Competitor notes", text: $scout.competitorNotes, axis: .vertical)
                .lineLimit(3...8)
        }
    }

    private var ocrSource: some View {
        Section("OCR Source") {
            if viewModel.isRunningOCR {
                ProgressView("Reading text locally...")
            }
            TextField("Recognized text", text: $scout.recognizedText, axis: .vertical)
                .lineLimit(4...12)
            TextField("Detected barcode/EAN", text: Binding(
                get: { scout.detectedBarcodeOrEAN ?? "" },
                set: { scout.detectedBarcodeOrEAN = $0.isEmpty ? nil : $0 }
            ))
            Button("Re-run OCR", systemImage: "text.viewfinder") {
                Task { await viewModel.rerunOCR(for: scout) }
            }
            Button("Clear OCR text", systemImage: "xmark.circle", role: .destructive) {
                scout.recognizedText = ""
                scout.detectedBarcodeOrEAN = nil
            }
        }
    }

    private var scorePreview: some View {
        Section("Score Preview") {
            LabeledContent("Scout Score", value: "\(scout.scoutScore)/100")
            LabeledContent("Risk Level", value: scout.riskLevel)
            LabeledContent("Beginner Friendliness", value: scout.beginnerFriendliness)
            Text("This is a local scouting estimate and does not replace legal, safety, tax, customs, or compliance review.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func addCurrentLocation() async {
        do {
            let location = try await locationService.requestCurrentLocation()
            scout.locationPermissionUsed = true
            scout.locationLabel = location.label
            scout.latitude = location.latitude
            scout.longitude = location.longitude
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func save() {
        scout.updatedAt = Date()
        try? modelContext.save()
    }

    private var photoSavePreference: PhotoLibrarySavePreference {
        PhotoLibrarySavePreference(rawValue: photoSavePreferenceRaw) ?? .askEveryTime
    }

    private func handleCapturedPhotoSavePreference(_ image: UIImage) {
        switch photoSavePreference {
        case .askEveryTime:
            pendingPhotosImage = image
            showingSaveToPhotosConfirmation = true
        case .always:
            Task { await saveCopyToPhotos(image) }
        case .never:
            break
        }
    }

    private func saveCopyToPhotos(_ image: UIImage) async {
        do {
            try await photoLibrarySaveService.saveImageToPhotos(image)
            viewModel.message = "Photo saved to Photos."
        } catch {
            viewModel.message = error.localizedDescription
        }
    }
}
