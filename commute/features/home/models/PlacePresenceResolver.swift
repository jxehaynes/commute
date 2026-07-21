import CoreLocation
import Foundation

enum PlacePresence: Equatable {
    case atSavedPlace(SavedLocation)
    case elsewhere
    case unknown

    var displayText: String {
        switch self {
        case .atSavedPlace(let place):
            "You're at \(place.displayName)"
        case .elsewhere:
            "You're on the move"
        case .unknown:
            "Finding your location…"
        }
    }
}

enum PlacePresenceResolver {
    private static let matchRadiusMeters: CLLocationDistance = 150

    static func resolve(
        userLocation: CLLocation?,
        savedPlaces: [SavedLocation]
    ) -> PlacePresence {
        guard let userLocation else { return .unknown }

        let matches = savedPlaces.compactMap { place -> (SavedLocation, CLLocationDistance)? in
            let placeLocation = CLLocation(
                latitude: place.coordinate.latitude,
                longitude: place.coordinate.longitude
            )
            let distance = userLocation.distance(from: placeLocation)
            guard distance <= matchRadiusMeters else { return nil }
            return (place, distance)
        }

        guard !matches.isEmpty else { return .elsewhere }

        let closestDistance = matches.map(\.1).min() ?? .infinity
        let closest = matches.filter { $0.1 == closestDistance }

        if closest.count == 1, let place = closest.first?.0 {
            return .atSavedPlace(place)
        }

        let priority: [SavedLocation.LocationLabel] = [.home, .work, .other]
        for label in priority {
            if let place = closest.first(where: { $0.0.label == label })?.0 {
                return .atSavedPlace(place)
            }
        }

        if let place = closest.first?.0 {
            return .atSavedPlace(place)
        }

        return .elsewhere
    }
}
