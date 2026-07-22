import CommuteKit
import CoreLocation
import Foundation
import Testing
@testable import commute

struct CommuteLiveActivityTimingTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(hour: Int, minute: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 7, day: 21, hour: hour, minute: minute))!
    }

    @Test func leaveByUsesTravelMinutes() {
        let arriveBy = date(hour: 9, minute: 0)
        let leaveBy = CommuteLiveActivityTiming.leaveByDate(arriveBy: arriveBy, travelMinutes: 35)
        #expect(leaveBy == date(hour: 8, minute: 25))
    }

    @Test func monitoringStartsSixtyMinutesBeforeLeave() {
        let leaveBy = date(hour: 8, minute: 25)
        #expect(CommuteLiveActivityTiming.monitoringStart(leaveBy: leaveBy) == date(hour: 7, minute: 25))
    }

    @Test func activityStartsThirtyMinutesBeforeLeave() {
        let leaveBy = date(hour: 8, minute: 25)
        #expect(CommuteLiveActivityTiming.activityStart(leaveBy: leaveBy) == date(hour: 7, minute: 55))
    }

    @Test func monitoringWindowBoundaries() {
        let leaveBy = date(hour: 8, minute: 25)
        #expect(CommuteLiveActivityTiming.isInMonitoringWindow(now: date(hour: 7, minute: 25), leaveBy: leaveBy))
        #expect(CommuteLiveActivityTiming.isInMonitoringWindow(now: date(hour: 7, minute: 54), leaveBy: leaveBy))
        #expect(!CommuteLiveActivityTiming.isInMonitoringWindow(now: date(hour: 7, minute: 55), leaveBy: leaveBy))
        #expect(!CommuteLiveActivityTiming.isInMonitoringWindow(now: date(hour: 7, minute: 24), leaveBy: leaveBy))
    }

    @Test func shouldStartActivityAfterThirtyMinuteLead() {
        let leaveBy = date(hour: 8, minute: 25)
        let arriveBy = date(hour: 9, minute: 0)
        #expect(CommuteLiveActivityTiming.shouldStartActivity(now: date(hour: 7, minute: 55), leaveBy: leaveBy, arriveBy: arriveBy))
        #expect(!CommuteLiveActivityTiming.shouldStartActivity(now: date(hour: 7, minute: 54), leaveBy: leaveBy, arriveBy: arriveBy))
    }

    @Test func nextPollDateIncrementsBySevenAndHalfMinutes() {
        let leaveBy = date(hour: 8, minute: 25)
        let now = date(hour: 7, minute: 25)
        let next = CommuteLiveActivityTiming.nextPollDate(now: now, leaveBy: leaveBy)
        #expect(next == now.addingTimeInterval(CommuteLiveActivityTiming.pollInterval))
    }

    @Test func phaseTransitions() {
        let leaveBy = date(hour: 8, minute: 25)
        let arriveBy = date(hour: 9, minute: 0)

        #expect(CommuteLiveActivityTiming.phase(now: date(hour: 8, minute: 0), leaveBy: leaveBy, arriveBy: arriveBy, current: .countdown) == .countdown)
        #expect(CommuteLiveActivityTiming.phase(now: date(hour: 8, minute: 25), leaveBy: leaveBy, arriveBy: arriveBy, current: .countdown) == .leaveNow)
        #expect(CommuteLiveActivityTiming.phase(now: date(hour: 8, minute: 28), leaveBy: leaveBy, arriveBy: arriveBy, current: .countdown) == .enRoute)
        #expect(CommuteLiveActivityTiming.phase(now: date(hour: 9, minute: 0), leaveBy: leaveBy, arriveBy: arriveBy, current: .countdown) == .arrived)
    }

    @Test func disruptionAlertPersistsUntilActivityStart() {
        let leaveBy = date(hour: 8, minute: 25)
        let arriveBy = date(hour: 9, minute: 0)
        #expect(
            CommuteLiveActivityTiming.phase(
                now: date(hour: 7, minute: 40),
                leaveBy: leaveBy,
                arriveBy: arriveBy,
                current: .disruptionAlert
            ) == .disruptionAlert
        )
    }
}

