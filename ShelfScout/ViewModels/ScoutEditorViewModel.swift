import PhotosUI
import SwiftUI

@MainActor
final class ScoutEditorViewModel: ObservableObject {
    @Published var isRunningOCR = false
    @Published var message: String?

    private let ocrService = OCRService()

    func applyImage(_ image: UIImage, to scout: ProductScout) async {
        do {
            scout.productPhotoLocalPath = try ImageStorageService.save(image)
            try await runOCR(on: image, scout: scout)
        } catch {
            message = error.localizedDescription
        }
    }

    func loadPhotoPickerItem(_ item: PhotosPickerItem?, into scout: ProductScout) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                throw AppError.message("The selected photo could not be opened.")
            }
            await applyImage(image, to: scout)
        } catch {
            message = error.localizedDescription
        }
    }

    func rerunOCR(for scout: ProductScout) async {
        guard let image = ImageStorageService.load(path: scout.productPhotoLocalPath) else {
            message = "Add a product photo before running OCR."
            return
        }
        do {
            try await runOCR(on: image, scout: scout)
        } catch {
            message = error.localizedDescription
        }
    }

    private func runOCR(on image: UIImage, scout: ProductScout) async throws {
        isRunningOCR = true
        defer { isRunningOCR = false }

        let text = try await ocrService.recognizeText(from: image)
        scout.recognizedText = text
        let parsed = OCRParsingService.parse(text)
        if scout.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            scout.title = parsed.possibleTitle ?? scout.title
        }
        if scout.researchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            scout.researchQuery = ProductScout.defaultResearchQuery(title: scout.title, category: scout.category)
        }
        if scout.observedStorePrice == nil {
            scout.observedStorePrice = parsed.price
        }
        if scout.detectedBarcodeOrEAN == nil {
            scout.detectedBarcodeOrEAN = parsed.barcode
        }
        if scout.productDescription.isEmpty {
            scout.productDescription = [parsed.weightOrSize, parsed.dimensions]
                .compactMap { $0 }
                .joined(separator: " · ")
        }
        scout.updatedAt = Date()
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            message = "No readable text was found. You can still fill out the scout manually."
        }
    }
}
