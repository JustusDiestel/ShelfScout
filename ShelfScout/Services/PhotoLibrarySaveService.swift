import Photos
import UIKit

enum PhotoLibrarySavePreference: String, CaseIterable, Identifiable {
    case on = "On"
    case off = "Off"

    static let storageKey = "photoLibrarySavePreference"

    var id: String { rawValue }

    static func resolved(from rawValue: String) -> PhotoLibrarySavePreference {
        PhotoLibrarySavePreference(rawValue: rawValue) ?? .on
    }
}

enum PhotoLibrarySaveError: LocalizedError {
    case denied
    case restricted
    case failed

    var errorDescription: String? {
        switch self {
        case .denied:
            "Photo saved in ShelfScout only. Photos permission is disabled."
        case .restricted:
            "Photos permission is restricted. Photo was saved in ShelfScout only."
        case .failed:
            "Photo was saved in ShelfScout only."
        }
    }
}

final class PhotoLibrarySaveService {
    func saveImageToPhotos(_ image: UIImage) async throws {
        let status = await authorizationStatus()
        guard status == .authorized || status == .limited else {
            if status == .restricted { throw PhotoLibrarySaveError.restricted }
            throw PhotoLibrarySaveError.denied
        }

        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PhotoLibrarySaveError.failed)
                }
            }
        }
    }

    private func authorizationStatus() async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        guard current == .notDetermined else { return current }

        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: status)
            }
        }
    }
}
