import Foundation

enum PlaceScheduleMatcher {
    static func matchingPlaces(
        in locations: [SavedLocation],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [SavedLocation] {
        locations.filter { $0.schedule.matches(now: now, calendar: calendar) }
    }
}
