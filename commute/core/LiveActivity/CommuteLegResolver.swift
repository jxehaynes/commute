import Foundation

/// A single leg of the daily commute — which saved place to which, and by what deadline.
struct CommuteLeg: Equatable {
    var origin: SavedLocation
    var destination: SavedLocation
    var arriveBy: Date
}

/// Picks whichever of the user's two daily deadlines (arrive at work / arrive home)
/// is the next one still ahead of `now`.
enum CommuteLegResolver {
    static func nextLeg(for profile: UserProfile, now: Date, calendar: Calendar = .current) -> CommuteLeg? {
        guard
            let home = profile.locations.first(where: { $0.label == .home }),
            let work = profile.locations.first(where: { $0.label == .work })
        else { return nil }

        let legs = [
            profile.commuteSchedule.arriveAtWork(on: now, calendar: calendar).map {
                CommuteLeg(origin: home, destination: work, arriveBy: $0)
            },
            profile.commuteSchedule.arriveHome(on: now, calendar: calendar).map {
                CommuteLeg(origin: work, destination: home, arriveBy: $0)
            },
        ]
        .compactMap { $0 }
        // Drop legs whose deadline (plus arrival grace) has already passed today, so a
        // completed morning commute doesn't keep shadowing the evening one.
        .filter { $0.arriveBy.addingTimeInterval(CommuteLiveActivityTiming.arrivalGrace) > now }
        // Respect each destination's configured days/periods (e.g. "weekdays only").
        .filter { $0.destination.schedule.matches(now: now, calendar: calendar) }

        return legs.min { $0.arriveBy < $1.arriveBy }
    }
}
