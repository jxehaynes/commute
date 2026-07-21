import Foundation

struct UserProfile: Codable {
    var firstName: String
    var useSerif: Bool
    var accentStyle: AccentStyle
    var mapsProvider: MapsProvider
    var locations: [SavedLocation]
    var usualRoutes: [UsualRoute]
    var commuteSchedule: CommuteSchedule
    var journeyRoutes: [JourneyCommuteRoute]
    var preferredCommutePattern: PreferredCommutePattern?
    var enablePaceLearning: Bool
    var enableLiveActivities: Bool
    var lineVisibility: LineVisibilityPreferences

    init(
        firstName: String,
        useSerif: Bool,
        accentStyle: AccentStyle,
        mapsProvider: MapsProvider,
        locations: [SavedLocation],
        usualRoutes: [UsualRoute],
        commuteSchedule: CommuteSchedule = .default,
        journeyRoutes: [JourneyCommuteRoute] = [],
        preferredCommutePattern: PreferredCommutePattern? = nil,
        enablePaceLearning: Bool = false,
        enableLiveActivities: Bool = false,
        lineVisibility: LineVisibilityPreferences = .default
    ) {
        self.firstName = firstName
        self.useSerif = useSerif
        self.accentStyle = accentStyle
        self.mapsProvider = mapsProvider
        self.locations = locations
        self.usualRoutes = usualRoutes
        self.commuteSchedule = commuteSchedule
        self.journeyRoutes = journeyRoutes
        self.preferredCommutePattern = preferredCommutePattern
        self.enablePaceLearning = enablePaceLearning
        self.enableLiveActivities = enableLiveActivities
        self.lineVisibility = lineVisibility
    }

    enum CodingKeys: String, CodingKey {
        case firstName, useSerif, accentStyle, mapsProvider, locations, usualRoutes, commuteSchedule
        case journeyRoutes
        case customCommuteRoute // legacy key, decode-only, used for one-time migration
        case preferredCommutePattern, enablePaceLearning, enableLiveActivities, lineVisibility
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        firstName = try container.decode(String.self, forKey: .firstName)
        useSerif = try container.decode(Bool.self, forKey: .useSerif)
        accentStyle = try container.decode(AccentStyle.self, forKey: .accentStyle)
        mapsProvider = try container.decode(MapsProvider.self, forKey: .mapsProvider)
        locations = try container.decode([SavedLocation].self, forKey: .locations)
        usualRoutes = try container.decode([UsualRoute].self, forKey: .usualRoutes)
        commuteSchedule = try container.decodeIfPresent(CommuteSchedule.self, forKey: .commuteSchedule) ?? .default
        journeyRoutes = try container.decodeIfPresent([JourneyCommuteRoute].self, forKey: .journeyRoutes) ?? []
        preferredCommutePattern = try container.decodeIfPresent(PreferredCommutePattern.self, forKey: .preferredCommutePattern)
        enablePaceLearning = try container.decodeIfPresent(Bool.self, forKey: .enablePaceLearning) ?? false
        enableLiveActivities = try container.decodeIfPresent(Bool.self, forKey: .enableLiveActivities) ?? false
        lineVisibility = try container.decodeIfPresent(LineVisibilityPreferences.self, forKey: .lineVisibility) ?? .default
        migrateLocationSchedulesIfNeeded()
        migrateLegacyCustomCommuteRouteIfNeeded(container: container)
        migrateTypicalTravelMinutesIfNeeded()
    }

    /// Keep schedule travel time aligned with the user's chosen usual route fingerprint.
    private mutating func migrateTypicalTravelMinutesIfNeeded() {
        guard let pattern = preferredCommutePattern else { return }
        guard commuteSchedule.typicalTravelMinutes != pattern.totalMinutes else { return }
        commuteSchedule.typicalTravelMinutes = pattern.totalMinutes
    }

    /// Older versions stored a single global `customCommuteRoute` with no address pairing.
    /// If present, fold it into `journeyRoutes` under Home → Work so it isn't silently dropped.
    private mutating func migrateLegacyCustomCommuteRouteIfNeeded(container: KeyedDecodingContainer<CodingKeys>) {
        guard journeyRoutes.isEmpty,
              let legacyRoute = try? container.decodeIfPresent(CustomCommuteRoute.self, forKey: .customCommuteRoute),
              let home = locations.first(where: { $0.label == .home }),
              let work = locations.first(where: { $0.label == .work }) else {
            return
        }
        journeyRoutes = [JourneyCommuteRoute(routePair: RoutePair(fromID: home.id, toID: work.id), route: legacyRoute)]
    }

