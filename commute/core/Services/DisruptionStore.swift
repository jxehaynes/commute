import Foundation

/// Shares a single cached disruption fetch across every part of the app that needs one (the
/// home screen's periodic refresh, the route load, and the Live Activity scheduler), so they
/// never independently hit the TfL status endpoint at the same time and never disagree about
/// how fresh the data is.
actor DisruptionStore: DisruptionProviding {
    static let shared = DisruptionStore()

    private let provider: any DisruptionProviding
    private let ttl: TimeInterval
    private var cached: (disruptions: [Disruption], fetchedAt: Date)?
    private var inFlight: Task<[Disruption], Error>?

    init(provider: any DisruptionProviding = TfLDisruptionProvider(), ttl: TimeInterval = 60) {
        self.provider = provider
        self.ttl = ttl
    }

    func fetchDisruptions() async throws -> [Disruption] {
        if let cached, Date().timeIntervalSince(cached.fetchedAt) < ttl {
            return cached.disruptions
        }

        if let inFlight {
            return try await inFlight.value
        }

        let task = Task<[Disruption], Error> {
            try await provider.fetchDisruptions()
        }
        inFlight = task

        do {
            let result = try await task.value
            cached = (disruptions: result, fetchedAt: Date())
            inFlight = nil
            return result
        } catch {
            inFlight = nil
            throw error
        }
    }
}
