import CommuteKit
import Foundation

/// Given live arrivals for a boarding stop and how long it takes to walk
/// there, decides which vehicle the user should aim for and whether they're
/// at risk of missing an earlier one. Shared by `TfLETAProvider` (feeds the
/// Live Activity) and `DirectionsViewModel` (feeds the in-app directions
/// view) so both frame the "leave now" decision identically.
enum CommuteDecision {
    struct Result {
        var chosen: LiveArrival?
        /// Minutes to wait at the stop after arriving there on foot.
        var waitMinutes: Int
        var disruption: DisruptionLevel
        var disruptionMessage: String?
    }

    static func choose(from arrivals: [LiveArrival], walkMinutes: Int, now: Date = .now) -> Result {
        guard !arrivals.isEmpty else {
            return Result(chosen: nil, waitMinutes: 0, disruption: .severe, disruptionMessage: "No live arrivals for this stop")
        }

        let sorted = arrivals.sorted { $0.expectedArrival < $1.expectedArrival }
        guard let chosen = sorted.first(where: { $0.minutesAway(from: now) >= Double(walkMinutes) }) else {
            return Result(
                chosen: nil,
                waitMinutes: 0,
                disruption: .severe,
                disruptionMessage: "You'll miss every predicted arrival on the walk over"
            )
        }

        let waitMinutes = max(0, Int((chosen.minutesAway(from: now) - Double(walkMinutes)).rounded()))
        guard chosen.id == sorted[0].id else {
            let missedMinutes = Int(sorted[0].minutesAway(from: now).rounded())
            return Result(
                chosen: chosen,
                waitMinutes: waitMinutes,
                disruption: .minor,
                disruptionMessage: "Next one in \(waitMinutes) min — you'll miss the \(missedMinutes)-min one"
            )
        }

        return Result(chosen: chosen, waitMinutes: waitMinutes, disruption: .onTime, disruptionMessage: nil)
    }
}
