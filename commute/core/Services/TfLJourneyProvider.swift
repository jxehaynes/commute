import CoreLocation
import Foundation

struct TfLJourneyProvider: RouteProviding {
    func fetchRoutes(from: SavedLocation, to: SavedLocation, query: RouteQuery) async throws -> [Route] {
        let origin = from.tflRoutingValue
        let destination = to.tflRoutingValue
        print("TfL routing from: \(from.address) @ \(origin)")
        print("TfL routing to: \(to.address) @ \(destination)")
        let strategies = TfLJourneyStrategy.strategies(for: query)

        let responses = await withTaskGroup(of: TfLJourneyResponse?.self) { group in
            for strategy in strategies {
                group.addTask {
                    try? await fetchJourney(
                        from: origin,
                        to: destination,
                        strategy: strategy
                    )
                }
            }

            var collected: [TfLJourneyResponse] = []
            for await result in group {
                if let result {
                    collected.append(result)
                }
            }
            return collected
        }

        let pairs = responses.flatMap { response in
            response.journeys.compactMap { $0.routeWithStopSequences }
        }

        var stopSequences: [UUID: [Int: [String]]] = [:]
        for pair in pairs {
            stopSequences[pair.route.id] = pair.stopSequences
        }

        let deduped = pairs.map(\.route).deduplicatedBySignatureKeepingFastest()
        return RouteGrouping.grouped(deduped, stopSequences: stopSequences)
    }

    private func fetchJourney(from: String, to: String, strategy: TfLJourneyStrategy) async throws -> TfLJourneyResponse {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.tfl.gov.uk"
        components.path = "/Journey/JourneyResults/\(from)/to/\(to)"
        var queryItems = [
            URLQueryItem(name: "mode", value: strategy.modeString),
            URLQueryItem(name: "journeyPreference", value: strategy.preference.rawValue),
            URLQueryItem(name: "timeIs", value: strategy.timeMode.tflValue),
            URLQueryItem(name: "walkingSpeed", value: "fast"),
            URLQueryItem(name: "maxWalkingMinutes", value: "15")
        ]
        if let date = strategy.date {
            queryItems.append(URLQueryItem(name: "date", value: DateFormatter.tflQueryDate.string(from: date)))
            queryItems.append(URLQueryItem(name: "time", value: DateFormatter.tflQueryTime.string(from: date)))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw TfLProviderError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw TfLProviderError.badResponse
        }
        return try JSONDecoder.tfl.decode(TfLJourneyResponse.self, from: data)
    }
}

private struct TfLJourneyStrategy: Hashable {
    enum Preference: String, Hashable {
        case leastTime = "leasttime"
        case leastInterchange = "leastinterchange"
        case leastWalking = "leastwalking"
    }

    let date: Date?
    let timeMode: RouteQuery.TimeMode
    let preference: Preference
    let includesBus: Bool

    var modeString: String {
        var modes = "walking,tube,overground,dlr,elizabeth-line,national-rail"
        if includesBus {
            modes += ",bus"
        }
        return modes
    }

    static func strategies(for query: RouteQuery) -> [TfLJourneyStrategy] {
        if query.usesLightweightStrategies {
            return [
                TfLJourneyStrategy(
                    date: query.date,
                    timeMode: query.timeMode,
                    preference: .leastTime,
                    includesBus: true
                )
            ]
        }

        let baseDate = query.date
        let sweepDates = [
            baseDate?.addingTimeInterval(-10 * 60),
            baseDate,
            baseDate?.addingTimeInterval(10 * 60)
        ]

        var strategies: [TfLJourneyStrategy] = sweepDates.map {
            TfLJourneyStrategy(
                date: $0,
                timeMode: query.timeMode,
                preference: .leastTime,
                includesBus: true
            )
        }

        strategies += [
            TfLJourneyStrategy(date: baseDate, timeMode: query.timeMode, preference: .leastInterchange, includesBus: true),
            TfLJourneyStrategy(date: baseDate, timeMode: query.timeMode, preference: .leastWalking, includesBus: true),
            TfLJourneyStrategy(date: baseDate, timeMode: query.timeMode, preference: .leastTime, includesBus: false)
        ]

        return Array(Set(strategies))
    }
}

