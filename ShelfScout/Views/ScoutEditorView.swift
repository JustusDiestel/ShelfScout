import PhotosUI
import SwiftData
import SwiftUI

struct ScoutEditorView: View {
    @Bindable var scout: ProductScout
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PhotoLibrarySavePreference.storageKey) private var photoSavePreferenceRaw = PhotoLibrarySavePreference.on.rawValue
    @StateObject private var viewModel = ScoutEditorViewModel()
    @StateObject private var locationService = LocationService()
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingCamera = false
    @State private var alertMessage: String?
    private let photoLibrarySaveService = PhotoLibrarySaveService()

    var body: some View {
        Form {
            imagesSection
            productSection
            storeLocationSection
            priceSection
        }
        .navigationTitle("Edit Scout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    save()
                    dismiss()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                save()
                dismiss()
            } label: {
                Label("Save Scout", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .background(.bar)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in
                Task { await viewModel.applyImage(image, to: scout) }
                saveCapturedPhotoIfEnabled(image)
            }
            .ignoresSafeArea()
        }
        .alert("ShelfScout", isPresented: Binding(
            get: { alertMessage != nil || viewModel.message != nil },
            set: { _ in alertMessage = nil; viewModel.message = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? viewModel.message ?? "")
        }
        .onChange(of: selectedPhotos) { _, newValue in
            guard !newValue.isEmpty else { return }
            Task {
                await viewModel.loadPhotoPickerItems(newValue, into: scout)
                selectedPhotos = []
            }
        }
    }

    private var imagesSection: some View {
        Section("Images") {
            Text(scout.imageCountText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            if scout.imageLocalPaths.isEmpty {
                ContentUnavailableView(
                    "No images",
                    systemImage: "photo.badge.plus",
                    description: Text("Add up to 4 product images.")
                )
            } else {
                imageGrid
            }

            HStack {
                Button("Add Photo", systemImage: "camera") {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showingCamera = true
                    } else {
                        alertMessage = "Camera is not available here. Choose images or continue manually."
                    }
                }
                .disabled(scout.imageLocalPaths.count >= ProductScout.maxImageCount)

                if scout.imageLocalPaths.count < ProductScout.maxImageCount {
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: remainingImageSlots, matching: .images) {
                        Label("Choose Images", systemImage: "photo")
                    }
                }
            }
        }
    }

    private var imageGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 12) {
            ForEach(Array(scout.imageLocalPaths.enumerated()), id: \.offset) { index, path in
                VStack(alignment: .leading, spacing: 8) {
                    ZStack(alignment: .topLeading) {
                        ScoutPhotoView(path: path)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(4 / 3, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        if index == 0 {
                            Text("Primary")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.regularMaterial, in: Capsule())
                                .padding(6)
                        }
                    }
                    HStack {
                        Button("Primary") {
                            viewModel.setPrimaryImage(at: index, in: scout)
                        }
                        .font(.caption)
                        .disabled(index == 0)
                        Spacer()
                        Button(role: .destructive) {
                            viewModel.removeImage(at: index, from: scout)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .accessibilityLabel("Remove image \(index + 1)")
                    }
                }
            }
        }
    }

    private var productSection: some View {
        Section("Product") {
            TextField("Product name", text: $scout.title)
            Picker("Category", selection: $scout.category) {
                Text("Not set").tag("")
                ForEach(ProductCategory.allCases) { category in
                    Text(category.rawValue).tag(category.rawValue)
                }
            }
            TextField("Short description", text: $scout.productDescription, axis: .vertical)
                .lineLimit(2...5)
            TextField("Notes", text: $scout.notes, axis: .vertical)
                .lineLimit(3...8)
            Picker("Status", selection: $scout.status) {
                ForEach(ProductScoutStatus.allCases) { status in
                    Text(status.rawValue).tag(status.rawValue)
                }
            }
        }
    }

    private var storeLocationSection: some View {
        Section("Store & Location") {
            TextField("Store name", text: $scout.storeName)
            DatePicker("Date seen", selection: $scout.dateSeen)
            TextField("Location label", text: $scout.locationLabel)
            Button("Add Current Location", systemImage: "location") {
                Task { await addCurrentLocation() }
            }
            if scout.latitude != nil || scout.longitude != nil || !scout.locationLabel.isEmpty {
                Button("Remove Location", systemImage: "location.slash", role: .destructive) {
                    scout.locationLabel = ""
                    scout.latitude = nil
                    scout.longitude = nil
                }
            }
        }
    }

    private var priceSection: some View {
        Section("Price Estimate") {
            DecimalField(title: "Observed store price", value: $scout.observedStorePrice)
            DecimalField(title: "Estimated purchase price", value: $scout.estimatedPurchasePrice)
            DecimalField(title: "Estimated sale price", value: $scout.estimatedSalePrice)
            TextField("Currency", text: $scout.currency)
                .textInputAutocapitalization(.characters)
            LabeledContent("Estimated gross profit", value: AppFormatters.money(scout.estimatedGrossProfit, currency: scout.currency))
            LabeledContent("Estimated margin", value: AppFormatters.percent(scout.estimatedMarginPercent))
        }
    }


    #if DEBUG
    private var debugSection: some View {
        Section("Debug") {
            LabeledContent("Scout ID", value: scout.id.uuidString)
            LabeledContent("Image count", value: "\(scout.imageLocalPaths.count)")
            Text("Images: \(scout.imageLocalPaths.map { URL(filePath: $0).lastPathComponent }.joined(separator: ", "))")
                .font(.caption)
        }
    }
    #endif

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

    private var remainingImageSlots: Int {
        max(ProductScout.maxImageCount - scout.imageLocalPaths.count, 1)
    }

    private var photoSavePreference: PhotoLibrarySavePreference {
        PhotoLibrarySavePreference.resolved(from: photoSavePreferenceRaw)
    }

    private func saveCapturedPhotoIfEnabled(_ image: UIImage) {
        guard photoSavePreference == .on else { return }
        Task { await saveCopyToPhotos(image) }
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