    // `customCommuteRoute` is a decode-only legacy key with no matching stored property,
    // so `encode(to:)` must be written by hand (auto-synthesis requires every CodingKeys
    // case to map to a stored property).
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(useSerif, forKey: .useSerif)
        try container.encode(accentStyle, forKey: .accentStyle)
        try container.encode(mapsProvider, forKey: .mapsProvider)
        try container.encode(locations, forKey: .locations)
        try container.encode(usualRoutes, forKey: .usualRoutes)
        try container.encode(commuteSchedule, forKey: .commuteSchedule)
        try container.encode(journeyRoutes, forKey: .journeyRoutes)
        try container.encodeIfPresent(preferredCommutePattern, forKey: .preferredCommutePattern)
        try container.encode(enablePaceLearning, forKey: .enablePaceLearning)
        try container.encode(enableLiveActivities, forKey: .enableLiveActivities)
        try container.encode(lineVisibility, forKey: .lineVisibility)
    }

    enum MapsProvider: String, Codable, CaseIterable {
        case apple, google, openStreetMap

        var displayName: String {
            switch self {
            case .apple: "Apple MapKit"
            case .google: "Google Maps"
            case .openStreetMap: "OpenStreetMap"
            }
        }

        var privacySummary: String {
            switch self {
            case .apple: "Live search is enabled through Apple's native MapKit services."
            case .google: "Provider wiring is in place, but Google Places needs an API key and billing before it can be enabled."
            case .openStreetMap: "Provider wiring is in place, but production OSM search needs a hosted Nominatim, Photon or Pelias service."
            }
        }

        var isLocationSearchEnabled: Bool {
            self == .apple
        }

        var availabilityLabel: String {
            isLocationSearchEnabled ? "Live" : "Coming soon"
        }
    }
}

struct RoutePair: Codable, Hashable {
    let fromID: UUID
    let toID: UUID
}

/// A custom-built commute route tied to a specific directional pair of saved addresses.
/// A → B and B → A are distinct pairs, so each direction can have its own route.
struct JourneyCommuteRoute: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var routePair: RoutePair
    var route: CustomCommuteRoute
}

extension UserProfile {
    func journeyRoute(from: SavedLocation, to: SavedLocation) -> CustomCommuteRoute? {
        journeyRoutes.first(where: { $0.routePair == RoutePair(fromID: from.id, toID: to.id) })?.route
    }

    mutating func setJourneyRoute(_ route: CustomCommuteRoute, from: SavedLocation, to: SavedLocation) {
        let pair = RoutePair(fromID: from.id, toID: to.id)
        if let index = journeyRoutes.firstIndex(where: { $0.routePair == pair }) {
            journeyRoutes[index].route = route
        } else {
            journeyRoutes.append(JourneyCommuteRoute(routePair: pair, route: route))
        }
    }

    mutating func removeJourneyRoute(from: SavedLocation, to: SavedLocation) {
        let pair = RoutePair(fromID: from.id, toID: to.id)
        journeyRoutes.removeAll { $0.routePair == pair }
    }

    /// Drops journey routes whose endpoints no longer exist in `locations`. Call after editing saved places.
    mutating func pruneOrphanedJourneyRoutes() {
        let ids = Set(locations.map(\.id))
        journeyRoutes.removeAll { !ids.contains($0.routePair.fromID) || !ids.contains($0.routePair.toID) }
    }
}

struct UsualRoute: Codable {
    let routePair: RoutePair
    let legs: [RouteLeg]
    let activeDays: Set<Weekday>
    let departureTime: DateComponents
    let notificationLeadMinutes: Int
}

enum Weekday: Int, Codable, CaseIterable, Hashable {
    case monday = 2, tuesday, wednesday, thursday, friday, saturday, sunday

    var shortLabel: String {
        switch self {
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        case .sunday: "Sun"
        }
    }
}
