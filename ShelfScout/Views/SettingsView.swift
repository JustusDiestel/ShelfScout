import CoreLocation
import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var scouts: [ProductScout]
    @AppStorage(PhotoLibrarySavePreference.storageKey) private var photoSavePreferenceRaw = PhotoLibrarySavePreference.on.rawValue
    @State private var showingDeleteConfirmation = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Privacy") {
                    Text("ShelfScout stores your product scouts locally on this iPhone. No account, no cloud sync, no analytics, no tracking, and no automatic uploads.")
                    Text("Location is optional and only used when you choose to add the current location to a scout.")
                    Text("Photo suggestions are generated locally on this iPhone using an embedded Core ML model. Photos and results are not uploaded.")
                    Text("Product photos are stored locally in ShelfScout. If you choose to save copies to Apple Photos, they may sync with iCloud depending on your iCloud settings.")
                }

                Section("Permissions") {
                    LabeledContent("Location", value: locationStatusText)
                    Text("Core scouting works without camera, photo library, or location permission. Denied permissions can be handled with manual entry.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Photos") {
                    Picker("Save captured photos to Apple Photos", selection: $photoSavePreferenceRaw) {
                        ForEach(PhotoLibrarySavePreference.allCases) { preference in
                            Text(preference.rawValue).tag(preference.rawValue)
                        }
                    }
                    Text("Captured photos are always stored locally in ShelfScout. If enabled, copies are also saved to Apple Photos. Photos may sync with iCloud depending on your iCloud settings.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Local Data") {
                    Button("Export all data as CSV", systemImage: "tablecells") {
                        do { present(try CSVExportService.writeCSV(for: scouts)) } catch { message = error.localizedDescription }
                    }
                    Button("Export all data as .shelfscout archive", systemImage: "archivebox") {
                        do { present(try ShelfScoutFileService.writeArchive(for: scouts)) } catch { message = error.localizedDescription }
                    }
                    Button("Delete all local data", systemImage: "trash", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                }

                Section("About") {
                    LabeledContent("App version", value: appVersion)
                    Text("This is a local scouting estimate and does not replace legal, safety, tax, customs, or compliance review.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .alert("ShelfScout", isPresented: Binding(get: { message != nil }, set: { _ in message = nil })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
            .confirmationDialog("Delete all local scouts?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete all", role: .destructive) {
                    for scout in scouts {
                        ImageStorageService.delete(paths: scout.imageLocalPaths)
                        modelContext.delete(scout)
                    }
                }
            }
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var locationStatusText: String {
        switch CLLocationManager().authorizationStatus {
        case .notDetermined: "Not requested"
        case .restricted: "Restricted"
        case .denied: "Denied"
        case .authorizedAlways, .authorizedWhenInUse: "Allowed while using"
        @unknown default: "Unknown"
        }
    }

    private func present(_ url: URL) {
        do {
            try SharePresenter.present(items: [ExportFileValidator.validate(url)])
        } catch {
            message = error.localizedDescription
        }
    }
}
