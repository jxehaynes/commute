import Combine
import CoreLocation
import Foundation
import MapKit

struct LocationSearchSuggestion: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let subtitle: String

    init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
        id = "\(title)|\(subtitle)"
    }

    var displayAddress: String {
        subtitle.isEmpty ? title : "\(title), \(subtitle)"
    }

    var searchQuery: String {
        subtitle.isEmpty ? title : "\(title) \(subtitle)"
    }
}

struct ResolvedLocationSearchResult: Equatable {
    let suggestion: LocationSearchSuggestion
    let coordinate: CLLocationCoordinate2D
    let formattedAddress: String
}

@MainActor
protocol LocationSearchProviding {
    func suggestions(for query: String) async throws -> [LocationSearchSuggestion]
    func resolve(_ suggestion: LocationSearchSuggestion) async throws -> ResolvedLocationSearchResult
}

enum LocationSearchProviderFactory {
    @MainActor
    static func provider(for mapsProvider: UserProfile.MapsProvider) -> any LocationSearchProviding {
        switch mapsProvider {
        case .apple:
            AppleLocationSearchProvider()
        case .google:
            UnavailableLocationSearchProvider(providerName: mapsProvider.displayName)
        case .openStreetMap:
            UnavailableLocationSearchProvider(providerName: mapsProvider.displayName)
        }
    }
}

@MainActor
final class LocationSearchViewModel: ObservableObject {
    @Published private(set) var suggestions: [LocationSearchSuggestion] = []
    @Published private(set) var isSearching = false

    private var provider: any LocationSearchProviding
    private var searchTask: Task<Void, Never>?

    init(provider: (any LocationSearchProviding)? = nil) {
        self.provider = provider ?? AppleLocationSearchProvider()
    }

    deinit {
        searchTask?.cancel()
    }

    func updateQuery(_ query: String) {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            suggestions = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task { [provider] in
            do {
                try await Task.sleep(for: .milliseconds(250))
                let results = try await provider.suggestions(for: trimmed)
                guard !Task.isCancelled else { return }
                suggestions = results
                isSearching = false
            } catch {
                guard !Task.isCancelled else { return }
                suggestions = []
                isSearching = false
            }
        }
    }

    func useProvider(for mapsProvider: UserProfile.MapsProvider) {
        searchTask?.cancel()
        provider = LocationSearchProviderFactory.provider(for: mapsProvider)
        suggestions = []
        isSearching = false
    }

    func clear() {
        searchTask?.cancel()
        suggestions = []
        isSearching = false
    }

    func resolve(_ suggestion: LocationSearchSuggestion) async -> ResolvedLocationSearchResult? {
        try? await provider.resolve(suggestion)
    }
}

@MainActor
struct UnavailableLocationSearchProvider: LocationSearchProviding {
    let providerName: String

    func suggestions(for query: String) async throws -> [LocationSearchSuggestion] {
        []
    }

    func resolve(_ suggestion: LocationSearchSuggestion) async throws -> ResolvedLocationSearchResult {
        throw LocationSearchError.providerUnavailable(providerName)
    }
}

@MainActor
final class AppleLocationSearchProvider: NSObject, LocationSearchProviding {
    private let completer = MKLocalSearchCompleter()
    private var continuation: CheckedContinuation<[LocationSearchSuggestion], Error>?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        completer.region = Self.londonRegion
    }

    func suggestions(for query: String) async throws -> [LocationSearchSuggestion] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

        continuation?.resume(returning: [])
        continuation = nil

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            completer.queryFragment = query
        }
    }

    func resolve(_ suggestion: LocationSearchSuggestion) async throws -> ResolvedLocationSearchResult {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = suggestion.searchQuery
        request.region = Self.londonRegion

        let response = try await MKLocalSearch(request: request).start()
        guard let item = response.mapItems.first else {
            throw LocationSearchError.noMatch
        }
        let coordinate = await Self.bestCoordinate(
            for: suggestion.searchQuery,
            mapItemCoordinate: item.placemark.coordinate
        )

        return ResolvedLocationSearchResult(
            suggestion: suggestion,
            coordinate: coordinate,
            formattedAddress: Self.formattedAddress(for: item, fallback: suggestion.displayAddress)
        )
    }

    private static let londonRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
        span: MKCoordinateSpan(latitudeDelta: 0.7, longitudeDelta: 0.9)
    )

    private static func formattedAddress(for item: MKMapItem, fallback: String) -> String {
        let placemark = item.placemark
        let parts = [
            placemark.name,
            placemark.thoroughfare,
            placemark.locality,
            placemark.postalCode
        ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return parts.isEmpty ? fallback : parts.removingDuplicates().joined(separator: ", ")
    }

    private static func bestCoordinate(
        for query: String,
        mapItemCoordinate: CLLocationCoordinate2D
    ) async -> CLLocationCoordinate2D {
        let geocoder = CLGeocoder()
        guard let placemarks = try? await geocoder.geocodeAddressString(query),
              let location = placemarks.first?.location else {
            return mapItemCoordinate
        }

        let mapLocation = CLLocation(
            latitude: mapItemCoordinate.latitude,
            longitude: mapItemCoordinate.longitude
        )
        let distance = mapLocation.distance(from: location)

        guard distance < 200 else {
            return mapItemCoordinate
        }

        return location.coordinate
    }
}

extension AppleLocationSearchProvider: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            let suggestions = completer.results.map {
                LocationSearchSuggestion(title: $0.title, subtitle: $0.subtitle)
            }
            continuation?.resume(returning: suggestions)
            continuation = nil
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}

private enum LocationSearchError: Error {
    case noMatch
    case providerUnavailable(String)
}

private extension Array where Element == String {
    func removingDuplicates() -> [String] {
        var seen: Set<String> = []
        return filter { seen.insert($0).inserted }
    }
}
