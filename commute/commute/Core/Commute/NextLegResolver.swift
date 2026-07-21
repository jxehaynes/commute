import Foundation

/// A single leg of the daily commute — which saved place to which, and by
/// what deadline.
struct CommuteLeg {
    var origin: SavedLocation
    var destination: SavedLocation
    var deadline: Date
}

/// Picks whichever of the user's two daily deadlines (arrive at work / arrive
/// home) is the next one still ahead of `now`. Shared by the Live Activity
/// scheduler and the in-app Directions view so both agree on "what's next".
enum NextLegResolver {
    static func nextLeg(for profile: UserProfile, now: Date, calendar: Calendar = .current) -> CommuteLeg? {
        guard
            let home = profile.location(labeled: .home),
            let work = profile.location(labeled: .work)
        else { return nil }

        func nextOccurrence(of components: DateComponents) -> Date? {
            calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTimePreservingSmallerComponents)
        }

        let legs = [
            nextOccurrence(of: profile.commuteSchedule.arriveAtWorkBy).map {
                CommuteLeg(origin: home, destination: work, deadline: $0)
            },
            nextOccurrence(of: profile.commuteSchedule.arriveHomeBy).map {
                CommuteLeg(origin: work, destination: home, deadline: $0)
            },
        ].compactMap { $0 }

        return legs.min { $0.deadline < $1.deadline }
    }
}
