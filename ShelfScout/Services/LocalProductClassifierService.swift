import CoreML
import UIKit
import Vision

enum LocalProductClassifierError: LocalizedError {
    case noImage
    case modelUnavailable
    case classificationFailed

    var errorDescription: String? {
        switch self {
        case .noImage:
            "Add a product photo before running local suggestions."
        case .modelUnavailable:
            "Local classifier model is not available."
        case .classificationFailed:
            "Local photo suggestions could not be generated."
        }
    }
}

final class LocalProductClassifierService {
    private let modelName = "ShelfScoutProductClassifier"

    func classify(image: UIImage) async throws -> ProductClassificationResult {
        guard let cgImage = image.cgImage else { throw LocalProductClassifierError.noImage }
        return try await classify(cgImage: cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation))
    }

    func classify(imageFileURL: URL) async throws -> ProductClassificationResult {
        guard let image = UIImage(contentsOfFile: imageFileURL.path) else {
            throw LocalProductClassifierError.noImage
        }
        return try await classify(image: image)
    }

    private func classify(cgImage: CGImage, orientation: CGImagePropertyOrientation) async throws -> ProductClassificationResult {
        let model = try loadVisionModel()

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if error != nil {
                    continuation.resume(throwing: LocalProductClassifierError.classificationFailed)
                    return
                }

                let observations = (request.results as? [VNClassificationObservation] ?? [])
                    .sorted { $0.confidence > $1.confidence }
                let labels = observations.prefix(5).map {
                    ClassificationLabel(label: $0.identifier, confidence: Double($0.confidence))
                }
                continuation.resume(returning: ClassificationLabelMapper.map(labels: labels))
            }
            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            Task.detached(priority: .userInitiated) {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: LocalProductClassifierError.classificationFailed)
                }
            }
        }
    }

    private func loadVisionModel() throws -> VNCoreMLModel {
        guard let url = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw LocalProductClassifierError.modelUnavailable
        }
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        let model = try MLModel(contentsOf: url, configuration: configuration)
        return try VNCoreMLModel(for: model)
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
