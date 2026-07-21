import Foundation
import SwiftUI

struct Route: Identifiable, Equatable, Hashable {
    let id: UUID
    let summary: String
    let totalMinutes: Int
    let legs: [RouteLeg]
    let status: LineStatus
    /// Other lines that serve the exact same stop sequence as the transit leg at a given index,
    /// e.g. two bus routes that share every stop between the same boarding and alighting points.
    var groupedAlternatives: [Int: [TransitLineOption]]

    init(
        id: UUID = UUID(),
        summary: String,
        totalMinutes: Int,
        legs: [RouteLeg],
        status: LineStatus,
        groupedAlternatives: [Int: [TransitLineOption]] = [:]
    ) {
        self.id = id
        self.summary = summary
        self.totalMinutes = totalMinutes
        self.legs = legs
        self.status = status
        self.groupedAlternatives = groupedAlternatives
    }

    var transitLines: [TfLLine] {
        legs.compactMap { leg in
            guard case .transit(let line, _, _, _, _, _, _) = leg else { return nil }
            return line
        }
    }

    var signature: String {
        legs.map { leg in
            switch leg {
            case .walk:
                return "walk"
            case .transit(let line, _, _, _, _, _, let label):
                return label ?? line.rawValue
            }
        }
        .joined(separator: "→")
    }

    enum LineStatus: Equatable, Hashable {
        case goodService
        case minorDelays
        case severeDelays
        case suspended
        case unknown
    }
}

struct TransitLineOption: Equatable, Hashable {
    let line: TfLLine
    let lineLabel: String?
    let departureTime: String
    let platform: String?
}

enum RouteLeg: Equatable, Hashable {
    case walk(minutes: Int, distanceMiles: Double)
    case transit(
        line: TfLLine,
        from: String,
        to: String,
        departureTime: String,
        platform: String?,
        stops: Int,
        lineLabel: String? = nil
    )
}

extension Route.LineStatus {
    var isOnTime: Bool {
        switch self {
        case .goodService: true
        case .minorDelays, .severeDelays, .suspended, .unknown: false
        }
    }

    var displayLabel: String {
        switch self {
        case .goodService: "Good service"
        case .minorDelays: "Minor delays"
        case .severeDelays: "Severe delays"
        case .suspended: "Suspended"
        case .unknown: "Status unknown"
        }
    }

    var themeColor: Color {
        switch self {
        case .goodService: Theme.Colors.statusGood
        case .minorDelays: Theme.Colors.statusWarning
        case .severeDelays, .suspended: Theme.Colors.statusDisrupted
        case .unknown: Theme.Colors.textSecondary
        }
    }

    var disruptionPriority: Int {
        switch self {
        case .goodService: 0
        case .unknown: 1
        case .minorDelays: 2
        case .severeDelays: 3
        case .suspended: 4
        }
    }

    var disruptionDotColor: Color {
        switch self {
        case .minorDelays, .unknown: Theme.Colors.statusWarning
        case .severeDelays, .suspended: Theme.Colors.statusDisrupted
        case .goodService: .clear
        }
    }
}
