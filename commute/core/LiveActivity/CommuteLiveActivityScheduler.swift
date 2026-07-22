import ActivityKit
import CommuteKit
import Foundation

enum CommuteLiveActivityTiming {
    static let preMonitoringLead: TimeInterval = 60 * 60
    static let activityLead: TimeInterval = 30 * 60
    static let pollInterval: TimeInterval = 7.5 * 60
    static let departureGrace: TimeInterval = 3 * 60
    static let arrivalGrace: TimeInterval = 2 * 60

    static func leaveByDate(arriveBy: Date, travelMinutes: Int) -> Date {
        arriveBy.addingTimeInterval(-TimeInterval(travelMinutes * 60))
    }

    static func monitoringStart(leaveBy: Date) -> Date {
        leaveBy.addingTimeInterval(-preMonitoringLead)
    }

    static func activityStart(leaveBy: Date) -> Date {
        leaveBy.addingTimeInterval(-activityLead)
    }

    static func isInMonitoringWindow(now: Date, leaveBy: Date) -> Bool {
        now >= monitoringStart(leaveBy: leaveBy) && now < activityStart(leaveBy: leaveBy)
    }

    static func shouldStartActivity(now: Date, leaveBy: Date, arriveBy: Date) -> Bool {
        now >= activityStart(leaveBy: leaveBy) && now < arriveBy.addingTimeInterval(arrivalGrace)
    }

    static func nextPollDate(now: Date, leaveBy: Date) -> Date? {
        guard isInMonitoringWindow(now: now, leaveBy: leaveBy) else { return nil }
        let candidate = now.addingTimeInterval(pollInterval)
        let end = activityStart(leaveBy: leaveBy)
        return candidate <= end ? candidate : end
    }

    static func nextCheckDate(now: Date, leaveBy: Date, arriveBy: Date) -> Date? {
        if now >= arriveBy.addingTimeInterval(arrivalGrace) { return nil }
        if now >= activityStart(leaveBy: leaveBy) {
            return now.addingTimeInterval(pollInterval)
        }
        if let poll = nextPollDate(now: now, leaveBy: leaveBy) {
            return poll
        }
        if now < monitoringStart(leaveBy: leaveBy) {
            return monitoringStart(leaveBy: leaveBy)
        }
        return nil
    }

    static func phase(now: Date, leaveBy: Date, arriveBy: Date, current: CommutePhase) -> CommutePhase {
        if current == .disruptionAlert, now < activityStart(leaveBy: leaveBy) {
            return .disruptionAlert
        }
        if now >= arriveBy {
            return .arrived
        }
        if now >= leaveBy.addingTimeInterval(departureGrace) {
            return .enRoute
        }
        if now >= leaveBy {
            return .leaveNow
        }
        return .countdown
    }
}

/// Starts, refreshes, and ends the "time to leave" Live Activity against the
/// user's saved schedule.
@MainActor
final class CommuteLiveActivityScheduler {
    private let disruptionProvider: DisruptionProviding
    private let routeProvider: any RouteProviding
    private var currentActivity: Activity<CommuteLiveActivityAttributes>?

    init(disruptionProvider: DisruptionProviding? = nil, routeProvider: (any RouteProviding)? = nil) {
        self.disruptionProvider = disruptionProvider ?? DisruptionStore.shared
        self.routeProvider = routeProvider ?? BestAvailableRouteProvider()
    }

    /// Single orchestration entry point for foreground, background, and launch.
    @discardableResult
    func runCommuteCheck(profile: UserProfile, now: Date = .now, calendar: Calendar = .current) async -> Date? {
        guard profile.enableLiveActivities else { return nil }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return nil }
        guard let leg = CommuteLegResolver.nextLeg(for: profile, now: now, calendar: calendar) else {
            // Nothing left to show today (or today's schedule/weekday doesn't match) —
            // wake up again at the start of the next day rather than going silent until
            // the user happens to reopen the app.
            let startOfToday = calendar.startOfDay(for: now)
            return calendar.date(byAdding: .day, value: 1, to: startOfToday)
        }

        let estimate = await CommuteTravelTimeEstimator.estimate(
            for: profile,
            leg: leg,
            routeProvider: routeProvider,
            disruptionProvider: disruptionProvider
        )
        let leaveBy = CommuteLiveActivityTiming.leaveByDate(arriveBy: leg.arriveBy, travelMinutes: estimate.totalMinutes)

        if let activity = activeActivity() {
            await refreshExistingActivity(
                activity: activity,
                profile: profile,
                leg: leg,
                estimate: estimate,
                leaveBy: leaveBy,
                now: now
            )
            return CommuteLiveActivityTiming.nextCheckDate(now: now, leaveBy: leaveBy, arriveBy: leg.arriveBy)
        }

        if CommuteLiveActivityTiming.isInMonitoringWindow(now: now, leaveBy: leaveBy) {
            await pollMonitoringWindow(
                profile: profile,
                leg: leg,
                estimate: estimate,
                leaveBy: leaveBy,
                now: now
            )
        }

