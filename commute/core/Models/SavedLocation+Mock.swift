import CoreLocation
import Foundation

extension SavedLocation {
    static let ephemeralCurrentLocationID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    static func ephemeral(at coordinate: CLLocationCoordinate2D) -> SavedLocation {
        SavedLocation(
            id: ephemeralCurrentLocationID,
            label: .other,
            customName: "Current location",
            address: "Current location",
            coordinate: coordinate,
            schedule: .empty
        )
    }

    static func mock(
        label: LocationLabel,
        customName: String? = nil,
        address: String? = nil
    ) -> SavedLocation {
        let defaultAddress: String
        let coordinate: (Double, Double)
        switch label {
        case .home:
            defaultAddress = "12 Camden Road, London NW1"
            coordinate = (51.539, -0.143)
        case .work:
            defaultAddress = "1 Canada Square, London E14"
            coordinate = (51.505, -0.023)
        case .other:
            defaultAddress = "45 Old Street, London EC1"
            coordinate = (51.525, -0.087)
        }
        return SavedLocation(
            id: UUID(),
            label: label,
            customName: customName,
            address: address ?? defaultAddress,
            coordinate: .init(latitude: coordinate.0, longitude: coordinate.1),
            schedule: PlaceSchedule.defaulted(for: label)
        )
    }
}
