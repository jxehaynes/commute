import ActivityKit
import CommuteKit
import SwiftUI
import WidgetKit

struct CommuteLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CommuteLiveActivityAttributes.self) { context in
            CommuteLockScreenView(
                attributes: context.attributes,
                state: context.state
            )
            .activityBackgroundTint(Theme.Colors.backgroundSurface)
            .activitySystemActionForegroundColor(Theme.Colors.textPrimary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        ModeGradientBadge(
                            systemImage: context.attributes.destinationIcon,
                            gradient: context.attributes.accent.gradient,
                            diameter: 28,
                            iconSize: 12
                        )
                        if context.state.phase == .disruptionAlert {
                            Text(context.state.alertLineName.map { "Disruption on \($0)" } ?? "Route disruption")
                                .font(Theme.Fonts.serifAccent)
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .lineLimit(2)
                        } else {
                            Text(context.attributes.destinationLabel)
                                .font(Theme.Fonts.serifAccent)
                                .foregroundStyle(Theme.Colors.textPrimary)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    CommuteCountdownText(
                        state: context.state,
                        accent: context.attributes.accent,
                        font: .system(size: 20, weight: .bold, design: .rounded)
                    )
                    .multilineTextAlignment(.trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        if context.state.phase != .disruptionAlert, !context.state.routeSteps.isEmpty {
                            RouteStepStrip(steps: context.state.routeSteps, accent: context.attributes.accent)
                        }
                        StatusLine(
                            disruption: context.state.disruption,
                            message: context.state.disruptionMessage,
                            trailingText: context.state.phase == .disruptionAlert
                                ? "Check Commute to change route"
                                : arrivalTimeText(context.state.arriveByDate)
                        )
                        if context.state.phase != .disruptionAlert {
                            LeaveProgressBar(state: context.state, accent: context.attributes.accent)
                        }
                    }
                }
            } compactLeading: {
                ModeGradientBadge(
                    systemImage: context.state.phase == .disruptionAlert ? "exclamationmark.triangle.fill" : context.attributes.destinationIcon,
                    gradient: context.attributes.accent.gradient,
                    diameter: 20,
                    iconSize: 10
                )
            } compactTrailing: {
                CommuteCountdownText(
                    state: context.state,
                    accent: context.attributes.accent,
                    font: .system(size: 14, weight: .semibold, design: .rounded)
                )
                .frame(maxWidth: 44)
            } minimal: {
                ModeGradientBadge(
                    systemImage: context.state.phase == .disruptionAlert ? "exclamationmark.triangle.fill" : context.attributes.destinationIcon,
                    gradient: context.attributes.accent.gradient,
                    diameter: 18,
                    iconSize: 9
                )
            }
            .widgetURL(URL(string: "commute://home"))
            .keylineTint(context.attributes.accent.tintColor)
        }
    }
}

private struct CommuteLockScreenView: View {
    var attributes: CommuteLiveActivityAttributes
    var state: CommuteContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ModeGradientBadge(
                    systemImage: state.phase == .disruptionAlert ? "exclamationmark.triangle.fill" : nextStepIcon,
                    gradient: attributes.accent.gradient
                )

                VStack(alignment: .leading, spacing: 2) {
                    DestinationHeadline(
                        phase: state.phase,
                        destinationLabel: attributes.destinationLabel,
                        alertLineName: state.alertLineName
                    )
                    if state.phase == .disruptionAlert {
                        Text("Check Commute to change route")
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    } else {
                        Text(arrivalTimeText(state.arriveByDate))
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }

                Spacer(minLength: 8)

                if state.phase != .disruptionAlert {
                    CommuteCountdownText(state: state, accent: attributes.accent)
                }
            }

            if state.phase != .disruptionAlert, !state.routeSteps.isEmpty {
                RouteStepStrip(steps: state.routeSteps, accent: attributes.accent)
            }

            StatusLine(
                disruption: state.disruption,
                message: state.disruptionMessage,
                trailingText: state.phase == .disruptionAlert
                    ? ""
                    : "\(state.etaMinutes) min journey"
            )

            if state.phase != .disruptionAlert {
                LeaveProgressBar(state: state, accent: attributes.accent)
            }
        }
        .padding(16)
        .widgetURL(URL(string: "commute://home"))
    }

    private var nextStepIcon: String {
        state.routeSteps.first?.icon ?? attributes.destinationIcon
    }
}

#Preview("Countdown", as: .content, using: CommuteLiveActivityAttributes.preview) {
    CommuteLiveActivityWidget()
} contentStates: {
    CommuteLiveActivityAttributes.ContentState.previewCountdown
}

#Preview("Disruption alert", as: .content, using: CommuteLiveActivityAttributes.preview) {
    CommuteLiveActivityWidget()
} contentStates: {
    CommuteLiveActivityAttributes.ContentState.previewDisruptionAlert
}

#Preview("Leave now", as: .content, using: CommuteLiveActivityAttributes.preview) {
    CommuteLiveActivityWidget()
} contentStates: {
    CommuteLiveActivityAttributes.ContentState.previewLeaveNow
}

#Preview("En route", as: .content, using: CommuteLiveActivityAttributes.preview) {
    CommuteLiveActivityWidget()
} contentStates: {
    CommuteLiveActivityAttributes.ContentState.previewEnRoute
}
