import BackgroundTasks
import Foundation

enum CommuteBackgroundRefresh {
    static let taskIdentifier = "dev.jh.commute.commute-check"
}

@MainActor
final class CommuteBackgroundRefreshManager {
    private let scheduler: CommuteLiveActivityScheduler
    private var foregroundPollTask: Task<Void, Never>?
    private var profileProvider: (() -> UserProfile)?

    init(scheduler: CommuteLiveActivityScheduler? = nil) {
        self.scheduler = scheduler ?? CommuteLiveActivityScheduler()
    }

    func configure(profileProvider: @escaping () -> UserProfile) {
        self.profileProvider = profileProvider
    }

    func register() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: CommuteBackgroundRefresh.taskIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { @MainActor in
                await self.handleBackgroundRefresh(refreshTask)
            }
        }
    }

    func runForegroundCheck() async {
        guard let profile = profileProvider?() else { return }
        let nextCheck = await scheduler.runCommuteCheck(profile: profile)
        scheduleBackgroundRefresh(earliest: nextCheck)
    }

    func startForegroundPollingIfNeeded() {
        foregroundPollTask?.cancel()
        foregroundPollTask = Task { @MainActor in
            while !Task.isCancelled {
                guard let profile = profileProvider?() else { return }
                guard profile.enableLiveActivities else { return }
                guard let leg = CommuteLegResolver.nextLeg(for: profile, now: .now) else { return }

                let estimate = CommuteTravelTimeEstimator.estimate(for: profile, leg: leg)
                let leaveBy = CommuteLiveActivityTiming.leaveByDate(
                    arriveBy: leg.arriveBy,
                    travelMinutes: estimate.totalMinutes
                )

                guard CommuteLiveActivityTiming.isInMonitoringWindow(now: .now, leaveBy: leaveBy)
                    || CommuteLiveActivityTiming.shouldStartActivity(
                        now: .now,
                        leaveBy: leaveBy,
                        arriveBy: leg.arriveBy
                    ) else {
                    return
                }

                let nextCheck = await scheduler.runCommuteCheck(profile: profile)
                scheduleBackgroundRefresh(earliest: nextCheck)

                let sleepInterval = CommuteLiveActivityTiming.pollInterval
                try? await Task.sleep(for: .seconds(sleepInterval))
            }
        }
    }

    func stopForegroundPolling() {
        foregroundPollTask?.cancel()
        foregroundPollTask = nil
    }

    private func handleBackgroundRefresh(_ task: BGAppRefreshTask) async {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        guard let profile = profileProvider?() else {
            task.setTaskCompleted(success: false)
            return
        }

        let nextCheck = await scheduler.runCommuteCheck(profile: profile)
        scheduleBackgroundRefresh(earliest: nextCheck)
        task.setTaskCompleted(success: true)
    }

    func scheduleBackgroundRefresh(earliest: Date?) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: CommuteBackgroundRefresh.taskIdentifier)
        guard let earliest else { return }

        let request = BGAppRefreshTaskRequest(identifier: CommuteBackgroundRefresh.taskIdentifier)
        request.earliestBeginDate = earliest
        try? BGTaskScheduler.shared.submit(request)
    }
}
