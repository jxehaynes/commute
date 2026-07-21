import ActivityKit
import SwiftUI

/// One step in the current route, e.g. "Walk" or "District line".
public struct RouteStepSummary: Codable, Hashable, Identifiable, Sendable {
    public var icon: String
    public var label: String

    public init(icon: String, label: String) {
        self.icon = icon
        self.label = label
    }

    public var id: String { icon + label }
}

/// Live service condition for the current route, mirrors the transit-style
/// severity used elsewhere in the app (`Theme.Colors.status*`).
public enum DisruptionLevel: String, Codable, Hashable, Sendable {
    case onTime
    case minor
    case severe

    public var statusColor: Color {
        switch self {
        case .onTime: Theme.Colors.statusOnTime
        case .minor: Theme.Colors.statusWarning
        case .severe: Theme.Colors.statusDisrupted
        }
    }

    public var defaultMessage: String {
        switch self {
        case .onTime: "Good service"
        case .minor: "Minor delays"
        case .severe: "Severe delays"
        }
    }
}

/// Where the Live Activity currently is in the commute lifecycle. Drives both
/// the countdown/ETA framing and the accent-to-urgency color shift.
public enum CommutePhase: String, Codable, Hashable, Sendable {
    /// More than 0 minutes until `leaveByDate` — calm countdown.
    case countdown
    /// `now >= leaveByDate` and the user hasn't set off yet — urgency emphasis.
    case leaveNow
    /// The user is expected to be travelling — shows ETA/progress instead of a countdown.
    case enRoute
    /// Past `arriveByDate` — the activity is about to end.
    case arrived
}

/// ActivityKit contract for the "time to leave" Live Activity.
public struct CommuteLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var leaveByDate: Date
        public var arriveByDate: Date
        public var etaMinutes: Int
        public var routeSteps: [RouteStepSummary]
        public var disruption: DisruptionLevel
        public var disruptionMessage: String?
        public var phase: CommutePhase

        public init(
            leaveByDate: Date,
            arriveByDate: Date,
            etaMinutes: Int,
            routeSteps: [RouteStepSummary],
            disruption: DisruptionLevel,
            disruptionMessage: String? = nil,
            phase: CommutePhase
        ) {
            self.leaveByDate = leaveByDate
            self.arriveByDate = arriveByDate
            self.etaMinutes = etaMinutes
            self.routeSteps = routeSteps
            self.disruption = disruption
            self.disruptionMessage = disruptionMessage
            self.phase = phase
        }
    }

    /// e.g. "Work" or "Home" — the fixed label for the whole life of the activity.
    public var destinationLabel: String
    public var destinationIcon: String
    public var accent: AccentStyle

    public init(destinationLabel: String, destinationIcon: String, accent: AccentStyle) {
        self.destinationLabel = destinationLabel
        self.destinationIcon = destinationIcon
        self.accent = accent
    }
}
