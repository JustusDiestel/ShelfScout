import SwiftUI

struct ScoutPhotoView: View {
    let path: String?

    var body: some View {
        Group {
            if let image = ImageStorageService.load(path: path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.secondary.opacity(0.16))
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
