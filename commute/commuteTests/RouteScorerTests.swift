import Foundation
import Testing
@testable import commute

struct RouteScorerTests {
    private func route(line: TfLLine, totalMinutes: Int = 20) -> Route {
        Route(
            summary: "Via \(line.displayName)",
            totalMinutes: totalMinutes,
            legs: [
                .transit(
                    line: line,
                    from: "Bank",
                    to: "Tower Hill",
                    departureTime: nil,
                    platform: nil,
                    stops: 2,
                    lineLabel: nil
                )
            ],
            status: .goodService
        )
    }

    @Test func scoresRouteWithMatchingDisruptionLowerThanCleanRoute() {
        let disruptedRoute = route(line: .central)
        let cleanRoute = route(line: .victoria)

        let disruptions = [
            Disruption(
                line: .central,
                severity: .severeDelays,
                statusLabel: "Severe Delays",
                reason: "Severe delays on the Central line."
            )
        ]

        let disruptedScore = RouteScorer.score(disruptedRoute, preference: nil, disruptions: disruptions)
        let cleanScore = RouteScorer.score(cleanRoute, preference: nil, disruptions: disruptions)

        #expect(disruptedScore < cleanScore)
    }

    @Test func unmatchedDisruptionDoesNotAffectScore() {
        let unaffectedRoute = route(line: .victoria)

        let disruptions = [
            Disruption(
                line: .central,
                severity: .severeDelays,
                statusLabel: "Severe Delays",
                reason: "Severe delays on the Central line."
            )
        ]

        let scoreWithDisruption = RouteScorer.score(unaffectedRoute, preference: nil, disruptions: disruptions)
        let scoreWithoutDisruption = RouteScorer.score(unaffectedRoute, preference: nil, disruptions: [])

        #expect(scoreWithDisruption == scoreWithoutDisruption)
    }

    @Test func nationalRailDisruptionMatchesRouteViaOperatorAliasing() {
        let railRoute = route(line: .nationalRail)

        let disruptions = [
            Disruption(
                line: .southeastern,
                severity: .suspended,
                statusLabel: "Suspended",
                reason: "Southeastern services are suspended."
            )
        ]

        let disruptedScore = RouteScorer.score(railRoute, preference: nil, disruptions: disruptions)
        let cleanScore = RouteScorer.score(railRoute, preference: nil, disruptions: [])

        #expect(disruptedScore < cleanScore)
    }

    @Test func rankedRoutesPrefersRouteWithoutMatchingDisruption() {
        let disruptedRoute = route(line: .central, totalMinutes: 20)
        let cleanRoute = route(line: .victoria, totalMinutes: 20)

        let disruptions = [
            Disruption(
                line: .central,
                severity: .severeDelays,
                statusLabel: "Severe Delays",
                reason: "Severe delays on the Central line."
            )
        ]

        let ranked = RouteScorer.rankedRoutes(
            [disruptedRoute, cleanRoute],
            preference: nil,
            disruptions: disruptions
        )

        #expect(ranked.first?.id == cleanRoute.id)
    }
}
