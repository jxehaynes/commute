import CommuteKit
import Foundation

struct CommuteTravelEstimate: Equatable {
    var totalMinutes: Int
    var routeSteps: [RouteStepSummary]
}

enum CommuteTravelTimeEstimator {
    static func estimate(for profile: UserProfile, leg: CommuteLeg) -> CommuteTravelEstimate {
        if let customRoute = profile.journeyRoute(from: leg.origin, to: leg.destination), customRoute.isValid {
            let steps = customRoute.steps.map {
                RouteStepSummary(icon: $0.mode.systemImage, label: stepLabel(for: $0))
            }
            return CommuteTravelEstimate(
                totalMinutes: customRoute.steps.reduce(0) { $0 + $1.estimatedMinutes },
                routeSteps: steps
            )
        }

        if let pattern = profile.preferredCommutePattern {
            return CommuteTravelEstimate(
                totalMinutes: pattern.totalMinutes,
                routeSteps: routeSteps(from: pattern)
            )
        }

        return CommuteTravelEstimate(
            totalMinutes: profile.commuteSchedule.typicalTravelMinutes,
            routeSteps: [RouteStepSummary(icon: "figure.walk", label: "Commute")]
        )
    }

    private static func stepLabel(for step: CommuteBuilderStep) -> String {
        switch step.mode {
        case .walk:
            return "Walk"
        case .drive:
            return "Drive"
        case .bus, .train:
            return step.lineName ?? step.mode.label
        }
    }

    private static func routeSteps(from pattern: PreferredCommutePattern) -> [RouteStepSummary] {
        var steps: [RouteStepSummary] = []
        var lineIndex = 0

        for kind in pattern.legKinds {
            switch kind {
            case .walk:
                steps.append(RouteStepSummary(icon: "figure.walk", label: "Walk"))
            case .bus:
                let label = lineLabel(at: lineIndex, in: pattern.lineLabels, fallback: "Bus")
                lineIndex += 1
                steps.append(RouteStepSummary(icon: "bus.fill", label: label))
            case .tube, .elizabethLine, .overground, .dlr, .nationalRail, .transit:
                let label = lineLabel(at: lineIndex, in: pattern.lineLabels, fallback: kind.displayLabel)
                lineIndex += 1
                steps.append(RouteStepSummary(icon: "tram.fill", label: label))
            }
        }

        if steps.isEmpty {
            steps.append(RouteStepSummary(icon: "figure.walk", label: "Commute"))
        }

        return steps
    }

    private static func lineLabel(at index: Int, in labels: [String], fallback: String) -> String {
        guard index < labels.count else { return fallback }
        return labels[index]
    }
}
