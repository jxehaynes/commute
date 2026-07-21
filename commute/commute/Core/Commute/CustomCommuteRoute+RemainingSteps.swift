import Foundation

extension CustomCommuteRoute {
    /// The first non-walk step — the boarding leg a live TfL-backed estimate
    /// replaces.
    var firstTransitStep: Step? {
        steps.first { $0.mode != .walk }
    }

    /// Steps after the first transit leg, for appending after a live estimate
    /// of that first leg.
    var stepsAfterFirstTransit: [Step] {
        guard isValid, let firstTransitIndex = steps.firstIndex(where: { $0.mode != .walk }) else { return [] }
        return Array(steps[(firstTransitIndex + 1)...])
    }
}
