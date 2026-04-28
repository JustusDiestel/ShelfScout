import CoreLocation
import Foundation

struct ScoutLocation: Equatable {
    var label: String
    var latitude: Double
    var longitude: Double
}

enum LocationServiceError: LocalizedError {
    case denied
    case unavailable

    var errorDescription: String? {
        switch self {
        case .denied:
            return "Location access is off. You can type the location manually."
        case .unavailable:
            return "The current location could not be determined. You can type it manually."
        }
    }
}

@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var continuation: CheckedContinuation<ScoutLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    func requestCurrentLocation() async throws -> ScoutLocation {
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            throw LocationServiceError.denied
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            if authorizationStatus == .notDetermined {
                manager.requestWhenInUseAuthorization()
            } else {
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            switch authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                continuation?.resume(throwing: LocationServiceError.denied)
                continuation = nil
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            Task { @MainActor in
                continuation?.resume(throwing: LocationServiceError.unavailable)
                continuation = nil
            }
            return
        }

        Task { @MainActor in
            let label = await reverseGeocode(location) ?? formattedCoordinate(location)
            continuation?.resume(returning: ScoutLocation(
                label: label,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            ))
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(throwing: LocationServiceError.unavailable)
            continuation = nil
        }
    }

    private func reverseGeocode(_ location: CLLocation) async -> String? {
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first else { return nil }
        return [placemark.name, placemark.locality, placemark.administrativeArea]
            .compactMap { $0 }
            .removingDuplicates()
            .joined(separator: ", ")
    }

    private func formattedCoordinate(_ location: CLLocation) -> String {
        String(format: "%.5f, %.5f", location.coordinate.latitude, location.coordinate.longitude)
    }
}