struct TfLDisruptionProvider: DisruptionProviding {
    func fetchDisruptions() async throws -> [Disruption] {
        let tflIDs = TfLLine.allCases.compactMap(\.tflIdentifier)

        async let nationalRailStatuses = fetchStatuses(path: "/Line/Mode/national-rail/Status")
        let tflStatuses: [TfLLineStatusResponse]
        if tflIDs.isEmpty {
            tflStatuses = []
        } else {
            tflStatuses = try await fetchStatuses(path: "/Line/\(tflIDs.joined(separator: ","))/Status")
        }

        let resolvedNationalRailStatuses = try await nationalRailStatuses.filter { status in
            TfLLine(tflIdentifier: status.id)?.isLondonAreaRailOperator ?? false
        }
        let combined = tflStatuses + resolvedNationalRailStatuses
        return combined.compactMap(\.disruption)
    }

    private func fetchStatuses(path: String) async throws -> [TfLLineStatusResponse] {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.tfl.gov.uk"
        components.path = path

        guard let url = components.url else { throw TfLProviderError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw TfLProviderError.badResponse
        }

        return try JSONDecoder().decode([TfLLineStatusResponse].self, from: data)
    }
}

private struct TfLJourneyResponse: Decodable {
    let journeys: [TfLJourney]
}

private struct TfLJourney: Decodable {
    let duration: Int
    let legs: [TfLLeg]

    var route: Route? {
        routeWithStopSequences?.route
    }

    /// Pairs the decoded route with the full ordered stop-point names for each transit leg,
    /// keyed by that leg's index in the resulting `Route.legs`, so callers can detect two
    /// routes that share the exact same stops but differ in which line serves them.
    var routeWithStopSequences: (route: Route, stopSequences: [Int: [String]])? {
        let pairs = legs.compactMap { leg -> (RouteLeg, [String])? in
            guard let routeLeg = leg.routeLeg else { return nil }
            return (routeLeg, leg.stopNames)
        }
        guard !pairs.isEmpty else { return nil }

        let routeLegs = pairs.map { $0.0 }
        let route = Route(
            summary: TfLJourney.summary(for: routeLegs),
            totalMinutes: duration,
            legs: routeLegs,
            status: .goodService
        )

        var stopSequences: [Int: [String]] = [:]
        for (index, pair) in pairs.enumerated() {
            guard case .transit = pair.0 else { continue }
            stopSequences[index] = pair.1
        }

        return (route, stopSequences)
    }

    private static func summary(for legs: [RouteLeg]) -> String {
        let lines = legs.compactMap { leg -> String? in
            guard case .transit(let line, _, _, _, _, _, let label) = leg else { return nil }
            return label ?? "\(line.displayName) line"
        }

        guard !lines.isEmpty else { return "Walk route" }
        return "Via \(lines.removingDuplicates().joined(separator: " + "))"
    }
}

private struct TfLLeg: Decodable {
    let duration: Int
    let mode: TfLMode
    let departureTime: Date?
    let instruction: TfLInstruction?
    let routeOptions: [TfLRouteOption]?
    let path: TfLPath?

    var routeLeg: RouteLeg? {
        if mode.id == "walking" || mode.id == "cycle" {
            return .walk(minutes: max(duration, 1), distanceMiles: Double(duration) / 20.0)
        }

        guard let from = stopNames.first,
              let to = stopNames.last,
              from != to else { return nil }

        let line = resolvedLine
        return .transit(
            line: line,
            from: from,
            to: to,
            departureTime: departureLabel,
            platform: nil,
            stops: max(stopNames.count - 1, 1),
            lineLabel: resolvedLineLabel(line: line)
        )
    }

    fileprivate var stopNames: [String] {
        path?.stopPoints?.compactMap { $0.name }.filter { !$0.isEmpty } ?? []
    }

    private var resolvedLine: TfLLine {
        guard let identifier = routeOptions?.first?.lineIdentifier,
              let line = TfLLine(tflIdentifier: identifier) else {
            return mode.defaultLine
        }
        return line
    }

    private func resolvedLineLabel(line: TfLLine) -> String? {
        if mode.id == "bus", let name = routeOptions?.first?.name {
            return "Bus \(name)"
        }
        if line == .nationalRail || line.isNationalRailOperator, let name = routeOptions?.first?.name {
            return name
        }
        return nil
    }

