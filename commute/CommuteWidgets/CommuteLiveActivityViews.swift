import CommuteKit
import SwiftUI

typealias CommuteContentState = CommuteLiveActivityAttributes.ContentState

/// A circular gradient icon badge — the same motif `AccentGradientCircle`
/// uses in Settings, reused here for the next transport mode / destination.
struct ModeGradientBadge: View {
    var systemImage: String
    var gradient: LinearGradient
    var diameter: CGFloat = Theme.Metrics.badgeDiameter
    var iconSize: CGFloat = 14

    var body: some View {
        ZStack {
            Circle().fill(gradient)
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: diameter, height: diameter)
    }
}

/// "Leave for **Work**" — plain leading text with a serif-accented destination,
/// mirroring the app's `OnboardingHeadline` treatment.
struct DestinationHeadline: View {
    var phase: CommutePhase
    var destinationLabel: String

    private var leadingText: String {
        switch phase {
        case .countdown: "Leave for "
        case .leaveNow: "Time to leave for "
        case .enRoute: "On the way to "
        case .arrived: "Arrived at "
        }
    }

    var body: some View {
        (Text(leadingText).font(Theme.Fonts.headline)
            + Text(destinationLabel).font(Theme.Fonts.serifAccent))
            .foregroundStyle(Theme.Colors.textPrimary)
    }
}

/// The big phase-aware countdown/ETA figure. Uses `Text(timerInterval:)` so it
/// ticks live on the Lock Screen and Dynamic Island without any activity update.
struct CommuteCountdownText: View {
    var state: CommuteContentState
    var accent: AccentStyle
    /// Callers size this for their slot (Lock Screen vs. the ~44pt-wide
    /// Dynamic Island compact region) — only color/content vary by phase.
    var font: Font = .system(size: 32, weight: .bold, design: .rounded)

    var body: some View {
        content
            .font(font)
            .monospacedDigit()
    }

    @ViewBuilder
    private var content: some View {
        switch state.phase {
        case .countdown:
            Text(timerInterval: Date.now...safeUpperBound(state.leaveByDate), countsDown: true)
                .foregroundStyle(Theme.Colors.textPrimary)
        case .leaveNow:
            Text("Time to go")
                .foregroundStyle(accent.tintColor)
        case .enRoute:
            Text(timerInterval: Date.now...safeUpperBound(state.arriveByDate), countsDown: true)
                .foregroundStyle(Theme.Colors.textPrimary)
        case .arrived:
            Text("Arrived")
                .foregroundStyle(Theme.Colors.statusOnTime)
        }
    }

    private func safeUpperBound(_ date: Date) -> Date {
        max(date, Date.now.addingTimeInterval(1))
    }
}

/// A slim, natively-ticking progress capsule: fills up across the pre-departure
/// window, then across the journey itself once en route.
struct LeaveProgressBar: View {
    var state: CommuteContentState
    var accent: AccentStyle

    private var windowStart: Date {
        state.leaveByDate.addingTimeInterval(-30 * 60)
    }

    var body: some View {
        Group {
            switch state.phase {
            case .countdown where state.leaveByDate > windowStart:
                ProgressView(timerInterval: windowStart...state.leaveByDate, countsDown: false)
            case .enRoute where state.arriveByDate > state.leaveByDate:
                ProgressView(timerInterval: state.leaveByDate...state.arriveByDate, countsDown: false)
            default:
                ProgressView(value: 1)
            }
        }
        .labelsHidden()
        .progressViewStyle(.linear)
        .tint(accent.tintColor)
    }
}

/// Route step chips connected by small chevrons, e.g. Walk → District line → Bus.
struct RouteStepStrip: View {
    var steps: [RouteStepSummary]
    var accent: AccentStyle

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(spacing: 4) {
                    Image(systemName: step.icon)
                        .font(.system(size: 11, weight: .semibold))
                    Text(step.label)
                        .font(Theme.Fonts.caption)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Capsule().fill(accent.softBackground()))
                .foregroundStyle(Theme.Colors.textPrimary)

                if index < steps.count - 1 {
                    Image(systemName: "chevron.compact.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
    }
}

/// Colored status dot + service message, plus a trailing detail (arrival time).
struct StatusLine: View {
    var disruption: DisruptionLevel
    var message: String?
    var trailingText: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(disruption.statusColor)
                .frame(width: 6, height: 6)
            Text(message ?? disruption.defaultMessage)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer(minLength: 8)
            Text(trailingText)
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }
}

func arrivalTimeText(_ date: Date) -> String {
    "Arrive by \(date.formatted(date: .omitted, time: .shortened))"
}
