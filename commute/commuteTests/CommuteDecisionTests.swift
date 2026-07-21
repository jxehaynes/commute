import Foundation
import Testing
@testable import commute

struct CommuteDecisionTests {
    private let now = Date(timeIntervalSince1970: 0)

    private func arrival(id: String, lineName: String, minutesAway: Double) -> LiveArrival {
        let prediction = TfLPrediction(
            vehicleId: id,
            naptanId: "940GZZLUHY",
            lineName: lineName,
            modeName: "tube",
            stationName: "Test Station",
            destinationName: "Test Destination",
            timeToStation: Int(minutesAway * 60)
        )
        return LiveArrival(prediction: prediction, fetchedAt: now)
    }

    @Test func choosesSoonestCatchableArrival() {
        let arrivals = [arrival(id: "A", lineName: "Victoria", minutesAway: 4)]
        let result = CommuteDecision.choose(from: arrivals, walkMinutes: 3, now: now)

        #expect(result.chosen?.id == "A-Victoria")
        #expect(result.waitMinutes == 1)
        #expect(result.disruption == .onTime)
        #expect(result.disruptionMessage == nil)
    }

    @Test func flagsWhenAnEarlierArrivalWillBeMissed() {
        let arrivals = [
            arrival(id: "A", lineName: "Victoria", minutesAway: 2),
            arrival(id: "B", lineName: "Victoria", minutesAway: 9),
        ]
        let result = CommuteDecision.choose(from: arrivals, walkMinutes: 5, now: now)

        #expect(result.chosen?.id == "B-Victoria")
        #expect(result.disruption == .minor)
        #expect(result.disruptionMessage?.contains("2-min") == true)
    }

    @Test func reportsSevereWhenNothingIsCatchable() {
        let arrivals = [arrival(id: "A", lineName: "Victoria", minutesAway: 1)]
        let result = CommuteDecision.choose(from: arrivals, walkMinutes: 10, now: now)

        #expect(result.chosen == nil)
        #expect(result.disruption == .severe)
    }

    @Test func reportsSevereWhenNoPredictions() {
        let result = CommuteDecision.choose(from: [], walkMinutes: 5, now: now)

        #expect(result.chosen == nil)
        #expect(result.disruption == .severe)
    }
}
