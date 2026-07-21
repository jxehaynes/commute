import Combine
import CoreLocation
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var routes: [Route] = []
    @Published var isLoading = false
    @Published var disruptions: [Disruption] = []
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?
    @Published var selectedDestinationID: UUID?
    @Published var journeyIntent: JourneyIntent?
    @Published private(set) var preloadComplete = false

    private struct RouteCacheEntry {
        let fromID: UUID
        let toID: UUID
        let routes: [Route]
        let fetchedAt: Date
    }

    private let routeProvider: any RouteProviding
    private let disruptionProvider: any DisruptionProviding
    private var preloadTask: Task<Void, Never>?
    private var activePreloadToken: UUID?
    private var routeCache: RouteCacheEntry?
    private let routeCacheTTL: TimeInterval = 5 * 60

    init(
        routeProvider: (any RouteProviding)? = nil,
        disruptionProvider: (any DisruptionProviding)? = nil
    ) {
        self.routeProvider = routeProvider ?? BestAvailableRouteProvider()
        self.disruptionProvider = disruptionProvider ?? TfLDisruptionProvider()
    }

    func refreshDisruptions() async {
        do {
            disruptions = try await disruptionProvider.fetchDisruptions()
            lastUpdated = Date()
        } catch {
            // Keep any previously loaded disruptions; the status line falls back gracefully.
        }
    }

    func refreshIntent(
        profile: UserProfile,
        userLocation: CLLocation?,
        now: Date = .now
    ) {
        let presence = PlacePresenceResolver.resolve(
            userLocation: userLocation,
            savedPlaces: profile.locations
        )
        journeyIntent = JourneyIntentResolver.resolve(
            profile: profile,
            presence: presence,
            currentLocation: userLocation,
            now: now
        )
        resetDestinationSelectionIfNeeded(for: profile, now: now)
    }

    func loadRoutes(from: SavedLocation, to: SavedLocation) async {
        await performRouteLoad(from: from, to: to, token: nil)
    }

    func preloadRoutes(from: SavedLocation, to: SavedLocation) {
        if let cached = cachedRoutes(from: from, to: to) {
            routes = cached
            preloadComplete = true
            errorMessage = nil
            return
        }

        let token = UUID()
        activePreloadToken = token
        preloadTask?.cancel()
        preloadComplete = false
        errorMessage = nil

        preloadTask = Task {
            await performRouteLoad(from: from, to: to, token: token)
        }
    }

    func cancelPreload() {
        preloadTask?.cancel()
        preloadTask = nil
        activePreloadToken = nil
        if !preloadComplete {
            routes = []
            isLoading = false
        }
    }

    func resetPreloadState() {
        cancelPreload()
        preloadComplete = false
        routes = []
        errorMessage = nil
    }

    func retryPreload(for profile: UserProfile, now: Date = .now) {
        guard let endpoints = routeEndpoints(for: profile, now: now) else { return }
        routeCache = nil
        preloadTask?.cancel()
        preloadTask = nil
        activePreloadToken = nil
        isLoading = false
        routes = []
        preloadComplete = false
        errorMessage = nil
        preloadRoutes(from: endpoints.from, to: endpoints.to)
    }

    func destinationCandidates(for profile: UserProfile, now: Date = .now) -> [SavedLocation] {
        journeyIntent?.destinationCandidates
            ?? PlaceScheduleMatcher.matchingPlaces(in: profile.locations, now: now)
    }

    func needsDestinationPicker(for profile: UserProfile, now: Date = .now) -> Bool {
        let candidates = destinationCandidates(for: profile, now: now)
        guard candidates.count > 1 else { return false }
        guard let selectedDestinationID else { return true }
        return !candidates.contains(where: { $0.id == selectedDestinationID })
    }

    func selectDestination(_ location: SavedLocation) {
        selectedDestinationID = location.id
        routes = []
        preloadComplete = false
    }

    func resetDestinationSelectionIfNeeded(for profile: UserProfile, now: Date = .now) {
        let candidates = destinationCandidates(for: profile, now: now)
        if candidates.count <= 1 {
            selectedDestinationID = candidates.first?.id
            return
        }
        if let selectedDestinationID,
           candidates.contains(where: { $0.id == selectedDestinationID }) {
            return
        }
        selectedDestinationID = nil
    }

    func resolvedDestination(for profile: UserProfile, now: Date = .now) -> SavedLocation? {
        let candidates = destinationCandidates(for: profile, now: now)
        switch candidates.count {
        case 0:
            return nil
        case 1:
            return candidates[0]
        default:
            guard let selectedDestinationID else { return nil }
            return candidates.first(where: { $0.id == selectedDestinationID })
        }
    }

    func canStartJourney(for profile: UserProfile, now: Date = .now) -> Bool {
        routeEndpoints(for: profile, now: now) != nil
    }

    func commutePhase(for profile: UserProfile, now: Date = .now) -> HomeCommutePhase {
        HomeGreetingBuilder.phase(
            schedule: profile.commuteSchedule,
            otherLocation: resolvedDestination(for: profile, now: now) ?? profile.locations.first(where: { $0.label == .other }),
            now: now
        )
    }

    func routeEndpoints(for profile: UserProfile, now: Date = .now) -> (from: SavedLocation, to: SavedLocation)? {
        guard let intent = journeyIntent,
              let destination = resolvedDestination(for: profile, now: now) else {
            return nil
        }
        return (intent.origin, destination)
    }

    /// Prefers the user's saved custom route for the current journey, then the route closest to their learned commute pattern.
    func defaultRoute(for profile: UserProfile, now: Date = .now) -> Route? {
        if let endpoints = routeEndpoints(for: profile, now: now),
           let custom = profile.journeyRoute(from: endpoints.from, to: endpoints.to),
           custom.isValid {
            return custom.toRoute()
        }
        return RouteScorer.preferredRoute(from: routes, preference: profile.preferredCommutePattern)
    }

    func alternativeRoutes(for profile: UserProfile) -> [Route] {
        guard let preferred = defaultRoute(for: profile) else { return routes }
        return RouteScorer.rankedRoutes(
            routes.filter { $0.id != preferred.id },
            preference: profile.preferredCommutePattern
        )
    }

    func minutesUntilLeave(for profile: UserProfile, route: Route, now: Date = .now) -> Int? {
        CommuteLeavePlanner.minutesUntilLeave(route: route, now: now)
    }

    func leaveByTime(for profile: UserProfile, route: Route, now: Date = .now) -> String? {
        CommuteLeavePlanner.leaveByLabel(route: route, now: now)
    }

    var statusTimeLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: lastUpdated ?? Date())
    }

    var statusLine: String {
        let time = statusTimeLabel
        let displayStatus = routes.first(where: { $0.status.isOnTime })?.status.displayLabel
            ?? routes.first?.status.displayLabel
            ?? "Good service"
        return "\(time) · \(displayStatus)"
    }

    func networkDisruptions(matching preferences: LineVisibilityPreferences) -> [Disruption] {
        disruptions
            .filter { preferences.isVisible($0.line) }
            .sorted {
                $0.line.displayName.localizedCaseInsensitiveCompare($1.line.displayName) == .orderedAscending
            }
    }

    func primaryDisruption(matching preferences: LineVisibilityPreferences) -> Disruption? {
        networkDisruptions(matching: preferences).first
    }

    func disruptions(for route: Route) -> [Disruption] {
        let lines = Set(route.transitLines)
        let includesNationalRail = lines.contains(.nationalRail)

        return disruptions.filter { disruption in
            lines.contains(disruption.line)
                || (includesNationalRail && disruption.line.isNationalRailOperator)
        }
    }

    private func performRouteLoad(
        from: SavedLocation,
        to: SavedLocation,
        token: UUID?
    ) async {
        isLoading = true
        errorMessage = nil
        defer {
            if token == nil || activePreloadToken == token {
                isLoading = false
            }
        }

        do {
            let loadedRoutes = try await routeProvider.fetchRoutes(
                from: from,
                to: to,
                query: .departingNowLightweight
            )

            if let token, activePreloadToken != token || Task.isCancelled {
                return
            }

            routes = loadedRoutes
            if token != nil {
                preloadComplete = true
            }
            if loadedRoutes.isEmpty {
                errorMessage = "No routes found for this journey."
            } else {
                errorMessage = nil
                storeRouteCache(from: from, to: to, routes: loadedRoutes)
            }

            if let loadedDisruptions = try? await disruptionProvider.fetchDisruptions() {
                disruptions = loadedDisruptions
                lastUpdated = Date()
            }
        } catch is CancellationError {
        } catch {
            if token == nil || activePreloadToken == token {
                errorMessage = "Couldn't load routes. Try again."
            }
        }
    }

    private func cachedRoutes(from: SavedLocation, to: SavedLocation) -> [Route]? {
        guard let cache = routeCache,
              cache.fromID == from.id,
              cache.toID == to.id,
              !cache.routes.isEmpty,
              Date().timeIntervalSince(cache.fetchedAt) < routeCacheTTL else {
            return nil
        }
        return cache.routes
    }

    private func storeRouteCache(from: SavedLocation, to: SavedLocation, routes: [Route]) {
        routeCache = RouteCacheEntry(
            fromID: from.id,
            toID: to.id,
            routes: routes,
            fetchedAt: .now
        )
    }
}
