import CommuteKit
import Foundation

/// Everything set during onboarding and editable afterwards in Settings.
struct UserProfile: Codable, Hashable {
    enum MapsProvider: String, Codable, CaseIterable {
        case apple
        case google
        case citymapper

        /// Whether this provider currently supports in-app address search.
        var isLocationSearchEnabled: Bool {
            switch self {
            case .apple: true
            case .google, .citymapper: false
            }
        }
    }

    var firstName: String = ""
    var accent: AccentStyle = .indigo
    var locations: [SavedLocation] = []
    var commuteSchedule: CommuteSchedule = .default
    var customCommuteRoute: CustomCommuteRoute?
    var preferredCommutePattern: CommutePattern?
    var mapsProvider: MapsProvider = .apple
    var enablePaceLearning: Bool = false
    var enableLiveActivities: Bool = true

    func location(labeled label: SavedLocation.LocationLabel) -> SavedLocation? {
        locations.first { $0.label == label }
    }
}
