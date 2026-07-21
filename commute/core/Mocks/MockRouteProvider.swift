import Foundation

struct MockRouteProvider: RouteProviding {
    func fetchRoutes(from: SavedLocation, to: SavedLocation, query: RouteQuery) async throws -> [Route] {
        try await Task.sleep(for: .seconds(0.8))
        return Route.mockRoutes(from: from, to: to)
    }
}