struct CommuteLegResolverTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(year: Int = 2026, month: Int = 7, day: Int = 21, hour: Int, minute: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func makeProfile(home: SavedLocation, work: SavedLocation) -> UserProfile {
        UserProfile(
            firstName: "Joe",
            useSerif: true,
            accentStyle: .gradient(.blue),
            mapsProvider: .apple,
            locations: [home, work],
            usualRoutes: []
        )
    }

    @Test func skipsMorningLegOnceItsArrivalHasPassed() {
        let home = SavedLocation(
            label: .home, address: "Home", coordinate: .init(latitude: 51.5, longitude: -0.1),
            schedule: PlaceSchedule.defaulted(for: .home)
        )
        let work = SavedLocation(
            label: .work, address: "Work", coordinate: .init(latitude: 51.51, longitude: -0.11),
            schedule: PlaceSchedule.defaulted(for: .work)
        )
        let profile = makeProfile(home: home, work: work)

        // 2026-07-21 is a Tuesday; the 9:00am work arrival is long past by the afternoon,
        // so nextLeg must fall through to the evening home leg instead of getting stuck.
        let leg = CommuteLegResolver.nextLeg(for: profile, now: date(hour: 14, minute: 0), calendar: calendar)
        #expect(leg?.destination.label == .home)
    }

    @Test func excludesLegWhoseDestinationScheduleDoesNotMatchToday() {
        let home = SavedLocation(
            label: .home, address: "Home", coordinate: .init(latitude: 51.5, longitude: -0.1),
            schedule: PlaceSchedule.defaulted(for: .home)
        )
        let work = SavedLocation(
            label: .work, address: "Work", coordinate: .init(latitude: 51.51, longitude: -0.11),
            schedule: PlaceSchedule.defaulted(for: .work)
        )
        let profile = makeProfile(home: home, work: work)

        // 2026-07-25 is a Saturday; both legs default to weekdays only, so neither should resolve.
        let leg = CommuteLegResolver.nextLeg(
            for: profile,
            now: date(year: 2026, month: 7, day: 25, hour: 8, minute: 0),
            calendar: calendar
        )
        #expect(leg == nil)
    }

    @Test func resolvesMorningLegBeforeItsArrival() {
        let home = SavedLocation(
            label: .home, address: "Home", coordinate: .init(latitude: 51.5, longitude: -0.1),
            schedule: PlaceSchedule.defaulted(for: .home)
        )
        let work = SavedLocation(
            label: .work, address: "Work", coordinate: .init(latitude: 51.51, longitude: -0.11),
            schedule: PlaceSchedule.defaulted(for: .work)
        )
        let profile = makeProfile(home: home, work: work)

        let leg = CommuteLegResolver.nextLeg(for: profile, now: date(hour: 7, minute: 30), calendar: calendar)
        #expect(leg?.destination.label == .work)
    }
}

struct CommuteTravelTimeEstimatorTests {
    @Test func prefersCustomRouteDuration() {
        let home = SavedLocation(
            label: .home,
            address: "Home",
            coordinate: .init(latitude: 51.5, longitude: -0.1)
        )
        let work = SavedLocation(
            label: .work,
            address: "Work",
            coordinate: .init(latitude: 51.51, longitude: -0.11)
        )
        let route = CustomCommuteRoute(steps: [
            CommuteBuilderStep(mode: .walk, fromStop: "A", toStop: "B", estimatedMinutes: 5),
            CommuteBuilderStep(mode: .train, lineID: TfLLine.elizabethLine.rawValue, lineName: "Elizabeth line", fromStop: "B", toStop: "C", estimatedMinutes: 30),
        ])
        var profile = UserProfile(
            firstName: "Joe",
            useSerif: true,
            accentStyle: .gradient(.blue),
            mapsProvider: .apple,
            locations: [home, work],
            usualRoutes: [],
            preferredCommutePattern: PreferredCommutePattern(route: Route(
                summary: "Test",
                totalMinutes: 99,
                legs: [.walk(minutes: 5, distanceMiles: 0.2)],
                status: .goodService
            ))
        )
        profile.setJourneyRoute(route, from: home, to: work)

        let leg = CommuteLeg(origin: home, destination: work, arriveBy: .now)
        let estimate = CommuteTravelTimeEstimator.estimate(for: profile, leg: leg)
        #expect(estimate.totalMinutes == 35)
    }
}

struct UsualRouteDisruptionCheckerTests {
    @Test func matchesPreferredPatternLines() {
        let home = SavedLocation(label: .home, address: "Home", coordinate: .init(latitude: 51.5, longitude: -0.1))
        let work = SavedLocation(label: .work, address: "Work", coordinate: .init(latitude: 51.51, longitude: -0.11))
        let profile = UserProfile(
            firstName: "Joe",
            useSerif: true,
            accentStyle: .gradient(.blue),
            mapsProvider: .apple,
            locations: [home, work],
            usualRoutes: [],
            preferredCommutePattern: PreferredCommutePattern(route: Route(
                summary: "Elizabeth",
                totalMinutes: 35,
                legs: [
                    .walk(minutes: 5, distanceMiles: 0.2),
                    .transit(
                        line: .elizabethLine,
                        from: "A",
                        to: "B",
                        departureTime: "08:00",
                        platform: nil,
                        stops: 3,
                        lineLabel: "Elizabeth line"
                    ),
                ],
                status: .goodService
            ))
        )
        let leg = CommuteLeg(origin: home, destination: work, arriveBy: .now)
        let lines = UsualRouteDisruptionChecker.usualLines(for: profile, leg: leg)
        #expect(lines.contains(.elizabethLine))

        let disruption = UsualRouteDisruptionChecker.worstDisruption(
            for: profile,
            leg: leg,
            disruptions: [
                Disruption(
                    line: .elizabethLine,
                    severity: .severeDelays,
                    statusLabel: "Severe delays",
                    reason: "Signal failure"
                )
            ]
        )
        #expect(disruption?.line == .elizabethLine)
        #expect(disruption?.severity == .severe)
    }
}
