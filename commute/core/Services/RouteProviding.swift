import Foundation

struct RouteQuery: Sendable {
    enum TimeMode: Sendable {
        case departing
        case arriving
    }

    var date: Date?
    var timeMode: TimeMode
    /// Fewer TfL journey searches — used for home-screen preloads to avoid rate limits.
    var usesLightweightStrategies: Bool

    static let departingNow = RouteQuery(date: nil, timeMode: .departing, usesLightweightStrategies: false)
    static let departingNowLightweight = RouteQuery(date: nil, timeMode: .departing, usesLightweightStrategies: true)
}

protocol RouteProviding: Sendable {
    func fetchRoutes(from: SavedLocation, to: SavedLocation, query: RouteQuery) async throws -> [Route]
}

extension RouteProviding {
    func fetchRoutes(from: SavedLocation, to: SavedLocation) async throws -> [Route] {
        try await fetchRoutes(from: from, to: to, query: .departingNow)
    }
}
