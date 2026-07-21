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
                        Text(context.attributes.destinationLabel)
                            .font(Theme.Fonts.serifAccent)
                            .foregroundStyle(Theme.Colors.textPrimary)
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
                        RouteStepStrip(steps: context.state.routeSteps, accent: context.attributes.accent)
                        StatusLine(
                            disruption: context.state.disruption,
                            message: context.state.disruptionMessage,
                            trailingText: arrivalTimeText(context.state.arriveByDate)
                        )
                        LeaveProgressBar(state: context.state, accent: context.attributes.accent)
                    }
                }
            } compactLeading: {
                ModeGradientBadge(
                    systemImage: context.attributes.destinationIcon,
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
                    systemImage: context.attributes.destinationIcon,
                    gradient: context.attributes.accent.gradient,
                    diameter: 18,
                    iconSize: 9
                )
            }
            .widgetURL(nil)
            .keylineTint(context.attributes.accent.tintColor)
        }
    }
}

/// Lock Screen / notification banner presentation.
private struct CommuteLockScreenView: View {
    var attributes: CommuteLiveActivityAttributes
    var state: CommuteContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                ModeGradientBadge(
                    systemImage: nextStepIcon,
                    gradient: attributes.accent.gradient
                )

                VStack(alignment: .leading, spacing: 2) {
                    DestinationHeadline(phase: state.phase, destinationLabel: attributes.destinationLabel)
                    Text(arrivalTimeText(state.arriveByDate))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Spacer(minLength: 8)

                CommuteCountdownText(state: state, accent: attributes.accent)
            }

            if !state.routeSteps.isEmpty {
                RouteStepStrip(steps: state.routeSteps, accent: attributes.accent)
            }

            StatusLine(
                disruption: state.disruption,
                message: state.disruptionMessage,
                trailingText: "\(state.etaMinutes) min journey"
            )

            LeaveProgressBar(state: state, accent: attributes.accent)
        }
        .padding(16)
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

#Preview("Dynamic Island - expanded", as: .dynamicIsland(.expanded), using: CommuteLiveActivityAttributes.preview) {
    CommuteLiveActivityWidget()
} contentStates: {
    CommuteLiveActivityAttributes.ContentState.previewCountdown
    CommuteLiveActivityAttributes.ContentState.previewLeaveNow
}

#Preview("Dynamic Island - compact", as: .dynamicIsland(.compact), using: CommuteLiveActivityAttributes.preview) {
    CommuteLiveActivityWidget()
} contentStates: {
    CommuteLiveActivityAttributes.ContentState.previewCountdown
}
