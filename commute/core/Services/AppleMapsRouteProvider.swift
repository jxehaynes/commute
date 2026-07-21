import Foundation
import MapKit

struct AppleMapsRouteProvider: RouteProviding {
    func fetchRoutes(from: SavedLocation, to: SavedLocation, query: RouteQuery) async throws -> [Route] {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from.routingCoordinate ?? from.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to.routingCoordinate ?? to.coordinate))
        request.transportType = .transit
        request.requestsAlternateRoutes = true

        if let date = query.date {
            switch query.timeMode {
            case .departing:
                request.departureDate = date
            case .arriving:
                request.arrivalDate = date
            }
        }

        let response = try await MKDirections(request: request).calculate()
        return response.routes
            .map { route in
            Route(
                summary: route.displaySummary,
                totalMinutes: max(Int(route.expectedTravelTime / 60), 1),
                legs: route.routeLegs(from: from, to: to),
                status: .goodService
            )
        }
    }
}

private extension MKRoute {
    var displaySummary: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Apple Maps transit" }
        return "Via \(trimmed)"
    }

    func routeLegs(from: SavedLocation, to: SavedLocation) -> [RouteLeg] {
        let meaningfulSteps = steps.filter { step in
            !step.instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || step.distance > 0
        }

        let legs = meaningfulSteps.compactMap { step -> RouteLeg? in
            if step.transportType == .walking {
                let miles = step.distance / 1609.344
                let minutes = max(Int((step.distance / 80).rounded()), 1)
                return .walk(minutes: minutes, distanceMiles: miles)
            }

            if step.transportType.contains(.transit) {
                let label = step.transitLabel
                return .transit(
                    line: step.resolvedLine,
                    from: from.displayName,
                    to: to.displayName,
                    departureTime: "--:--",
                    platform: nil,
                    stops: 1,
                    lineLabel: label.isEmpty ? "Apple Maps" : label
                )
            }

            return nil
        }

        if legs.isEmpty {
            return [
                .transit(
                    line: .nationalRail,
                    from: from.displayName,
                    to: to.displayName,
                    departureTime: "--:--",
                    platform: nil,
                    stops: max(steps.count, 1),
                    lineLabel: "Apple Maps"
                )
            ]
        }

        return legs
    }
}

private extension MKRoute.Step {
    var transitLabel: String {
        let instruction = instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !instruction.isEmpty else { return "Apple Maps" }

        if let busNumber = instruction.busNumber {
            return "Bus \(busNumber)"
        }

        if instruction.localizedCaseInsensitiveContains("Elizabeth") {
            return "Elizabeth line"
        }

        return instruction
    }

    var resolvedLine: TfLLine {
        let instruction = instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        if instruction.localizedCaseInsensitiveContains("bus") {
            return .bus
        }
        if instruction.localizedCaseInsensitiveContains("Elizabeth") {
            return .elizabethLine
        }
        if instruction.localizedCaseInsensitiveContains("Overground") {
            return .overground
        }
        if instruction.localizedCaseInsensitiveContains("DLR") {
            return .dlr
        }
        return .nationalRail
    }
}

private extension String {
    var busNumber: String? {
        let pattern = #"(?i)\bbus\s+([A-Z]?\d+[A-Z]?|[A-Z]{1,3}\d?)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)),
              let range = Range(match.range(at: 1), in: self) else {
            return nil
        }
        return String(self[range])
    }
}

struct BestAvailableRouteProvider: RouteProviding {
    private let primaryProvider: any RouteProviding
    private let fallbackProvider: any RouteProviding

    init(
        primaryProvider: any RouteProviding = TfLJourneyProvider(),
        fallbackProvider: any RouteProviding = AppleMapsRouteProvider()
    ) {
        self.primaryProvider = primaryProvider
        self.fallbackProvider = fallbackProvider
    }

    func fetchRoutes(from: SavedLocation, to: SavedLocation, query: RouteQuery) async throws -> [Route] {
        if let primaryRoutes = try? await primaryProvider.fetchRoutes(from: from, to: to, query: query),
           !primaryRoutes.isEmpty {
            return primaryRoutes
        }

        return try await fallbackProvider.fetchRoutes(from: from, to: to, query: query)
    }
}
