import Foundation

/// Single choke point for live TfL arrivals: caches per-stop results briefly
/// and de-duplicates concurrent requests, so the Live Activity ETA provider
/// and the polling Directions view can share one feed instead of each
/// hitting the network independently.
actor ArrivalsRepository {
    private let client: TfLArrivalsFetching
    private let cacheTTL: TimeInterval

    private struct CacheEntry {
        var arrivals: [LiveArrival]
        var fetchedAt: Date
    }

    private var cache: [String: CacheEntry] = [:]
    private var inFlight: [String: Task<[LiveArrival], Error>] = [:]

    init(client: TfLArrivalsFetching = TfLArrivalsClient(), cacheTTL: TimeInterval = 30) {
        self.client = client
        self.cacheTTL = cacheTTL
    }

    func arrivals(for naptanId: String, forceRefresh: Bool = false, now: Date = .now) async throws -> [LiveArrival] {
        if !forceRefresh, let cached = cache[naptanId], now.timeIntervalSince(cached.fetchedAt) < cacheTTL {
            return cached.arrivals
        }

        if let existing = inFlight[naptanId] {
            return try await existing.value
        }

        let client = client
        let task = Task<[LiveArrival], Error> {
            let fetchedAt = Date.now
            let predictions = try await client.arrivals(naptanId: naptanId)
            return predictions.map { LiveArrival(prediction: $0, fetchedAt: fetchedAt) }
        }
        inFlight[naptanId] = task

        do {
            let arrivals = try await task.value
            cache[naptanId] = CacheEntry(arrivals: arrivals, fetchedAt: .now)
            inFlight[naptanId] = nil
            return arrivals
        } catch {
            inFlight[naptanId] = nil
            throw error
        }
    }
}
