import Foundation
import Testing
@testable import commute

struct TfLArrivalsClientTests {
    @Test func decodesSampleTfLResponse() throws {
        let json = """
        [
            {
                "vehicleId": "BUS1",
                "naptanId": "490000173C",
                "lineName": "43",
                "modeName": "bus",
                "stationName": "Highbury Corner",
                "destinationName": "Friern Barnet",
                "timeToStation": 180
            },
            {
                "vehicleId": "TUBE1",
                "naptanId": "940GZZLUHY",
                "lineName": "Victoria",
                "modeName": "tube",
                "stationName": "Highbury & Islington Underground Station",
                "destinationName": "Walthamstow Central",
                "timeToStation": 90
            }
        ]
        """.data(using: .utf8)!

        let predictions = try JSONDecoder().decode([TfLPrediction].self, from: json)

        #expect(predictions.count == 2)
        #expect(predictions[0].lineName == "43")
        #expect(predictions[0].timeToStation == 180)
        #expect(predictions[1].modeName == "tube")
    }
}
