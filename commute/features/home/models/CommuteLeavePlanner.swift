import Foundation

enum CommuteLeavePlanner {
    static func firstBoardingLeaveTime(
        route: Route,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Date? {
        var walkMinutes = 0

        for leg in route.legs {
            switch leg {
            case .walk(let minutes, _):
                walkMinutes += minutes
            case .transit(_, _, _, let departureTime, _, _, _):
                guard let departure = parseDepartureTime(
                    departureTime,
                    relativeTo: now,
                    calendar: calendar
                ) else {
                    return nil
                }
                return calendar.date(byAdding: .minute, value: -walkMinutes, to: departure)
            }
        }

        return nil
    }

    static func minutesUntilLeave(
        route: Route,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Int? {
        guard let leave = firstBoardingLeaveTime(route: route, now: now, calendar: calendar) else {
            return nil
        }
        return max(0, Int(leave.timeIntervalSince(now).rounded(.up) / 60))
    }

    static func leaveByLabel(
        route: Route,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> String? {
        guard let leave = firstBoardingLeaveTime(route: route, now: now, calendar: calendar) else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.calendar = calendar
        return formatter.string(from: leave)
    }

    private static func parseDepartureTime(
        _ timeString: String,
        relativeTo now: Date,
        calendar: Calendar
    ) -> Date? {
        guard timeString != "--:--" else { return nil }

        let parts = timeString.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else {
            return nil
        }

        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard var departure = calendar.date(from: components) else { return nil }

        if departure <= now {
            departure = calendar.date(byAdding: .day, value: 1, to: departure) ?? departure
        }

        return departure
    }
}
