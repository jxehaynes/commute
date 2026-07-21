import CommuteKit
import Foundation

/// Live, TfL-backed `CommuteETAProviding`. Resolves the boarding stop from
/// the origin's saved `naptanId`, factors in live arrivals via
/// `ArrivalsRepository`, and falls back to `fallback` whenever there's no
/// stop to check or TfL has nothing useful to say about it — this is the
/// live provider `CommuteETAProviding`'s doc comment anticipated replacing
/// `StaticScheduleETAProvider` with.
struct TfLETAProvider: CommuteETAProviding {
    var fallback: CommuteETAProviding
    var repository: ArrivalsRepository
    var customRoute: CustomCommuteRoute?
    var preferredPattern: CommutePattern?

    func estimate(
        from origin: SavedLocation,
        to destination: SavedLocation,
        departing date: Date
    ) async throws -> CommuteETA {
        guard let naptanId = origin.naptanId else {
            return try await fallback.estimate(from: origin, to: destination, departing: date)
        }

        guard let predictions = try? await repository.arrivals(for: naptanId, now: date) else {
            return try await fallback.estimate(from: origin, to: destination, departing: date)
        }

        let candidates = matchingPreferredLine(in: predictions)
        guard !candidates.isEmpty else {
            return try await fallback.estimate(from: origin, to: destination, departing: date)
        }

        let walkMinutes = WalkTimeEstimator.minutes(from: origin)
        let decision = CommuteDecision.choose(from: candidates, walkMinutes: walkMinutes, now: date)
        let remainingSteps = (customRoute?.stepsAfterFirstTransit ?? []).map {
            RouteStepSummary(icon: $0.mode.systemImage, label: $0.summary)
        }
        let remainingMinutes = (customRoute?.stepsAfterFirstTransit ?? []).reduce(0) { $0 + $1.estimatedMinutes }

        guard let chosen = decision.chosen else {
            return CommuteETA(
                totalMinutes: walkMinutes + remainingMinutes,
                steps: [RouteStepSummary(icon: LegKind.walk.systemImage, label: "Walk to stop")] + remainingSteps,
                disruption: decision.disruption,
                disruptionMessage: decision.disruptionMessage
            )
        }

        let lineStep = RouteStepSummary(
            icon: chosen.mode.systemImage,
            label: "\(chosen.lineName) · \(Int(chosen.minutesAway(from: date).rounded())) min"
        )

        return CommuteETA(
            totalMinutes: walkMinutes + decision.waitMinutes + remainingMinutes,
            steps: [RouteStepSummary(icon: LegKind.walk.systemImage, label: "Walk to stop"), lineStep] + remainingSteps,
            disruption: decision.disruption,
            disruptionMessage: decision.disruptionMessage
        )
    }

    private func matchingPreferredLine(in predictions: [LiveArrival]) -> [LiveArrival] {
        let labels = preferredLineLabels
        guard !labels.isEmpty else { return predictions }
        let filtered = predictions.filter { arrival in
            labels.contains {
                arrival.lineName.localizedCaseInsensitiveContains($0) || $0.localizedCaseInsensitiveContains(arrival.lineName)
            }
        }
        return filtered.isEmpty ? predictions : filtered
    }

    private var preferredLineLabels: [String] {
        if let label = customRoute?.firstTransitStep?.summary {
            return [label]
        }
        return preferredPattern?.lineLabels ?? []
    }
}
