import Foundation
import Testing
@testable import commute

struct RouteGroupingTests {
    private func time(_ hour: Int, _ minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return Calendar.current.date(from: components)!
    }

    @Test func mergesRoutesSharingIdenticalStopSequenceButDifferentLines() {
        let sharedStops = ["Bank", "Monument", "Tower Hill"]

        let route225 = Route(
            summary: "Via Bus 225",
            totalMinutes: 20,
            legs: [
                .walk(minutes: 5, distanceMiles: 0.3),
                .transit(
                    line: .nationalRail,
                    from: "Bank",
                    to: "Tower Hill",
                    departureTime: time(8, 55),
                    platform: nil,
                    stops: 2,
                    lineLabel: "Bus 225"
                ),
                .walk(minutes: 3, distanceMiles: 0.2)
            ],
            status: .goodService
        )

        let route141 = Route(
            summary: "Via Bus 141",
            totalMinutes: 22,
            legs: [
                .walk(minutes: 5, distanceMiles: 0.3),
                .transit(
                    line: .nationalRail,
                    from: "Bank",
                    to: "Tower Hill",
                    departureTime: time(8, 48),
                    platform: nil,
                    stops: 2,
                    lineLabel: "Bus 141"
                ),
                .walk(minutes: 3, distanceMiles: 0.2)
            ],
            status: .minorDelays
        )

        let stopSequences: [UUID: [Int: [String]]] = [
            route225.id: [1: sharedStops],
            route141.id: [1: sharedStops]
        ]

        let grouped = RouteGrouping.grouped([route225, route141], stopSequences: stopSequences)

        #expect(grouped.count == 1)
        let merged = try! #require(grouped.first)
        let alternatives = try! #require(merged.groupedAlternatives[1])
        #expect(alternatives.count == 2)
        #expect(alternatives.map { $0.lineLabel } == ["Bus 141", "Bus 225"])

        guard case .transit(_, _, _, let departureTime, _, _, let lineLabel) = merged.legs[1] else {
            Issue.record("Expected merged leg to remain a transit leg")
            return
        }
        #expect(departureTime == time(8, 48))
        #expect(lineLabel == "Bus 141")
    }

    @Test func doesNotMergeRoutesWithDifferingIntermediateStops() {
        let route225 = Route(
            summary: "Via Bus 225",
            totalMinutes: 20,
            legs: [
                .transit(
                    line: .nationalRail,
                    from: "Bank",
                    to: "Tower Hill",
                    departureTime: time(8, 55),
                    platform: nil,
                    stops: 2,
                    lineLabel: "Bus 225"
                )
            ],
            status: .goodService
        )

        let routeDetour = Route(
            summary: "Via Bus 42",
            totalMinutes: 26,
            legs: [
                .transit(
                    line: .nationalRail,
                    from: "Bank",
                    to: "Tower Hill",
                    departureTime: time(8, 50),
                    platform: nil,
                    stops: 4,
                    lineLabel: "Bus 42"
                )
            ],
            status: .goodService
        )

        let stopSequences: [UUID: [Int: [String]]] = [
            route225.id: [0: ["Bank", "Monument", "Tower Hill"]],
            routeDetour.id: [0: ["Bank", "Aldgate", "Fenchurch Street", "Tower Hill"]]
        ]

        let grouped = RouteGrouping.grouped([route225, routeDetour], stopSequences: stopSequences)

        #expect(grouped.count == 2)
        #expect(grouped.allSatisfy { $0.groupedAlternatives.isEmpty })
    }

    @Test func collapsesDuplicateFixedLineRoutesToASingleEntryWithNoAlternatives() {
        let sharedStops = ["Dalston Junction", "Hoxton", "Shoreditch High Street"]

        func mildmayRoute(totalMinutes: Int, walkMinutes: Int, departureTime: Date, lineLabel: String?) -> Route {
            Route(
                summary: "Via the Mildmay line",
                totalMinutes: totalMinutes,
                legs: [
                    .walk(minutes: walkMinutes, distanceMiles: 0.3),
                    .transit(
                        line: .mildmay,
                        from: "Dalston Junction",
                        to: "Shoreditch High Street",
                        departureTime: departureTime,
                        platform: nil,
                        stops: 2,
                        lineLabel: lineLabel
                    ),
                    .walk(minutes: 4, distanceMiles: 0.2)
                ],
                status: .goodService
            )
        }

        // Two journeys for the exact same Mildmay ride, returned by different TfL search
        // strategies with slightly different walking-time estimates and label formatting.
        let leastTime = mildmayRoute(totalMinutes: 20, walkMinutes: 5, departureTime: time(8, 50), lineLabel: nil)
        let leastWalking = mildmayRoute(totalMinutes: 23, walkMinutes: 8, departureTime: time(8, 44), lineLabel: "Mildmay line")

        let stopSequences: [UUID: [Int: [String]]] = [
            leastTime.id: [1: sharedStops],
            leastWalking.id: [1: sharedStops]
        ]

        let grouped = RouteGrouping.grouped([leastTime, leastWalking], stopSequences: stopSequences)

        #expect(grouped.count == 1)
        let merged = try! #require(grouped.first)
        #expect(merged.groupedAlternatives.isEmpty)

        guard case .transit(_, _, _, let departureTime, _, _, _) = merged.legs[1] else {
            Issue.record("Expected merged leg to remain a transit leg")
            return
        }
        #expect(departureTime == time(8, 44))
    }

