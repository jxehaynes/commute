import CommuteKit
import Foundation

/// A resolved travel-time estimate for one leg of the commute.
struct CommuteETA {
    var totalMinutes: Int
    var steps: [RouteStepSummary]
    var disruption: DisruptionLevel
    var disruptionMessage: String?
}

/// Anything that can estimate how long a journey between two saved places
/// will take. `CommuteLiveActivityScheduler` only depends on this protocol,
/// so a live routing/TfL-backed provider can replace `StaticScheduleETAProvider`
/// later without any change to the scheduling logic.
protocol CommuteETAProviding {
    func estimate(
        from origin: SavedLocation,
        to destination: SavedLocation,
        departing date: Date
    ) async throws -> CommuteETA
}
