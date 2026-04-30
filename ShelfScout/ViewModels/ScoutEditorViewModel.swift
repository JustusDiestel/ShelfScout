import PhotosUI
import SwiftUI

@MainActor
final class ScoutEditorViewModel: ObservableObject {
    @Published var message: String?

    func applyImage(_ image: UIImage, to scout: ProductScout) async {
        do {
            guard scout.imageLocalPaths.count < ProductScout.maxImageCount else {
                message = "A scout can have up to 4 images."
                return
            }
            let path = try ImageStorageService.save(image)
            scout.addImageLocalPath(path)
            scout.updatedAt = Date()
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
            scout.updatedAt = Date()
        } else if scout.imageLocalPaths.count >= ProductScout.maxImageCount {
            message = "A scout can have up to 4 images."
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
}

