import CommuteKit
import Foundation

/// Default `CommuteETAProviding` implementation: sums the user's saved
/// custom-route step estimates, or falls back to a flat duration when no
/// custom route has been built. Always reports on-time service, since it has
/// no access to live conditions — that's the seam a real routing/disruption
/// feed plugs into later.
struct StaticScheduleETAProvider: CommuteETAProviding {
    var customRoute: CustomCommuteRoute?
    var fallbackMinutes: Int = 35

    func estimate(
        from origin: SavedLocation,
        to destination: SavedLocation,
        departing date: Date
    ) async throws -> CommuteETA {
        guard let customRoute, customRoute.isValid else {
            return CommuteETA(
                totalMinutes: fallbackMinutes,
                steps: [RouteStepSummary(icon: LegKind.walk.systemImage, label: "Commute")],
                disruption: .onTime,
                disruptionMessage: nil
            )
        }

        let steps = customRoute.steps.map {
            RouteStepSummary(icon: $0.mode.systemImage, label: $0.summary)
        }
        return CommuteETA(
            totalMinutes: customRoute.totalEstimatedMinutes,
            steps: steps,
            disruption: .onTime,
            disruptionMessage: nil
        )
    }
}
