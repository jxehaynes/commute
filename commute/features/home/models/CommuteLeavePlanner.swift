import Foundation

enum CommuteLeavePlanner {
    /// When the route's first transit leg has a real scheduled departure, leave time is that
    /// departure minus the walk to get there. Otherwise (Apple Maps fallback, a hand-built
    /// custom route, or a walk-only route — none of which have a real clock time) falls back to
    /// counting back from `arriveBy` using the route's total duration.
    static func firstBoardingLeaveTime(
        route: Route,
        arriveBy: Date? = nil,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Date? {
        var walkMinutes = 0

        for leg in route.legs {
            switch leg {
            case .walk(let minutes, _):
                walkMinutes += minutes
            case .transit(_, _, _, let departureTime, _, _, _):
                guard let departureTime else { break }
                return calendar.date(byAdding: .minute, value: -walkMinutes, to: departureTime)
            }
        }

        guard let arriveBy else { return nil }
        return arriveBy.addingTimeInterval(-TimeInterval(route.totalMinutes * 60))
    }

    static func minutesUntilLeave(
        route: Route,
        arriveBy: Date? = nil,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int? {
        guard let leave = firstBoardingLeaveTime(route: route, arriveBy: arriveBy, now: now, calendar: calendar) else {
            return nil
        }
        return max(0, Int(leave.timeIntervalSince(now).rounded(.up) / 60))
    }

    static func leaveByLabel(
        route: Route,
        arriveBy: Date? = nil,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> String? {
        guard let leave = firstBoardingLeaveTime(route: route, arriveBy: arriveBy, now: now, calendar: calendar) else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.calendar = calendar
        return formatter.string(from: leave)
    }
}
