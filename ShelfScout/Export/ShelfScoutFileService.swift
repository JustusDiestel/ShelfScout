import Foundation

enum ShelfScoutFileService {
    static func documentData(for scout: ProductScout) throws -> Data {
        let dto = ProductScoutDTO(from: scout, photoBase64: ImageStorageService.jpegBase64(path: scout.primaryImagePath))
        return try encoder.encode(ShelfScoutDocument(product: dto))
    }

    static func archiveData(for scouts: [ProductScout]) throws -> Data {
        let products = scouts.map {
            ProductScoutDTO(from: $0, photoBase64: ImageStorageService.jpegBase64(path: $0.primaryImagePath))
        }
        return try encoder.encode(ShelfScoutArchive(products: products))
    }

    static func writeDocument(for scout: ProductScout) throws -> URL {
        let safeTitle = scout.displayTitle.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(safeTitle).shelfscout")
        try documentData(for: scout).write(to: url, options: .atomic)
        return url
    }

    static func writeArchive(for scouts: [ProductScout]) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ShelfScout Archive.shelfscout")
        try archiveData(for: scouts).write(to: url, options: .atomic)
        return url
    }

    static func decodeProducts(from data: Data) throws -> [ProductScoutDTO] {
        if let document = try? decoder.decode(ShelfScoutDocument.self, from: data) {
            guard document.schemaVersion == 1, document.app == "ShelfScout" else {
                throw AppError.message("This .shelfscout file is not supported.")
            }
            return [document.product]
        }

        let archive = try decoder.decode(ShelfScoutArchive.self, from: data)
        guard archive.schemaVersion == 1, archive.app == "ShelfScout" else {
            throw AppError.message("This .shelfscout archive is not supported.")
        }
        return archive.products
    }

    static func makeModel(from dto: ProductScoutDTO) throws -> ProductScout {
        var imagePaths: [String] = []
        for base64 in dto.productPhotoJPEGBase64s.prefix(ProductScout.maxImageCount) {
            if let data = Data(base64Encoded: base64) {
                imagePaths.append(try ImageStorageService.saveJPEGData(data))
            }
        }

        if imagePaths.isEmpty, let base64 = dto.productPhotoJPEGBase64, let data = Data(base64Encoded: base64) {
            imagePaths.append(try ImageStorageService.saveJPEGData(data))
        }
        let model = dto.makeModel(photoPath: imagePaths.first, imagePaths: imagePaths)
        model.id = UUID()
        model.createdAt = Date()
        model.updatedAt = Date()
        model.setImageLocalPaths(imagePaths)
        return model
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
