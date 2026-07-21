import Combine
import CoreLocation
import Foundation

@MainActor
final class LocationPermissionManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus

    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    var isAlwaysAllowed: Bool {
        authorizationStatus == .authorizedAlways
    }

    var statusLabel: String {
        switch authorizationStatus {
        case .authorizedAlways:
            "Always allowed"
        case .authorizedWhenInUse:
            "Allowed while using"
        case .denied:
            "Denied"
        case .restricted:
            "Restricted"
        case .notDetermined:
            "Not set"
        @unknown default:
            "Unknown"
        }
    }

    var explanation: String {
        switch authorizationStatus {
        case .authorizedAlways:
            "Commute can help with proactive leave-time prompts and automatic journey context."
        case .authorizedWhenInUse:
            "Location works while the app is open. Always access enables proactive commute features later."
        case .denied, .restricted:
            "Location is off for Commute. You can enable it later in Settings."
        case .notDetermined:
            "Allow location access so Commute can understand where your journey starts."
        @unknown default:
            "Location access can be changed later in Settings."
        }
    }

    func requestAlwaysAccess() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        manager.requestAlwaysAuthorization()
    }

    func requestWhenInUseAccess() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        manager.requestWhenInUseAuthorization()
    }
}

extension LocationPermissionManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = status
        }
    }
}
