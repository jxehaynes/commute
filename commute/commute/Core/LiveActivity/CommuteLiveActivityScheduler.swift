import ActivityKit
import CommuteKit
import Foundation

/// Starts, refreshes, and ends the "time to leave" Live Activity against the
/// user's saved schedule.
///
/// There's no push-to-update server in this app, so background refresh is
/// necessarily best-effort (foreground calls + opportunistic `BGAppRefreshTask`
/// windows). That's fine for the countdown itself — the Lock Screen/Dynamic
/// Island countdown text ticks natively via `Text(timerInterval:)` without any
/// app wake-up — it only limits how quickly a *live* ETA/disruption change
/// would be reflected mid-commute.
@MainActor
final class CommuteLiveActivityScheduler {
    private let etaProvider: CommuteETAProviding
    /// Extra minutes added on top of the raw travel time before computing "leave by".
    private let bufferMinutes: Int
    /// How long after `leaveByDate` to keep showing the urgency emphasis before
    /// treating the user as having set off.
    private let departureGrace: TimeInterval = 3 * 60
    /// How long past `arriveByDate` to leave the activity up before ending it.
    private let arrivalGrace: TimeInterval = 2 * 60
    /// The window before `leaveByDate` in which the activity is allowed to start.
    private let startWindowMinutes: ClosedRange<Double> = 20...30

    private var currentActivity: Activity<CommuteLiveActivityAttributes>?

    init(etaProvider: CommuteETAProviding, bufferMinutes: Int = 5) {
        self.etaProvider = etaProvider
        self.bufferMinutes = bufferMinutes
    }

    private struct Leg {
        var origin: SavedLocation
        var destination: SavedLocation
        var deadline: Date
    }

    /// Whichever of the two daily deadlines (arrive at work / arrive home) is
    /// the next one still ahead of `now`.
    private func nextLeg(for profile: UserProfile, now: Date, calendar: Calendar = .current) -> Leg? {
        guard
            let home = profile.location(labeled: .home),
            let work = profile.location(labeled: .work)
        else { return nil }

        func nextOccurrence(of components: DateComponents) -> Date? {
            calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTimePreservingSmallerComponents)
        }

        let legs = [
            nextOccurrence(of: profile.commuteSchedule.arriveAtWorkBy).map {
                Leg(origin: home, destination: work, deadline: $0)
            },
            nextOccurrence(of: profile.commuteSchedule.arriveHomeBy).map {
                Leg(origin: work, destination: home, deadline: $0)
            },
        ].compactMap { $0 }

        return legs.min { $0.deadline < $1.deadline }
    }

    /// Call when the app becomes active, and from a registered `BGAppRefreshTask`.
    /// Starts the activity only once `now` falls within 20–30 minutes of the
    /// computed "leave by" time for the next leg of the commute.
    func checkAndStartIfNeeded(profile: UserProfile, now: Date = .now) async {
        guard profile.enableLiveActivities else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard Activity<CommuteLiveActivityAttributes>.activities.isEmpty else { return }
        guard let leg = nextLeg(for: profile, now: now) else { return }
        guard let eta = try? await etaProvider.estimate(from: leg.origin, to: leg.destination, departing: now) else { return }

        let leaveBy = leg.deadline.addingTimeInterval(-TimeInterval((eta.totalMinutes + bufferMinutes) * 60))
        let minutesUntilLeave = leaveBy.timeIntervalSince(now) / 60
        guard startWindowMinutes.contains(minutesUntilLeave) else { return }

        let attributes = CommuteLiveActivityAttributes(
            destinationLabel: leg.destination.displayName,
            destinationIcon: leg.destination.label == .work ? "briefcase.fill" : "house.fill",
            accent: profile.accent
        )
        let state = CommuteLiveActivityAttributes.ContentState(
            leaveByDate: leaveBy,
            arriveByDate: leg.deadline,
            etaMinutes: eta.totalMinutes,
            routeSteps: eta.steps,
            disruption: eta.disruption,
            disruptionMessage: eta.disruptionMessage,
            phase: .countdown
        )

        currentActivity = try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: leg.deadline.addingTimeInterval(15 * 60)),
            pushType: nil
        )
    }

    /// Call periodically (foreground timer / BG task) while an activity is running.
    /// Re-derives ETA/disruption and advances `phase` as time passes; ends the
    /// activity once the user should have arrived.
    func refresh(profile: UserProfile, now: Date = .now) async {
        guard let activity = currentActivity ?? Activity<CommuteLiveActivityAttributes>.activities.first else { return }
        var state = activity.content.state

        if now >= state.arriveByDate.addingTimeInterval(arrivalGrace) {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
            return
        }

        let phase: CommutePhase
        if now >= state.arriveByDate {
            phase = .arrived
        } else if now >= state.leaveByDate.addingTimeInterval(departureGrace) {
            phase = .enRoute
        } else if now >= state.leaveByDate {
            phase = .leaveNow
        } else {
            phase = .countdown
        }

        // The activity is heading toward whichever place isn't its destination.
        let destinationLabel: SavedLocation.LocationLabel = activity.attributes.destinationIcon == "briefcase.fill" ? .work : .home
        let originLabel: SavedLocation.LocationLabel = destinationLabel == .work ? .home : .work
        if let origin = profile.location(labeled: originLabel), let destination = profile.location(labeled: destinationLabel),
           let eta = try? await etaProvider.estimate(from: origin, to: destination, departing: now) {
            state.etaMinutes = eta.totalMinutes
            state.routeSteps = eta.steps
            state.disruption = eta.disruption
            state.disruptionMessage = eta.disruptionMessage
        }

        state.phase = phase
        await activity.update(.init(state: state, staleDate: state.arriveByDate.addingTimeInterval(15 * 60)))
    }
}
