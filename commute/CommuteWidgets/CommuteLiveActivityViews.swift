import CommuteKit
import SwiftUI

typealias CommuteContentState = CommuteLiveActivityAttributes.ContentState

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

struct DestinationHeadline: View {
    var phase: CommutePhase
    var destinationLabel: String
    var alertLineName: String?

    private var leadingText: String {
        switch phase {
        case .disruptionAlert:
            if let alertLineName {
                return "Disruption on the \(alertLineName)"
            }
            return "Disruption on your route"
        case .countdown:
            return "Leave for "
        case .leaveNow:
            return "Time to leave for "
        case .enRoute:
            return "On the way to "
        case .arrived:
            return "Arrived at "
        }
    }

    var body: some View {
        Group {
            if phase == .disruptionAlert {
                Text(leadingText)
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(Theme.Colors.textPrimary)
            } else {
                (Text(leadingText).font(Theme.Fonts.headline)
                    + Text(destinationLabel).font(Theme.Fonts.serifAccent))
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
        }
    }
}

struct CommuteCountdownText: View {
    var state: CommuteContentState
    var accent: LiveActivityAccent
    var font: Font = .system(size: 32, weight: .bold, design: .rounded)

    var body: some View {
        content
            .font(font)
            .monospacedDigit()
    }

    @ViewBuilder
    private var content: some View {
        switch state.phase {
        case .disruptionAlert:
            Text("Check Commute to change route")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(accent.tintColor)
                .multilineTextAlignment(.trailing)
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

struct LeaveProgressBar: View {
    var state: CommuteContentState
    var accent: LiveActivityAccent

    private var windowStart: Date {
        state.leaveByDate.addingTimeInterval(-30 * 60)
    }

    var body: some View {
        Group {
            switch state.phase {
            case .disruptionAlert:
                ProgressView(value: 0)
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

struct RouteStepStrip: View {
    var steps: [RouteStepSummary]
    var accent: LiveActivityAccent

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

struct StatusLine: View {
    var disruption: DisruptionLevel
    var message: String?
    var trailingText: String

    private var statusColor: Color {
        switch disruption {
        case .onTime: Theme.Colors.statusOnTime
        case .minor: Theme.Colors.statusWarning
        case .severe: Theme.Colors.statusDisrupted
        }
    }

    private var defaultMessage: String {
        switch disruption {
        case .onTime: "Good service"
        case .minor: "Minor delays"
        case .severe: "Severe delays"
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            Text(message ?? defaultMessage)
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
