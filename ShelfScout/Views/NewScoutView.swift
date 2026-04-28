import PhotosUI
import SwiftData
import SwiftUI

struct NewScoutView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(PhotoLibrarySavePreference.storageKey) private var photoSavePreferenceRaw = PhotoLibrarySavePreference.askEveryTime.rawValue
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var createdScout: ProductScout?
    @State private var showingCamera = false
    @State private var pendingPhotosImage: UIImage?
    @State private var pendingCreatedScout: ProductScout?
    @State private var showingSaveToPhotosConfirmation = false
    @StateObject private var viewModel = ScoutEditorViewModel()
    private let photoLibrarySaveService = PhotoLibrarySaveService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer(minLength: 20)
                Image(systemName: "plus.viewfinder")
                    .font(.system(size: 54))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)

                Text("Create a product scout")
                    .font(.title2.bold())
                Text("Capture a product idea, run on-device OCR, review the fields, and save it locally.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showingCamera = true
                    } else {
                        viewModel.message = "Camera is not available here. You can choose an image or continue manually."
                    }
                } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("Take product photo")

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Choose Image", systemImage: "photo.on.rectangle")
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

                if viewModel.isRunningOCR {
                    ProgressView("Reading text locally...")
                }
                if let message = viewModel.message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("New Scout")
            .navigationDestination(item: $createdScout) { scout in
                ScoutEditorView(scout: scout)
            }
            .sheet(isPresented: $showingCamera) {
                CameraPicker { image in
                    let scout = ProductScout()
                    modelContext.insert(scout)
                    Task { await viewModel.applyImage(image, to: scout) }
                    handleCapturedPhotoSavePreference(image, scout: scout)
                }
                .ignoresSafeArea()
            }
            .confirmationDialog("Save a copy to Photos", isPresented: $showingSaveToPhotosConfirmation, titleVisibility: .visible) {
                Button("Save a copy to Photos") {
                    if let image = pendingPhotosImage {
                        Task { await saveCopyToPhotos(image) }
                    }
                    if let scout = pendingCreatedScout {
                        createdScout = scout
                    }
                    pendingPhotosImage = nil
                    pendingCreatedScout = nil
                }
                Button("Keep in ShelfScout Only", role: .cancel) {
                    if let scout = pendingCreatedScout {
                        createdScout = scout
                    }
                    pendingPhotosImage = nil
                    pendingCreatedScout = nil
                    viewModel.message = "Photo was saved in ShelfScout only."
                }
            } message: {
                Text("Photos saved to Apple Photos may sync with iCloud depending on your personal iCloud settings.")
            }
            .onChange(of: selectedPhoto) { _, newValue in
                let scout = ProductScout()
                openScout(scout)
                Task { await viewModel.loadPhotoPickerItem(newValue, into: scout) }
            }
        }
    }

    private func openScout(_ scout: ProductScout) {
        modelContext.insert(scout)
        createdScout = scout
    }

    private var photoSavePreference: PhotoLibrarySavePreference {
        PhotoLibrarySavePreference(rawValue: photoSavePreferenceRaw) ?? .askEveryTime
    }

    private func handleCapturedPhotoSavePreference(_ image: UIImage, scout: ProductScout) {
        switch photoSavePreference {
        case .askEveryTime:
            pendingCreatedScout = scout
            pendingPhotosImage = image
            showingSaveToPhotosConfirmation = true
        case .always:
            createdScout = scout
            Task { await saveCopyToPhotos(image) }
        case .never:
            createdScout = scout
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
