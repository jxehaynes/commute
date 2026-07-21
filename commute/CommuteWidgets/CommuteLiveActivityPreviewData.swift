import CommuteKit
import Foundation

extension CommuteLiveActivityAttributes {
    static var preview: CommuteLiveActivityAttributes {
        CommuteLiveActivityAttributes(
            destinationLabel: "Work",
            destinationIcon: "briefcase.fill",
            accent: LiveActivityAccent(tintHex: "#5856D6", secondaryHex: "#7A79E8")
        )
    }
}

extension CommuteLiveActivityAttributes.ContentState {
    private static let steps = [
        RouteStepSummary(icon: "figure.walk", label: "Walk"),
        RouteStepSummary(icon: "tram.fill", label: "Elizabeth line"),
        RouteStepSummary(icon: "bus.fill", label: "14 bus"),
    ]

    static var previewCountdown: Self {
        .init(
            leaveByDate: .now.addingTimeInterval(18 * 60),
            arriveByDate: .now.addingTimeInterval(53 * 60),
            etaMinutes: 32,
            routeSteps: steps,
            disruption: .onTime,
            phase: .countdown
        )
    }

    static var previewDisruptionAlert: Self {
        .init(
            leaveByDate: .now.addingTimeInterval(45 * 60),
            arriveByDate: .now.addingTimeInterval(80 * 60),
            etaMinutes: 35,
            routeSteps: steps,
            disruption: .severe,
            disruptionMessage: "Severe delays",
            alertLineName: "Elizabeth line",
            phase: .disruptionAlert
        )
    }

    static var previewLeaveNow: Self {
        .init(
            leaveByDate: .now.addingTimeInterval(-30),
            arriveByDate: .now.addingTimeInterval(32 * 60),
            etaMinutes: 32,
            routeSteps: steps,
            disruption: .minor,
            disruptionMessage: "Minor delays on the Elizabeth line",
            phase: .leaveNow
        )
    }

    static var previewEnRoute: Self {
        .init(
            leaveByDate: .now.addingTimeInterval(-10 * 60),
            arriveByDate: .now.addingTimeInterval(18 * 60),
            etaMinutes: 32,
            routeSteps: steps,
            disruption: .onTime,
            phase: .enRoute
        )
    }
}
