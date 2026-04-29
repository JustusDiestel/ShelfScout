import PhotosUI
import SwiftUI

struct DetectedFieldSuggestions: Equatable {
    var title: String?
    var priceCandidates: [String] = []
    var currency: String?
    var barcode: String?
    var weight: String?
    var dimensions: String?

    var hasAny: Bool {
        title != nil ||
            !priceCandidates.isEmpty ||
            currency != nil ||
            barcode != nil ||
            weight != nil ||
            dimensions != nil
    }
}

@MainActor
final class ScoutEditorViewModel: ObservableObject {
    @Published var isRunningOCR = false
    @Published var analyzedImageCount = 0
    @Published var analysisWarning: String?
    @Published var detectedSuggestions = DetectedFieldSuggestions()
    @Published var message: String?

    private let ocrService = OCRService()
    private var activeRunID: UUID?

    func applyImage(_ image: UIImage, to scout: ProductScout) async {
        do {
            guard scout.imageLocalPaths.count < ProductScout.maxImageCount else {
                message = "A scout can have up to 4 images."
                return
            }
            let path = try ImageStorageService.save(image)
            scout.addImageLocalPath(path)
            await analyzeImages(for: scout)
        } catch {
            message = error.localizedDescription
        }
    }

    func loadPhotoPickerItems(_ items: [PhotosPickerItem], into scout: ProductScout) async {
        guard !items.isEmpty else { return }
        var added = 0
        for item in items {
            guard scout.imageLocalPaths.count < ProductScout.maxImageCount else { break }
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    throw AppError.message("One selected photo could not be opened.")
                }
                let path = try ImageStorageService.save(image)
                scout.addImageLocalPath(path)
                added += 1
            } catch {
                message = error.localizedDescription
            }
        }
        if added > 0 {
            await analyzeImages(for: scout)
        } else if scout.imageLocalPaths.count >= ProductScout.maxImageCount {
            message = "A scout can have up to 4 images."
        }
    }

    func analyzeImages(for scout: ProductScout) async {
        let paths = scout.imageLocalPaths
        guard !paths.isEmpty else {
            message = "Add product images before running OCR."
            return
        }

        let scoutID = scout.id
        let runID = UUID()
        activeRunID = runID
        isRunningOCR = true
        analyzedImageCount = 0
        analysisWarning = nil
        detectedSuggestions = DetectedFieldSuggestions()

        defer {
            if activeRunID == runID {
                isRunningOCR = false
                activeRunID = nil
            }
        }

        var texts: [String] = []
        var failures: [String] = []

        for (index, path) in paths.enumerated() {
            guard let image = ImageStorageService.load(path: path) else {
                texts.append("")
                failures.append("Image \(index + 1)")
                continue
            }
            do {
                texts.append(try await ocrService.recognizeText(from: image))
            } catch {
                texts.append("")
                failures.append("Image \(index + 1)")
            }
            analyzedImageCount += 1
        }

        guard activeRunID == runID, scout.id == scoutID else { return }

        scout.setRecognizedTextsByImage(texts)
        applyParsedValues(to: scout, text: scout.combinedRecognizedText)
        scout.ocrLastRunAt = Date()
        scout.updatedAt = Date()

        if !failures.isEmpty {
            analysisWarning = "Some images could not be read: \(failures.joined(separator: ", "))."
            message = analysisWarning
        } else if !detectedSuggestions.hasAny &&
                    scout.detectedPriceCandidates.isEmpty &&
                    scout.detectedBarcode == nil &&
                    scout.detectedWeight == nil &&
                    scout.detectedDimensions == nil {
            message = "No clear values detected. You can enter details manually."
        } else {
            message = "OCR checked \(paths.count) image\(paths.count == 1 ? "" : "s") locally."
        }
    }

    func removeImage(at index: Int, from scout: ProductScout) {
        if let removed = scout.removeImage(at: index) {
            ImageStorageService.delete(path: removed)
            scout.updatedAt = Date()
        }
    }

    func moveImage(from source: IndexSet, to destination: Int, in scout: ProductScout) {
        scout.moveImage(from: source, to: destination)
        scout.updatedAt = Date()
    }

    func setPrimaryImage(at index: Int, in scout: ProductScout) {
        scout.setPrimaryImage(at: index)
        scout.updatedAt = Date()
    }

    func useDetectedTitle(for scout: ProductScout) {
        guard let title = detectedSuggestions.title else { return }
        scout.title = title
        detectedSuggestions.title = nil
    }

    func useDetectedPrice(_ rawPrice: String, for scout: ProductScout) {
        scout.observedStorePrice = OCRParsingService.decimal(fromPriceText: rawPrice)
        detectedSuggestions.priceCandidates.removeAll { $0 == rawPrice }
    }

    func useDetectedCurrency(for scout: ProductScout) {
        guard let currency = detectedSuggestions.currency else { return }
        scout.currency = currency
        detectedSuggestions.currency = nil
    }

    func useDetectedBarcode(for scout: ProductScout) {
        scout.detectedBarcode = detectedSuggestions.barcode
        detectedSuggestions.barcode = nil
    }

    func useDetectedWeight(for scout: ProductScout) {
        scout.detectedWeight = detectedSuggestions.weight
        detectedSuggestions.weight = nil
    }

    func useDetectedDimensions(for scout: ProductScout) {
        scout.detectedDimensions = detectedSuggestions.dimensions
        detectedSuggestions.dimensions = nil
    }

    private func applyParsedValues(to scout: ProductScout, text: String) {
        let parsed = OCRParsingService.parse(text)
        scout.setDetectedPriceCandidates(parsed.priceCandidates)

        if let title = parsed.possibleTitle, OCRParsingService.isMeaningfulTitle(title) {
            if scout.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                scout.title = title
            } else if scout.title.caseInsensitiveCompare(title) != .orderedSame {
                detectedSuggestions.title = title
            }
        }

        if let price = parsed.price {
            if scout.observedStorePrice == nil {
                scout.observedStorePrice = price
            }
        } else if !parsed.priceCandidates.isEmpty {
            detectedSuggestions.priceCandidates = parsed.priceCandidates
        }

        if let currency = parsed.currency {
            if scout.currency.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                scout.currency = currency
            } else if scout.currency.caseInsensitiveCompare(currency) != .orderedSame {
                detectedSuggestions.currency = currency
            }
        }

        if let barcode = parsed.barcode {
            if scout.detectedBarcode == nil {
                scout.detectedBarcode = barcode
            } else if scout.detectedBarcode != barcode {
                detectedSuggestions.barcode = barcode
            }
        }

        if let weight = parsed.weightOrSize {
            if scout.detectedWeight == nil {
                scout.detectedWeight = weight
            } else if scout.detectedWeight != weight {
                detectedSuggestions.weight = weight
            }
        }

        if let dimensions = parsed.dimensions {
            if scout.detectedDimensions == nil {
                scout.detectedDimensions = dimensions
            } else if scout.detectedDimensions != dimensions {
                detectedSuggestions.dimensions = dimensions
            }
        }
    }
}
