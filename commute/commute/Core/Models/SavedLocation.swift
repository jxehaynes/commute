import CoreLocation
import Foundation

/// A place the user commutes to/from, saved during onboarding or Settings.
struct SavedLocation: Codable, Hashable, Identifiable {
    enum LocationLabel: String, Codable, Hashable {
        case home
        case work
        case other
    }

    var id: UUID
    var label: LocationLabel
    var customName: String?
    var address: String
    private var latitude: Double?
    private var longitude: Double?
    /// TfL NaPTAN identifier for the nearest stop, when resolved from a transit search.
    var naptanId: String?
    private var routingLatitude: Double?
    private var routingLongitude: Double?

    var coordinate: CLLocationCoordinate2D? {
        get {
            guard let latitude, let longitude else { return nil }
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            latitude = newValue?.latitude
            longitude = newValue?.longitude
        }
    }

    /// A coordinate snapped to the routing network (e.g. a station entrance), if different from `coordinate`.
    var routingCoordinate: CLLocationCoordinate2D? {
        get {
            guard let routingLatitude, let routingLongitude else { return nil }
            return CLLocationCoordinate2D(latitude: routingLatitude, longitude: routingLongitude)
        }
        set {
            routingLatitude = newValue?.latitude
            routingLongitude = newValue?.longitude
        }
    }

    init(
        id: UUID,
        label: LocationLabel,
        customName: String?,
        address: String,
        coordinate: CLLocationCoordinate2D?,
        naptanId: String?,
        routingCoordinate: CLLocationCoordinate2D?
    ) {
        self.id = id
        self.label = label
        self.customName = customName
        self.address = address
        self.naptanId = naptanId
        self.latitude = coordinate?.latitude
        self.longitude = coordinate?.longitude
        self.routingLatitude = routingCoordinate?.latitude
        self.routingLongitude = routingCoordinate?.longitude
    }

    var displayName: String {
        if let customName, !customName.trimmingCharacters(in: .whitespaces).isEmpty {
            return customName
        }
        switch label {
        case .home: return "Home"
        case .work: return "Work"
        case .other: return "Other"
        }
    }

    static func mock(label: LocationLabel, customName: String? = nil, address: String) -> SavedLocation {
        SavedLocation(
            id: UUID(),
            label: label,
            customName: customName,
            address: address,
            coordinate: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
            naptanId: nil,
            routingCoordinate: nil
        )
    }
}
