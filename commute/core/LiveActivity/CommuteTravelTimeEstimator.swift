import CommuteKit
import Foundation

struct CommuteTravelEstimate: Equatable {
    var totalMinutes: Int
    var routeSteps: [RouteStepSummary]
}

enum CommuteTravelTimeEstimator {
    /// Prefers, in order: the user's saved custom route (an exact, known duration — never
    /// re-fetched live, since a live lookup could return a different route than the one they
    /// actually built), then a live route fetch so the estimate reflects current conditions,
    /// then the static profile-based duration if the live fetch fails (offline, provider down).
    static func estimate(
        for profile: UserProfile,
        leg: CommuteLeg,
        routeProvider: any RouteProviding = BestAvailableRouteProvider(),
        disruptionProvider: any DisruptionProviding = DisruptionStore.shared
    ) async -> CommuteTravelEstimate {
        if let customRoute = profile.journeyRoute(from: leg.origin, to: leg.destination), customRoute.isValid {
            let steps = customRoute.steps.map {
                RouteStepSummary(icon: $0.mode.systemImage, label: stepLabel(for: $0))
            }
            return CommuteTravelEstimate(
                totalMinutes: customRoute.steps.reduce(0) { $0 + $1.estimatedMinutes },
                routeSteps: steps
            )
        }

        if let liveEstimate = await liveEstimate(
            profile: profile,
            leg: leg,
            routeProvider: routeProvider,
            disruptionProvider: disruptionProvider
        ) {
            return liveEstimate
        }

        return staticEstimate(for: profile)
    }

    private static func liveEstimate(
        profile: UserProfile,
        leg: CommuteLeg,
        routeProvider: any RouteProviding,
        disruptionProvider: any DisruptionProviding
    ) async -> CommuteTravelEstimate? {
        guard let routes = try? await routeProvider.fetchRoutes(
            from: leg.origin,
            to: leg.destination,
            query: .departingNow
        ) else {
            return nil
        }

        let disruptions = (try? await disruptionProvider.fetchDisruptions()) ?? []

        guard let best = RouteScorer.preferredRoute(
            from: routes,
            preference: profile.preferredCommutePattern,
            disruptions: disruptions
        ) else {
            return nil
        }

        return CommuteTravelEstimate(totalMinutes: best.totalMinutes, routeSteps: routeSteps(from: best))
    }

    private static func staticEstimate(for profile: UserProfile) -> CommuteTravelEstimate {
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

    private static func routeSteps(from route: Route) -> [RouteStepSummary] {
        let steps = route.legs.map { leg -> RouteStepSummary in
            switch leg {
            case .walk:
                return RouteStepSummary(icon: "figure.walk", label: "Walk")
            case .transit(let line, _, _, _, _, _, let lineLabel):
                let isBus = line == .bus || lineLabel?.localizedCaseInsensitiveContains("bus") == true
                return RouteStepSummary(
                    icon: isBus ? "bus.fill" : "tram.fill",
                    label: lineLabel ?? line.displayName
                )
            }
        }
        return steps.isEmpty ? [RouteStepSummary(icon: "figure.walk", label: "Commute")] : steps
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
