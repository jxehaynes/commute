import Foundation

/// Anything that can fetch live arrival predictions for a TfL stop. Lets
/// `ArrivalsRepository` be tested against a mock instead of the network.
protocol TfLArrivalsFetching: Sendable {
    func arrivals(naptanId: String) async throws -> [TfLPrediction]
}

/// One TfL "Prediction" from `StopPoint/{naptanId}/Arrivals` — only the
/// fields Commute actually uses.
struct TfLPrediction: Decodable, Sendable {
    var vehicleId: String
    var naptanId: String
    var lineName: String
    var modeName: String
    var stationName: String
    var destinationName: String
    /// Seconds until the vehicle reaches this stop, as of the response.
    var timeToStation: Int
}

enum TfLArrivalsClientError: Error {
    case invalidResponse
}

/// Talks to the TfL Unified API's live arrivals endpoint:
/// https://api.tfl.gov.uk/swagger/ui/index.html#!/StopPoint/StopPoint_ArrivalsId
///
/// Works unauthenticated but rate-limited; pass `appKey` (a free TfL API
/// registration, done by the user — not something this client can obtain on
/// its own) to raise the limit.
struct TfLArrivalsClient: TfLArrivalsFetching {
    var appKey: String?
    private let session: URLSession
    private let baseURL = URL(string: "https://api.tfl.gov.uk")!

    init(appKey: String? = nil, session: URLSession = .shared) {
        self.appKey = appKey
        self.session = session
    }

    nonisolated func arrivals(naptanId: String) async throws -> [TfLPrediction] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("StopPoint/\(naptanId)/Arrivals"),
            resolvingAgainstBaseURL: false
        )
        if let appKey, !appKey.isEmpty {
            components?.queryItems = [URLQueryItem(name: "app_key", value: appKey)]
        }
        guard let url = components?.url else { throw TfLArrivalsClientError.invalidResponse }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw TfLArrivalsClientError.invalidResponse
        }
        return try JSONDecoder().decode([TfLPrediction].self, from: data)
    }
}
