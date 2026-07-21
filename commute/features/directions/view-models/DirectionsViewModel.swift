import Combine
import CommuteKit
import Foundation

@MainActor
final class DirectionsViewModel: ObservableObject {
    @Published private(set) var leg: CommuteLeg?
    @Published private(set) var walkMinutes = 0
    @Published private(set) var arrivals: [LiveArrival] = []
    @Published private(set) var decision: CommuteDecision.Result?
    @Published private(set) var remainingSteps: [RouteStepSummary] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let repository: ArrivalsRepository
    private var pollTask: Task<Void, Never>?

    init(repository: ArrivalsRepository = ArrivalsRepository()) {
        self.repository = repository
    }

    /// Starts polling live arrivals for the next commute leg every ~30s.
    /// Call `stop()` when the view disappears.
    func start(profile: UserProfile) {
        stop()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh(profile: profile)
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    func refresh(profile: UserProfile, now: Date = .now) async {
        guard let leg = NextLegResolver.nextLeg(for: profile, now: now) else {
            leg = nil
            errorMessage = "Add Home and Work in Settings to see your commute."
            return
        }
        self.leg = leg
        remainingSteps = (profile.customCommuteRoute?.stepsAfterFirstTransit ?? []).map {
            RouteStepSummary(icon: $0.mode.systemImage, label: $0.summary)
        }

        guard let naptanId = leg.origin.naptanId else {
            errorMessage = "Add a stop to \(leg.origin.displayName) in Settings to see live arrivals."
            arrivals = []
            decision = nil
            return
        }

        walkMinutes = WalkTimeEstimator.minutes(from: leg.origin)
        isLoading = arrivals.isEmpty
        do {
            let predictions = try await repository.arrivals(for: naptanId, now: now)
            arrivals = predictions.sorted { $0.expectedArrival < $1.expectedArrival }
            decision = CommuteDecision.choose(from: predictions, walkMinutes: walkMinutes, now: now)
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't load live arrivals — showing your last update."
        }
        isLoading = false
    }
}
