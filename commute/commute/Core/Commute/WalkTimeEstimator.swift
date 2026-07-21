import CoreLocation
import Foundation

/// Straight-line walk-time estimate from a saved place to its resolved
/// boarding stop. A placeholder for a proper `MKDirections`-based estimate
/// later — good enough to seed the "leave by" decision now.
enum WalkTimeEstimator {
    static func minutes(
        from origin: SavedLocation,
        walkingSpeedMetersPerSecond: Double = 1.3,
        defaultMinutes: Int = 5
    ) -> Int {
        guard let start = origin.coordinate, let stop = origin.routingCoordinate else {
            return defaultMinutes
        }
        let distanceMeters = CLLocation(latitude: start.latitude, longitude: start.longitude)
            .distance(from: CLLocation(latitude: stop.latitude, longitude: stop.longitude))
        return max(1, Int((distanceMeters / walkingSpeedMetersPerSecond / 60).rounded()))
    }
}
