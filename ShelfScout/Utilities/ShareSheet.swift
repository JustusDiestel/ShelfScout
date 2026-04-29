import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

@MainActor
enum SharePresenter {
    static func present(items: [Any]) throws {
        guard !items.isEmpty else {
            throw AppError.message("There is nothing to share.")
        }
        guard let controller = topViewController() else {
            throw AppError.message("The share sheet could not be opened.")
        }

        let activityController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = controller.view
            popover.sourceRect = CGRect(
                x: controller.view.bounds.midX,
                y: controller.view.bounds.midY,
                width: 1,
                height: 1
            )
            popover.permittedArrowDirections = []
        }
        controller.present(activityController, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        let root = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        return topViewController(from: root)
    }

    private static func topViewController(from controller: UIViewController?) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(from: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            return topViewController(from: tabController.selectedViewController)
        }
        if let presented = controller?.presentedViewController {
            return topViewController(from: presented)
        }
        return controller
    }
}

enum ExportFileValidator {
    static func validate(_ url: URL) throws -> URL {
        let exists = FileManager.default.fileExists(atPath: url.path)
        let size = ((try? FileManager.default.attributesOfItem(atPath: url.path)[.size]) as? NSNumber)?.int64Value ?? 0
        print("ShelfScout export file URL: \(url.path)")
        print("ShelfScout export file exists: \(exists)")
        print("ShelfScout export file size bytes: \(size)")

        guard exists, size > 0 else {
            throw AppError.message("The export file could not be created. Please try again.")
        }
        return url
    }
}