        if CommuteLiveActivityTiming.shouldStartActivity(now: now, leaveBy: leaveBy, arriveBy: leg.arriveBy) {
            await startNormalActivity(
                profile: profile,
                leg: leg,
                estimate: estimate,
                leaveBy: leaveBy,
                disruption: nil,
                now: now
            )
        }

        return CommuteLiveActivityTiming.nextCheckDate(now: now, leaveBy: leaveBy, arriveBy: leg.arriveBy)
    }

    private func pollMonitoringWindow(
        profile: UserProfile,
        leg: CommuteLeg,
        estimate: CommuteTravelEstimate,
        leaveBy: Date,
        now: Date
    ) async {
        guard activeActivity() == nil else { return }

        let disruptions = (try? await disruptionProvider.fetchDisruptions()) ?? []
        guard let routeDisruption = UsualRouteDisruptionChecker.worstDisruption(
            for: profile,
            leg: leg,
            disruptions: disruptions
        ) else { return }

        await startNormalActivity(
            profile: profile,
            leg: leg,
            estimate: estimate,
            leaveBy: leaveBy,
            disruption: routeDisruption,
            now: now
        )
    }

    private func startNormalActivity(
        profile: UserProfile,
        leg: CommuteLeg,
        estimate: CommuteTravelEstimate,
        leaveBy: Date,
        disruption: UsualRouteDisruption?,
        now: Date
    ) async {
        guard activeActivity() == nil else { return }

        let phase: CommutePhase
        if disruption != nil, CommuteLiveActivityTiming.isInMonitoringWindow(now: now, leaveBy: leaveBy) {
            phase = .disruptionAlert
        } else {
            phase = CommuteLiveActivityTiming.phase(
                now: now,
                leaveBy: leaveBy,
                arriveBy: leg.arriveBy,
                current: .countdown
            )
        }

        let attributes = makeAttributes(profile: profile, leg: leg)
        let state = makeContentState(
            leg: leg,
            estimate: estimate,
            leaveBy: leaveBy,
            disruption: disruption,
            phase: phase
        )

        currentActivity = try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: leg.arriveBy.addingTimeInterval(15 * 60)),
            pushType: nil
        )
    }

    private func refreshExistingActivity(
        activity: Activity<CommuteLiveActivityAttributes>,
        profile: UserProfile,
        leg: CommuteLeg,
        estimate: CommuteTravelEstimate,
        leaveBy: Date,
        now: Date
    ) async {
        if now >= leg.arriveBy.addingTimeInterval(CommuteLiveActivityTiming.arrivalGrace) {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
            return
        }

        let disruptions = (try? await disruptionProvider.fetchDisruptions()) ?? []
        let routeDisruption = UsualRouteDisruptionChecker.worstDisruption(
            for: profile,
            leg: leg,
            disruptions: disruptions
        )

        if activity.content.state.phase == .disruptionAlert,
           routeDisruption == nil,
           now < CommuteLiveActivityTiming.activityStart(leaveBy: leaveBy) {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
            return
        }

        var phase = CommuteLiveActivityTiming.phase(
            now: now,
            leaveBy: leaveBy,
            arriveBy: leg.arriveBy,
            current: activity.content.state.phase
        )

        if phase == .disruptionAlert, now >= CommuteLiveActivityTiming.activityStart(leaveBy: leaveBy) {
            phase = CommuteLiveActivityTiming.phase(
                now: now,
                leaveBy: leaveBy,
                arriveBy: leg.arriveBy,
                current: .countdown
            )
        }

        // Disruption status is shown throughout (StatusLine renders it in every phase, not just
        // .disruptionAlert), so the current disruption always carries through unconditionally.
        let state = makeContentState(
            leg: leg,
            estimate: estimate,
            leaveBy: leaveBy,
            disruption: routeDisruption,
            phase: phase
        )

        await activity.update(.init(state: state, staleDate: leg.arriveBy.addingTimeInterval(15 * 60)))
    }

    private func activeActivity() -> Activity<CommuteLiveActivityAttributes>? {
        currentActivity ?? Activity<CommuteLiveActivityAttributes>.activities.first
    }

    private func makeAttributes(profile: UserProfile, leg: CommuteLeg) -> CommuteLiveActivityAttributes {
        CommuteLiveActivityAttributes(
            destinationLabel: leg.destination.displayName,
            destinationIcon: leg.destination.label == .work ? "briefcase.fill" : "house.fill",
            accent: LiveActivityAccent(accentStyle: profile.accentStyle)
        )
    }

    private func makeContentState(
        leg: CommuteLeg,
        estimate: CommuteTravelEstimate,
        leaveBy: Date,
        disruption: UsualRouteDisruption?,
        phase: CommutePhase
    ) -> CommuteLiveActivityAttributes.ContentState {
        CommuteLiveActivityAttributes.ContentState(
            leaveByDate: leaveBy,
            arriveByDate: leg.arriveBy,
            etaMinutes: estimate.totalMinutes,
            routeSteps: estimate.routeSteps,
            disruption: disruption?.severity ?? .onTime,
            disruptionMessage: disruption?.message,
            alertLineName: disruption?.line.displayName,
            phase: phase
        )
    }
}
