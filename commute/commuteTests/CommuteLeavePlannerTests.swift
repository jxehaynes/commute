import Foundation
import Testing
@testable import commute

struct CommuteLeavePlannerTests {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/London") ?? .gmt
        return cal
    }

    private func date(
        year: Int = 2026,
        month: Int = 7,
        day: Int = 21,
        hour: Int,
        minute: Int
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components)!
    }

    private func route(
        walkMinutes: Int = 8,
        departureTime: String = "08:47"
    ) -> Route {
        Route(
            summary: "Via Central line",
            totalMinutes: walkMinutes + 20,
            legs: [
                .walk(minutes: walkMinutes, distanceMiles: 0.4),
                .transit(
                    line: .central,
                    from: "Notting Hill Gate",
                    to: "Bank",
                    departureTime: departureTime,
                    platform: "2",
                    stops: 6
                ),
                .walk(minutes: 3, distanceMiles: 0.2)
            ],
            status: .goodService
        )
    }

    @Test func minutesUntilLeaveUsesFirstTransitDepartureMinusWalk() {
        let now = date(hour: 8, minute: 30)
        let result = CommuteLeavePlanner.minutesUntilLeave(
            route: route(walkMinutes: 8, departureTime: "08:47"),
            now: now,
            calendar: calendar
        )
        #expect(result == 9)
    }

    @Test func minutesUntilLeaveIsZeroWhenWalkArrivesAtDeparture() {
        let now = date(hour: 8, minute: 39)
        let result = CommuteLeavePlanner.minutesUntilLeave(
            route: route(walkMinutes: 8, departureTime: "08:47"),
            now: now,
            calendar: calendar
        )
        #expect(result == 0)
    }

    @Test func leaveByLabelReflectsDepartureMinusWalk() {
        let now = date(hour: 8, minute: 30)
        let label = CommuteLeavePlanner.leaveByLabel(
            route: route(walkMinutes: 8, departureTime: "08:47"),
            now: now,
            calendar: calendar
        )
        #expect(label == "08:39")
    }

    @Test func walkOnlyRouteReturnsNilLeaveTiming() {
        let walkOnly = Route(
            summary: "Walk route",
            totalMinutes: 15,
            legs: [.walk(minutes: 15, distanceMiles: 0.8)],
            status: .goodService
        )
        let now = date(hour: 8, minute: 30)

        #expect(CommuteLeavePlanner.minutesUntilLeave(route: walkOnly, now: now, calendar: calendar) == nil)
        #expect(CommuteLeavePlanner.leaveByLabel(route: walkOnly, now: now, calendar: calendar) == nil)
    }

    @Test func invalidDepartureTimeReturnsNilLeaveTiming() {
        let now = date(hour: 8, minute: 30)
        let invalidRoute = route(walkMinutes: 5, departureTime: "--:--")

        #expect(CommuteLeavePlanner.minutesUntilLeave(route: invalidRoute, now: now, calendar: calendar) == nil)
        #expect(CommuteLeavePlanner.leaveByLabel(route: invalidRoute, now: now, calendar: calendar) == nil)
    }

    @Test func pastDepartureRollsToNextDay() {
        let now = date(hour: 20, minute: 0)
        let result = CommuteLeavePlanner.minutesUntilLeave(
            route: route(walkMinutes: 8, departureTime: "08:47"),
            now: now,
            calendar: calendar
        )
        // Leave at 08:39 next day = 12h 39m from 20:00
        #expect(result == 759)
    }

    @Test func accumulatesMultipleWalkLegsBeforeFirstTransit() {
        let multiWalk = Route(
            summary: "Via District line",
            totalMinutes: 25,
            legs: [
                .walk(minutes: 5, distanceMiles: 0.2),
                .walk(minutes: 3, distanceMiles: 0.15),
                .transit(
                    line: .district,
                    from: "Westminster",
                    to: "Tower Hill",
                    departureTime: "09:00",
                    platform: nil,
                    stops: 4
                )
            ],
            status: .goodService
        )
        let now = date(hour: 8, minute: 45)
        let result = CommuteLeavePlanner.minutesUntilLeave(route: multiWalk, now: now, calendar: calendar)
        // Leave at 08:52 (09:00 - 8 min walk), now 08:45 -> 7 mins
        #expect(result == 7)
    }
}