    private var departureLabel: String {
        guard let departureTime else { return "--:--" }
        return DateFormatter.tflTime.string(from: departureTime)
    }
}

private struct TfLMode: Decodable {
    let id: String
    let name: String?

    var defaultLine: TfLLine {
        switch id {
        case "dlr": .dlr
        case "elizabeth-line": .elizabethLine
        case "overground": .overground
        case "national-rail": .nationalRail
        case "bus": .bus
        default: .central
        }
    }
}

private struct TfLInstruction: Decodable {
    let summary: String?
}

private struct TfLRouteOption: Decodable {
    let name: String?
    let lineIdentifier: TfLLineIdentifier?

    private enum CodingKeys: String, CodingKey {
        case name
        case lineIdentifier
    }
}

private struct TfLLineIdentifier: Decodable {
    let id: String?

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(),
           let value = try? container.decode(String.self) {
            id = value
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
    }

    private enum CodingKeys: String, CodingKey {
        case id
    }
}

private struct TfLPath: Decodable {
    let stopPoints: [TfLStopPoint]?
}

private struct TfLStopPoint: Decodable {
    let name: String?
}

private struct TfLLineStatusResponse: Decodable {
    let id: String
    let lineStatuses: [TfLStatus]

    var disruption: Disruption? {
        guard let line = TfLLine(tflIdentifier: id) else { return nil }
        let activeStatuses = lineStatuses.filter {
            Route.LineStatus(tflStatusDescription: $0.statusSeverityDescription) != .goodService
        }
        guard let worst = activeStatuses.max(by: {
            Route.LineStatus(tflStatusDescription: $0.statusSeverityDescription).disruptionPriority
                < Route.LineStatus(tflStatusDescription: $1.statusSeverityDescription).disruptionPriority
        }) else { return nil }

        let severity = Route.LineStatus(tflStatusDescription: worst.statusSeverityDescription)
        let reason = worst.reason?.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = worst.statusSeverityDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        let resolvedReason = Self.resolvedReason(
            reason: reason,
            fallback: fallback,
            disruptionDescription: worst.disruptionDescription
        )

        return Disruption(
            line: line,
            severity: severity,
            statusLabel: fallback,
            reason: resolvedReason
        )
    }
}

private struct TfLStatus: Decodable {
    let statusSeverityDescription: String
    let reason: String?
    let disruption: TfLStatusDisruption?
}

private struct TfLStatusDisruption: Decodable {
    let description: String?
}

private extension TfLLineStatusResponse {
    static func resolvedReason(
        reason: String?,
        fallback: String,
        disruptionDescription: String?
    ) -> String {
        let trimmedReason = reason?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedReason.isEmpty, !trimmedReason.lowercased().hasPrefix("http") {
            return trimmedReason
        }

        let trimmedDescription = disruptionDescription?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmedDescription.isEmpty, !trimmedDescription.lowercased().hasPrefix("http") {
            return trimmedDescription
        }

        return fallback
    }
}

private extension TfLStatus {
    var disruptionDescription: String? {
        disruption?.description
    }
}

private enum TfLProviderError: Error {
    case invalidURL
    case badResponse
}

private extension CLLocationCoordinate2D {
    var tflCoordinate: String {
        "\(latitude),\(longitude)"
    }
}

private extension SavedLocation {
    var tflRoutingValue: String {
        if let routingCoordinate {
            return routingCoordinate.tflCoordinate
        }
        return coordinate.tflCoordinate
    }
}

private extension Array where Element == Route {
    func deduplicatedBySignatureKeepingFastest() -> [Route] {
        var bestBySignature: [String: Route] = [:]

        for route in self {
            if let existing = bestBySignature[route.signature] {
                if route.totalMinutes < existing.totalMinutes {
                    bestBySignature[route.signature] = route
                }
            } else {
                bestBySignature[route.signature] = route
            }
        }

        return Array(bestBySignature.values)
    }
}

private extension JSONDecoder {
    static var tfl: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            if let date = DateFormatter.tflDateTime.date(from: value) {
                return date
            }

            if let date = ISO8601DateFormatter().date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid TfL date: \(value)"
            )
        }
        return decoder
    }
}

