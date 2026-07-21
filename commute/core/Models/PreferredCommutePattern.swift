import Foundation

enum CommuteLegKind: String, Codable, Hashable {
    case walk
    case bus
    case tube
    case elizabethLine
    case overground
    case dlr
    case nationalRail
    case transit

    var displayLabel: String {
        switch self {
        case .walk: "walk"
        case .bus: "bus"
        case .tube: "tube"
        case .elizabethLine: "Elizabeth line"
        case .overground: "Overground"
        case .dlr: "DLR"
        case .nationalRail: "National Rail"
        case .transit: "transit"
        }
    }
}

struct PreferredCommutePattern: Codable, Equatable {
    var legKinds: [CommuteLegKind]
    var lineIDs: [String]
    var lineLabels: [String]
    var walkingMinutes: [Int]
    var totalMinutes: Int
    var avoidsBus: Bool

    init(route: Route) {
        legKinds = route.legs.map(\.commuteLegKind)
        lineIDs = route.legs.compactMap(\.commuteLineID).removingDuplicates()
        lineLabels = route.legs.compactMap(\.commuteLineLabel).removingDuplicates()
        walkingMinutes = route.legs.compactMap(\.walkMinutes)
        totalMinutes = route.totalMinutes
        avoidsBus = !legKinds.contains(.bus)
    }
}

enum RouteScorer {
    static func rankedRoutes(_ routes: [Route], preference: PreferredCommutePattern?) -> [Route] {
        routes.sorted { lhs, rhs in
            score(lhs, preference: preference) > score(rhs, preference: preference)
        }
    }

    static func preferredRoute(from routes: [Route], preference: PreferredCommutePattern?) -> Route? {
        rankedRoutes(routes, preference: preference).first
    }

    static func score(_ route: Route, preference: PreferredCommutePattern?) -> Int {
        guard let preference else {
            return durationScore(route)
        }

        var score = durationScore(route)
        let kinds = route.legs.map(\.commuteLegKind)
        let routeLineIDs = route.legs.compactMap(\.commuteLineID)
        let routeLineLabels = route.legs.compactMap(\.commuteLineLabel)

        score += sequenceScore(candidate: kinds, preferred: preference.legKinds)
        score += overlapScore(candidate: routeLineIDs, preferred: preference.lineIDs, weight: 120)
        score += overlapScore(candidate: routeLineLabels, preferred: preference.lineLabels, weight: 90)

        if preference.avoidsBus, kinds.contains(.bus) {
            score -= 400
        }

        if hasDirectRailBonus(kinds) {
            score += 200
        }

        score -= max(kinds.filter { $0.isTransit }.count - 1, 0) * 60

        score -= abs(route.totalMinutes - preference.totalMinutes) * 2
        score -= abs(route.legs.count - preference.legKinds.count) * 20
        score -= walkingPenalty(route.legs.compactMap(\.walkMinutes), preferred: preference.walkingMinutes)

        if route.status.isOnTime {
            score += 40
        } else {
            score -= 80
        }

        return score
    }

    private static func durationScore(_ route: Route) -> Int {
        max(0, 1_000 - route.totalMinutes * 6)
    }

    private static func sequenceScore(candidate: [CommuteLegKind], preferred: [CommuteLegKind]) -> Int {
        guard !candidate.isEmpty, !preferred.isEmpty else { return 0 }
        var score = 0
        for index in 0..<min(candidate.count, preferred.count) {
            if candidate[index] == preferred[index] {
                score += 45
            }
        }
        if candidate == preferred {
            score += 160
        }
        return score
    }

    private static func overlapScore<T: Hashable>(candidate: [T], preferred: [T], weight: Int) -> Int {
        let candidateSet = Set(candidate)
        return preferred.reduce(0) { score, value in
            score + (candidateSet.contains(value) ? weight : 0)
        }
    }

    private static func walkingPenalty(_ candidate: [Int], preferred: [Int]) -> Int {
        guard !candidate.isEmpty, !preferred.isEmpty else { return 0 }
        var penalty = abs(candidate.reduce(0, +) - preferred.reduce(0, +)) * 2
        penalty += abs(candidate.count - preferred.count) * 10
        return penalty
    }

    private static func hasDirectRailBonus(_ kinds: [CommuteLegKind]) -> Bool {
        let transitKinds = kinds.filter(\.isTransit)
        guard transitKinds.count == 1 else { return false }
        switch transitKinds[0] {
        case .elizabethLine, .overground, .tube:
            return true
        case .walk, .bus, .dlr, .nationalRail, .transit:
            return false
        }
    }
}

private extension CommuteLegKind {
    var isTransit: Bool {
        self != .walk
    }
}

extension RouteLeg {
    var commuteLegKind: CommuteLegKind {
        switch self {
        case .walk:
            return .walk
        case .transit(let line, _, _, _, _, _, let lineLabel):
            if line == .bus || lineLabel?.localizedCaseInsensitiveContains("bus") == true {
                return .bus
            }
            switch line {
            case .elizabethLine:
                return .elizabethLine
            case .overground:
                return .overground
            case .dlr:
                return .dlr
            case .nationalRail:
                return .nationalRail
            default:
                return .tube
            }
        }
    }

    var commuteLineID: String? {
        switch self {
        case .walk:
            return nil
        case .transit(let line, _, _, _, _, _, let lineLabel):
            if let busNumber = lineLabel?.commuteBusNumber {
                return "bus-\(busNumber.lowercased())"
            }
            return line.rawValue
        }
    }

    var commuteLineLabel: String? {
        switch self {
        case .walk:
            return nil
        case .transit(let line, _, _, _, _, _, let lineLabel):
            if let lineLabel {
                return lineLabel.normalizedCommuteLabel
            }
            return line.displayName.normalizedCommuteLabel
        }
    }

    var walkMinutes: Int? {
        switch self {
        case .walk(let minutes, _):
            return minutes
        case .transit:
            return nil
        }
    }
}

private extension String {
    var normalizedCommuteLabel: String {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var commuteBusNumber: String? {
        let pattern = #"(?i)\bbus\s+([A-Z]?\d+[A-Z]?|[A-Z]{1,3}\d?)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)),
              let range = Range(match.range(at: 1), in: self) else {
            return nil
        }
        return String(self[range])
    }
}

private extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen: Set<Element> = []
        return filter { seen.insert($0).inserted }
    }
}
