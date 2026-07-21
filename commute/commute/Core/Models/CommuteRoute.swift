import Foundation

/// A leg of a journey — how the user gets from one point to the next.
enum LegKind: String, Codable, CaseIterable, Hashable {
    case walk
    case bus
    case tube
    case rail
    case cycle

    var systemImage: String {
        switch self {
        case .walk: "figure.walk"
        case .bus: "bus.fill"
        case .tube: "tram.fill"
        case .rail: "train.side.front.car"
        case .cycle: "bicycle"
        }
    }

    var displayLabel: String {
        switch self {
        case .walk: "Walk"
        case .bus: "Bus"
        case .tube: "Tube"
        case .rail: "Rail"
        case .cycle: "Cycle"
        }
    }
}

/// A resolved, human-readable summary of a route — what the user actually sees.
struct CommuteRoute: Codable, Hashable {
    var summary: String
}

/// The user's usual route pattern, learned or set manually, used as a fallback
/// ranking hint when live routing isn't available.
struct CommutePattern: Codable, Hashable {
    var legKinds: [LegKind]
    var lineLabels: [String]
}

/// A route the user has built and pinned themselves in the commute builder.
struct CustomCommuteRoute: Codable, Hashable {
    struct Step: Codable, Hashable, Identifiable {
        var id: UUID = UUID()
        var mode: LegKind
        var summary: String
        var estimatedMinutes: Int
    }

    var steps: [Step]

    var isValid: Bool { !steps.isEmpty }

    var totalEstimatedMinutes: Int {
        steps.reduce(0) { $0 + $1.estimatedMinutes }
    }

    func toRoute() -> CommuteRoute {
        CommuteRoute(summary: steps.map(\.summary).joined(separator: " → "))
    }
}
