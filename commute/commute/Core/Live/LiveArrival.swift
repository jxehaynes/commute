import Foundation

/// A single live prediction for a boarding stop, mapped from `TfLPrediction`
/// into app-facing types. `expectedArrival` is computed once at fetch time so
/// `minutesAway` stays correct between polls instead of drifting.
struct LiveArrival: Identifiable, Hashable {
    var id: String
    var lineName: String
    var mode: LegKind
    var stationName: String
    var destinationName: String
    var expectedArrival: Date
    var naptanId: String

    init(prediction: TfLPrediction, fetchedAt: Date) {
        self.id = "\(prediction.vehicleId)-\(prediction.lineName)"
        self.lineName = prediction.lineName
        self.mode = LegKind(tflModeName: prediction.modeName)
        self.stationName = prediction.stationName
        self.destinationName = prediction.destinationName
        self.expectedArrival = fetchedAt.addingTimeInterval(TimeInterval(prediction.timeToStation))
        self.naptanId = prediction.naptanId
    }

    func minutesAway(from now: Date = .now) -> Double {
        max(0, expectedArrival.timeIntervalSince(now) / 60)
    }
}

extension LegKind {
    /// Maps a TfL `modeName` (e.g. "tube", "bus", "overground") onto the
    /// app's own transit mode enum. Surface/rail modes not listed explicitly
    /// (overground, elizabeth-line, dlr, national-rail) fall back to `.rail`.
    init(tflModeName: String) {
        switch tflModeName {
        case "tube": self = .tube
        case "bus": self = .bus
        case "walking": self = .walk
        case "cycle-hire", "cycle": self = .cycle
        default: self = .rail
        }
    }
}
