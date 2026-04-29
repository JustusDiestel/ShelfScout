import PhotosUI
import SwiftData
import SwiftUI

struct NewScoutView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(PhotoLibrarySavePreference.storageKey) private var photoSavePreferenceRaw = PhotoLibrarySavePreference.on.rawValue
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var previewImages: [UIImage] = []
    @State private var createdScout: ProductScout?
    @State private var showingCamera = false
    @StateObject private var viewModel = ScoutEditorViewModel()
    private let photoLibrarySaveService = PhotoLibrarySaveService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Scout")
                            .font(.title2.bold())
                        Text("Capture a product idea from photos or create one manually.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 12) {
                        Button {
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                showingCamera = true
                            } else {
                                viewModel.message = "Camera is not available here. You can choose an image or continue manually."
                            }
                        } label: {
                            Label("Take Photos", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .accessibilityLabel("Take product photo")

                        PhotosPicker(selection: $selectedPhotos, maxSelectionCount: ProductScout.maxImageCount, matching: .images) {
                            Label("Choose Photos", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                        Button {
                            openScout(ProductScout())
                        } label: {
                            Label("Manual Entry", systemImage: "square.and.pencil")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }

                    if !previewImages.isEmpty {
                        selectedImagesPreview
                    }

                    if viewModel.isAnalyzingImages {
                        ProgressView("Analyzing images locally...")
                    }
                    if let message = viewModel.message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
            }
            .navigationTitle("New Scout")
            .navigationDestination(item: $createdScout) { scout in
                ScoutEditorView(scout: scout)
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraPicker { image in
                    let scout = ProductScout()
                    modelContext.insert(scout)
                    Task { await viewModel.applyImage(image, to: scout) }
                    createdScout = scout
                    saveCapturedPhotoIfEnabled(image)
                }
                .ignoresSafeArea()
            }
            .onChange(of: selectedPhotos) { _, newValue in
                guard !newValue.isEmpty else { return }
                let scout = ProductScout()
                openScout(scout)
                Task {
                    previewImages = await loadPreviewImages(from: newValue)
                    await viewModel.loadPhotoPickerItems(newValue, into: scout)
                    selectedPhotos = []
                }
            }
        }
    }

    private var selectedImagesPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selected images")
                .font(.headline)
            Text("Images \(previewImages.count)/\(ProductScout.maxImageCount)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(Array(previewImages.enumerated()), id: \.offset) { _, image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(4 / 3, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func openScout(_ scout: ProductScout) {
        modelContext.insert(scout)
        createdScout = scout
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

    private func loadPreviewImages(from items: [PhotosPickerItem]) async -> [UIImage] {
        var images: [UIImage] = []
        for item in items.prefix(ProductScout.maxImageCount) {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        return images
    }
}
