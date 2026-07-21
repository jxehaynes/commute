import ActivityKit
import Foundation

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

/// Live service condition for the current route.
public enum DisruptionLevel: String, Codable, Hashable, Sendable {
    case onTime
    case minor
    case severe
}

/// Where the Live Activity currently is in the commute lifecycle.
public enum CommutePhase: String, Codable, Hashable, Sendable {
    /// Pre-departure disruption warning before the normal countdown window.
    case disruptionAlert
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
        public var alertLineName: String?
        public var phase: CommutePhase

        public init(
            leaveByDate: Date,
            arriveByDate: Date,
            etaMinutes: Int,
            routeSteps: [RouteStepSummary],
            disruption: DisruptionLevel,
            disruptionMessage: String? = nil,
            alertLineName: String? = nil,
            phase: CommutePhase
        ) {
            self.leaveByDate = leaveByDate
            self.arriveByDate = arriveByDate
            self.etaMinutes = etaMinutes
            self.routeSteps = routeSteps
            self.disruption = disruption
            self.disruptionMessage = disruptionMessage
            self.alertLineName = alertLineName
            self.phase = phase
        }
    }

    public var destinationLabel: String
    public var destinationIcon: String
    public var accent: LiveActivityAccent

    public init(destinationLabel: String, destinationIcon: String, accent: LiveActivityAccent) {
        self.destinationLabel = destinationLabel
        self.destinationIcon = destinationIcon
        self.accent = accent
    }
}
