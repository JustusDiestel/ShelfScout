import UIKit

enum ImageStorageService {
    static let folderName = "ProductPhotos"

    static func save(_ image: UIImage, compressionQuality: CGFloat = 0.86) throws -> String {
        let directory = try imageDirectory()
        let fileURL = directory.appendingPathComponent("\(UUID().uuidString).jpg")
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            throw AppError.message("The image could not be saved.")
        }
        try data.write(to: fileURL, options: .atomic)
        return fileURL.path
    }

    static func saveJPEGData(_ data: Data) throws -> String {
        let directory = try imageDirectory()
        let fileURL = directory.appendingPathComponent("\(UUID().uuidString).jpg")
        try data.write(to: fileURL, options: .atomic)
        return fileURL.path
    }

    static func load(path: String?) -> UIImage? {
        guard let path else { return nil }
        return UIImage(contentsOfFile: path)
    }

    static func delete(path: String?) {
        guard let path else { return }
        try? FileManager.default.removeItem(atPath: path)
    }

    static func jpegBase64(path: String?) -> String? {
        guard let path, let data = try? Data(contentsOf: URL(filePath: path)) else { return nil }
        return data.base64EncodedString()
    }

    private static func imageDirectory() throws -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directory = documents.appendingPathComponent(folderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }
}
