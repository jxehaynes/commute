import Foundation

/// Collapses routes that take the exact same physical path — same stations, same stops in the
/// same order — into a single option.
///
/// Two flavours:
///  - Fixed-line legs (tube, rail, DLR, Overground, Elizabeth line) always collapse to exactly
///    one entry: these are the same service, so any duplicates from overlapping TfL search
///    strategies are just noise, not alternatives worth surfacing.
///  - Bus legs can legitimately be served by more than one route number over the same stops, so
///    those collapse into a single card that lists up to `maxBusAlternatives` distinct buses,
///    via `Route.groupedAlternatives`.
///
/// Walk legs are matched on their presence only (not exact minutes/distance) so that minor
/// walking-time jitter between TfL search strategies (leastTime vs leastWalking, etc.) doesn't
/// prevent two otherwise-identical journeys from collapsing together.
enum RouteGrouping {
    static let maxBusAlternatives = 3

    private struct StructuralKey: Hashable {
        enum LegKey: Hashable {
            case walk
            case bus(from: String, to: String, stops: [String])
            case fixedLine(line: TfLLine, from: String, to: String, stops: [String])
        }
        let legs: [LegKey]
    }

    static func grouped(_ routes: [Route], stopSequences: [UUID: [Int: [String]]]) -> [Route] {
        var buckets: [StructuralKey: [Route]] = [:]
        for route in routes {
            buckets[structuralKey(for: route, stopSequences: stopSequences), default: []].append(route)
        }
        return buckets.values.map(merge)
    }

    private static func structuralKey(for route: Route, stopSequences: [UUID: [Int: [String]]]) -> StructuralKey {
        let sequences = stopSequences[route.id] ?? [:]
        let legKeys = route.legs.enumerated().map { index, leg -> StructuralKey.LegKey in
            switch leg {
            case .walk:
                return .walk
            case .transit(let line, let from, let to, _, _, _, let lineLabel):
                let stops = sequences[index] ?? [from, to]
                if isBus(lineLabel: lineLabel) {
                    return .bus(from: from, to: to, stops: stops)
                }
                return .fixedLine(line: line, from: from, to: to, stops: stops)
            }
        }
        return StructuralKey(legs: legKeys)
    }

    private static func isBus(lineLabel: String?) -> Bool {
        lineLabel?.localizedCaseInsensitiveContains("bus") ?? false
    }

    static let maxUpcomingDepartures = 3

    private static func merge(_ group: [Route]) -> Route {
        precondition(!group.isEmpty, "RouteGrouping.merge called with an empty group")
        guard group.count > 1, let fastest = group.min(by: { $0.totalMinutes < $1.totalMinutes }) else {
            return group[0]
        }

        var mergedLegs = fastest.legs
        var alternatives: [Int: [TransitLineOption]] = [:]
        var upcomingDepartures: [Int: [Date]] = [:]

        for index in fastest.legs.indices {
            guard case .transit(_, let from, let to, _, _, let stops, let fastestLabel) = fastest.legs[index] else { continue }

            let options = distinctOptions(forLegIndex: index, in: group)
            guard let soonest = options.first else { continue }

            if isBus(lineLabel: fastestLabel), options.count > 1 {
                alternatives[index] = Array(options.prefix(maxBusAlternatives))
            }

            let identity = soonest.lineLabel ?? soonest.line.rawValue
            let departures = realDepartureTimes(forLegIndex: index, identity: identity, in: group)
            if !departures.isEmpty {
                upcomingDepartures[index] = departures
            }

            mergedLegs[index] = .transit(
                line: soonest.line,
                from: from,
                to: to,
                departureTime: soonest.departureTime,
                platform: soonest.platform,
                stops: stops,
                lineLabel: soonest.lineLabel
            )
        }

        return Route(
            id: fastest.id,
            summary: fastest.summary,
            totalMinutes: fastest.totalMinutes,
            legs: mergedLegs,
            status: fastest.status,
            groupedAlternatives: alternatives,
            upcomingDepartures: upcomingDepartures
        )
    }

    /// Real, distinct departure times for the same line/service at this leg index across every
    /// time-sweep instance in the group — soonest first, capped at `maxUpcomingDepartures`.
    private static func realDepartureTimes(forLegIndex index: Int, identity: String, in group: [Route]) -> [Date] {
        var seen: Set<Date> = []
        var times: [Date] = []
        for route in group where route.legs.indices.contains(index) {
            guard case .transit(let line, _, _, let departureTime?, _, _, let lineLabel) = route.legs[index],
                  (lineLabel ?? line.rawValue) == identity else { continue }
            if seen.insert(departureTime).inserted {
                times.append(departureTime)
            }
        }
        return Array(times.sorted().prefix(maxUpcomingDepartures))
    }

    /// One option per distinct line/bus-number at this leg index, keeping only the soonest
    /// departure for each, sorted soonest-first. A missing departure time (no real schedule)
    /// always sorts last.
    private static func distinctOptions(forLegIndex index: Int, in group: [Route]) -> [TransitLineOption] {
        var soonestByIdentity: [String: TransitLineOption] = [:]
        for route in group where route.legs.indices.contains(index) {
            guard case .transit(let line, _, _, let departureTime, let platform, _, let lineLabel) = route.legs[index] else { continue }
            let option = TransitLineOption(line: line, lineLabel: lineLabel, departureTime: departureTime, platform: platform)
            let identity = lineLabel ?? line.rawValue
            if let existing = soonestByIdentity[identity], isSoonerOrEqual(existing.departureTime, option.departureTime) {
                continue
            }
            soonestByIdentity[identity] = option
        }
        return soonestByIdentity.values.sorted { isSoonerOrEqual($0.departureTime, $1.departureTime) }
    }

    private static func isSoonerOrEqual(_ lhs: Date?, _ rhs: Date?) -> Bool {
        switch (lhs, rhs) {
        case (let lhs?, let rhs?): lhs <= rhs
        case (nil, nil): true
        case (nil, _): false
        case (_, nil): true
        }
    }
}