private extension DateFormatter {
    static let tflQueryDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    static let tflQueryTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB_POSIX")
        formatter.dateFormat = "HHmm"
        return formatter
    }()

    static let tflDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    static let tflTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

private extension RouteQuery.TimeMode {
    var tflValue: String {
        switch self {
        case .departing: "Departing"
        case .arriving: "Arriving"
        }
    }
}

private extension TfLLine {
    init?(tflIdentifier: TfLLineIdentifier) {
        guard let id = tflIdentifier.id else { return nil }
        self.init(tflIdentifier: id)
    }

    init?(tflIdentifier: String) {
        switch tflIdentifier {
        case "bakerloo": self = .bakerloo
        case "central": self = .central
        case "circle": self = .circle
        case "district": self = .district
        case "dlr": self = .dlr
        case "elizabeth-line": self = .elizabethLine
        case "hammersmith-city": self = .hammersmithAndCity
        case "jubilee": self = .jubilee
        case "metropolitan": self = .metropolitan
        case "northern": self = .northern
        case "london-overground", "overground": self = .overground
        case "piccadilly": self = .piccadilly
        case "victoria": self = .victoria
        case "waterloo-city": self = .waterlooAndCity
        case "liberty": self = .liberty
        case "lioness": self = .lioness
        case "mildmay": self = .mildmay
        case "suffragette": self = .suffragette
        case "weaver": self = .weaver
        case "windrush": self = .windrush
        case "thameslink": self = .thameslink
        case "southeastern": self = .southeastern
        case "southern": self = .southern
        case "south-western-railway": self = .southWesternRailway
        case "great-western-railway": self = .greatWesternRailway
        case "chiltern-railways": self = .chilternRailways
        case "great-northern": self = .greatNorthern
        case "greater-anglia": self = .greaterAnglia
        case "c2c": self = .c2c
        case "gatwick-express": self = .gatwickExpress
        case "heathrow-express": self = .heathrowExpress
        case "east-midlands-railway": self = .eastMidlandsRailway
        case "london-north-eastern-railway": self = .londonNorthEasternRailway
        case "crosscountry": self = .crosscountry
        case "avanti-west-coast": self = .avantiWestCoast
        case "west-midlands-trains": self = .westMidlandsTrains
        case "grand-central": self = .grandCentral
        case "hull-trains": self = .hullTrains
        case "lumo": self = .lumo
        case "transpennine-express": self = .transpennineExpress
        case "transport-for-wales": self = .transportForWales
        case "northern-rail": self = .northernRail
        case "merseyrail": self = .merseyrail
        case "scotrail": self = .scotrail
        case "island-line": self = .islandLine
        default: return nil
        }
    }

    var tflIdentifier: String? {
        switch self {
        case .bakerloo: "bakerloo"
        case .central: "central"
        case .circle: "circle"
        case .district: "district"
        case .dlr: "dlr"
        case .elizabethLine: "elizabeth-line"
        case .hammersmithAndCity: "hammersmith-city"
        case .jubilee: "jubilee"
        case .metropolitan: "metropolitan"
        case .northern: "northern"
        case .overground: "london-overground"
        case .piccadilly: "piccadilly"
        case .victoria: "victoria"
        case .waterlooAndCity: "waterloo-city"
        case .liberty: "liberty"
        case .lioness: "lioness"
        case .mildmay: "mildmay"
        case .suffragette: "suffragette"
        case .weaver: "weaver"
        case .windrush: "windrush"
        default: nil
        }
    }
}

private extension Route.LineStatus {
    init(tflStatusDescription: String) {
        let normalized = tflStatusDescription.lowercased()
        if normalized.contains("good") {
            self = .goodService
        } else if normalized.contains("minor") {
            self = .minorDelays
        } else if normalized.contains("suspend") {
            self = .suspended
        } else if normalized.contains("special") {
            self = .minorDelays
        } else if normalized.contains("severe") || normalized.contains("part closure") || normalized.contains("planned closure") {
            self = .severeDelays
        } else {
            self = .unknown
        }
    }
}

private extension Array where Element == String {
    func removingDuplicates() -> [String] {
        var seen: Set<String> = []
        return filter { seen.insert($0).inserted }
    }
}
