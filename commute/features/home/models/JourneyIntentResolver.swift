import CoreLocation
import Foundation

struct JourneyIntent: Equatable {
    let presence: PlacePresence
    let origin: SavedLocation
    let destinationCandidates: [SavedLocation]

    var defaultDestination: SavedLocation? {
        destinationCandidates.count == 1 ? destinationCandidates[0] : nil
    }
}

enum JourneyIntentResolver {
    static func resolve(
        profile: UserProfile,
        presence: PlacePresence,
        currentLocation: CLLocation?,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> JourneyIntent? {
        var candidates = PlaceScheduleMatcher.matchingPlaces(
            in: profile.locations,
            now: now,
            calendar: calendar
        )

        if case .atSavedPlace(let place) = presence {
            candidates.removeAll { $0.id == place.id }
        }

        if candidates.isEmpty {
            candidates = fallbackCandidates(
                profile: profile,
                presence: presence,
                now: now,
                calendar: calendar
            )
        }

        guard !candidates.isEmpty,
              let origin = resolveOrigin(
                profile: profile,
                presence: presence,
                currentLocation: currentLocation,
                now: now,
                calendar: calendar
              ) else {
            return legacyIntent(profile: profile, presence: presence, now: now, calendar: calendar)
        }

        return JourneyIntent(
            presence: presence,
            origin: origin,
            destinationCandidates: candidates
        )
    }

    private static func fallbackCandidates(
        profile: UserProfile,
        presence: PlacePresence,
        now: Date,
        calendar: Calendar
    ) -> [SavedLocation] {
        let home = profile.locations.first(where: { $0.label == .home })
        let work = profile.locations.first(where: { $0.label == .work })

        switch presence {
        case .atSavedPlace(let place):
            switch place.label {
            case .home:
                if let work { return [work] }
            case .work:
                if let home { return [home] }
            case .other:
                if let home { return [home] }
            }
            return []
        case .elsewhere, .unknown:
            if let endpoints = legacyEndpoints(profile: profile, now: now, calendar: calendar) {
                return [endpoints.to]
            }
            return []
        }
    }

    private static func resolveOrigin(
        profile: UserProfile,
        presence: PlacePresence,
        currentLocation: CLLocation?,
        now: Date,
        calendar: Calendar
    ) -> SavedLocation? {
        switch presence {
        case .atSavedPlace(let place):
            return place
        case .elsewhere:
            guard let currentLocation else {
                return legacyEndpoints(profile: profile, now: now, calendar: calendar)?.from
            }
            return SavedLocation.ephemeral(at: currentLocation.coordinate)
        case .unknown:
            return legacyEndpoints(profile: profile, now: now, calendar: calendar)?.from
        }
    }

    private static func legacyIntent(
        profile: UserProfile,
        presence: PlacePresence,
        now: Date,
        calendar: Calendar
    ) -> JourneyIntent? {
        guard let endpoints = legacyEndpoints(profile: profile, now: now, calendar: calendar) else {
            return nil
        }
        return JourneyIntent(
            presence: presence,
            origin: endpoints.from,
            destinationCandidates: [endpoints.to]
        )
    }

    private static func legacyEndpoints(
        profile: UserProfile,
        now: Date,
        calendar: Calendar
    ) -> (from: SavedLocation, to: SavedLocation)? {
        let home = profile.locations.first(where: { $0.label == .home })
        let work = profile.locations.first(where: { $0.label == .work })
        let other = profile.locations.first(where: { $0.label == .other })

        let schedule = profile.commuteSchedule
        guard let leaveForWork = schedule.leaveForWork(on: now, calendar: calendar),
              let leaveForHome = schedule.leaveForHome(on: now, calendar: calendar) else {
            guard let home else { return nil }
            if let other { return (home, other) }
            if let work { return (work, home) }
            return nil
        }

        if now < leaveForWork {
            guard let home, let work else { return nil }
            return (home, work)
        }
        if now < leaveForHome {
            guard let work, let home else { return nil }
            return (work, home)
        }
        guard let home else { return nil }
        if let other { return (home, other) }
        if let work { return (work, home) }
        return nil
    }
}
