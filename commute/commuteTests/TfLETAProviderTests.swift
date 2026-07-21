import CoreLocation
import Foundation
import Testing
@testable import commute

private struct StubFetcher: TfLArrivalsFetching {
    var predictions: [TfLPrediction]

    func arrivals(naptanId: String) async throws -> [TfLPrediction] {
        predictions
    }
}

private struct StubETAProvider: CommuteETAProviding {
    var eta: CommuteETA

    func estimate(from origin: SavedLocation, to destination: SavedLocation, departing date: Date) async throws -> CommuteETA {
        eta
    }
}

struct TfLETAProviderTests {
    private let now = Date(timeIntervalSince1970: 0)

    private func location(naptanId: String?, routingCoordinate: CLLocationCoordinate2D?) -> SavedLocation {
        SavedLocation(
            id: UUID(),
            label: .home,
            customName: nil,
            address: "1 Test Street",
            coordinate: CLLocationCoordinate2D(latitude: 51.538, longitude: -0.104),
            naptanId: naptanId,
            routingCoordinate: routingCoordinate
        )
    }

    @Test func fallsBackWhenOriginHasNoNaptanId() async throws {
        let fallback = StubETAProvider(eta: CommuteETA(totalMinutes: 35, steps: [], disruption: .onTime, disruptionMessage: nil))
        let provider = TfLETAProvider(
            fallback: fallback,
            repository: ArrivalsRepository(client: StubFetcher(predictions: [])),
            customRoute: nil,
            preferredPattern: nil
        )

        let eta = try await provider.estimate(
            from: location(naptanId: nil, routingCoordinate: nil),
            to: location(naptanId: nil, routingCoordinate: nil),
            departing: now
        )

        #expect(eta.totalMinutes == 35)
    }

    @Test func usesLiveArrivalWhenNaptanIdResolved() async throws {
        let prediction = TfLPrediction(
            vehicleId: "V1",
            naptanId: "940GZZLUHY",
            lineName: "Victoria",
            modeName: "tube",
            stationName: "Highbury & Islington",
            destinationName: "Walthamstow Central",
            timeToStation: 300
        )
        let fallback = StubETAProvider(eta: CommuteETA(totalMinutes: 99, steps: [], disruption: .onTime, disruptionMessage: nil))
        let provider = TfLETAProvider(
            fallback: fallback,
            repository: ArrivalsRepository(client: StubFetcher(predictions: [prediction])),
            customRoute: nil,
            preferredPattern: nil
        )

        let eta = try await provider.estimate(
            from: location(naptanId: "940GZZLUHY", routingCoordinate: CLLocationCoordinate2D(latitude: 51.538, longitude: -0.104)),
            to: location(naptanId: nil, routingCoordinate: nil),
            departing: now
        )

        #expect(eta.totalMinutes != 99)
        #expect(eta.disruption == .onTime)
        #expect(eta.steps.contains { $0.label.contains("Victoria") })
    }
}