    @Test func collectsRealUpcomingDeparturesForTheSameFixedLineService() {
        let sharedStops = ["Dalston Junction", "Hoxton", "Shoreditch High Street"]

        func mildmayRoute(departureTime: Date) -> Route {
            Route(
                summary: "Via the Mildmay line",
                totalMinutes: 20,
                legs: [
                    .walk(minutes: 5, distanceMiles: 0.3),
                    .transit(
                        line: .mildmay,
                        from: "Dalston Junction",
                        to: "Shoreditch High Street",
                        departureTime: departureTime,
                        platform: nil,
                        stops: 2,
                        lineLabel: "Mildmay line"
                    ),
                    .walk(minutes: 4, distanceMiles: 0.2)
                ],
                status: .goodService
            )
        }

        // Three time-sweep instances of the exact same Mildmay journey, each finding a
        // different real upcoming departure of the same service.
        let routes = [
            mildmayRoute(departureTime: time(8, 50)),
            mildmayRoute(departureTime: time(8, 40)),
            mildmayRoute(departureTime: time(9, 0)),
            // A duplicate of the 08:40 instance — should not appear twice.
            mildmayRoute(departureTime: time(8, 40))
        ]

        var stopSequences: [UUID: [Int: [String]]] = [:]
        for route in routes {
            stopSequences[route.id] = [1: sharedStops]
        }

        let grouped = RouteGrouping.grouped(routes, stopSequences: stopSequences)

        #expect(grouped.count == 1)
        let merged = try! #require(grouped.first)
        #expect(merged.upcomingDepartures[1] == [time(8, 40), time(8, 50), time(9, 0)])
    }

    @Test func capsBusAlternativesAtThreeAndDedupesRepeatedBusNumbers() {
        let sharedStops = ["Bank", "Monument", "Tower Hill"]

        func busRoute(number: String, departureTime: Date, totalMinutes: Int) -> Route {
            Route(
                summary: "Via Bus \(number)",
                totalMinutes: totalMinutes,
                legs: [
                    .transit(
                        line: .nationalRail,
                        from: "Bank",
                        to: "Tower Hill",
                        departureTime: departureTime,
                        platform: nil,
                        stops: 2,
                        lineLabel: "Bus \(number)"
                    )
                ],
                status: .goodService
            )
        }

        let routes = [
            busRoute(number: "225", departureTime: time(8, 55), totalMinutes: 20),
            busRoute(number: "141", departureTime: time(8, 48), totalMinutes: 22),
            busRoute(number: "42", departureTime: time(8, 50), totalMinutes: 21),
            busRoute(number: "15", departureTime: time(8, 52), totalMinutes: 21),
            // A later, slower duplicate of the 225 — should not create a second "225" entry.
            busRoute(number: "225", departureTime: time(9, 10), totalMinutes: 25)
        ]

        var stopSequences: [UUID: [Int: [String]]] = [:]
        for route in routes {
            stopSequences[route.id] = [0: sharedStops]
        }

        let grouped = RouteGrouping.grouped(routes, stopSequences: stopSequences)

        #expect(grouped.count == 1)
        let merged = try! #require(grouped.first)
        let alternatives = try! #require(merged.groupedAlternatives[0])
        #expect(alternatives.count == 3)
        #expect(alternatives.map { $0.lineLabel } == ["Bus 141", "Bus 42", "Bus 15"])
    }

    @Test func passesThroughUngroupedSingleRouteUnchanged() {
        let route = Route(
            summary: "Via the Central line",
            totalMinutes: 18,
            legs: [
                .transit(
                    line: .central,
                    from: "Holborn",
                    to: "Notting Hill Gate",
                    departureTime: time(8, 51),
                    platform: nil,
                    stops: 5,
                    lineLabel: nil
                )
            ],
            status: .goodService
        )

        let grouped = RouteGrouping.grouped([route], stopSequences: [:])

        #expect(grouped.count == 1)
        #expect(grouped.first?.groupedAlternatives.isEmpty == true)
    }
}
