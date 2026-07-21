import SwiftUI

struct ActiveCommuteCard: View {
    let route: Route
    let destinationLabel: String
    let minutesUntilLeave: Int?
    let leaveByTime: String?
    let accent: AccentStyle
    var lineDisruptions: [Disruption] = []
    var statusLastUpdated: Date?

    @State private var isExpanded = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var expandAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.82)
    }

    var body: some View {
        Button(action: toggleExpansion) {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, isExpanded ? 16 : 20)

                if isExpanded {
                    Divider()
                        .padding(.horizontal, 20)

                    CommuteStepTimeline(legs: route.legs, destinationLabel: destinationLabel)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .opacity.combined(with: .move(edge: .top))
                        )
                }

                RouteStatusPill(
                    status: route.status,
                    disruptions: lineDisruptions,
                    lastUpdated: statusLastUpdated,
                    isInteractive: false,
                    isExpanded: isExpanded
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Theme.Colors.backgroundSurface)
                .shadow(color: .black.opacity(0.1), radius: 16, y: 6)
                .accentGradientBorder(accent: accent, cornerRadius: 20, lineWidth: 2, isActive: true)
        }
        .accessibilityHint(isExpanded ? "Collapse route details" : "Expand route details")
    }

    private func toggleExpansion() {
        withAnimation(expandAnimation) {
            isExpanded.toggle()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let minutesUntilLeave {
                leaveHeadline(minutes: minutesUntilLeave)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(route.totalMinutes)")
                    .font(.playfairItalic(size: 36))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .monospacedDigit()
                Text("min journey to \(destinationLabel)")
                    .font(Theme.Fonts.routeSummary)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Text(route.summary)
                .font(Theme.Fonts.secondary)
                .foregroundStyle(Theme.Colors.textSecondary)

            if let leaveByTime {
                Text("Leave by \(leaveByTime)")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func leaveHeadline(minutes: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text("Leave in")
                .font(Theme.Fonts.routeSummary)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(leaveDurationLabel(minutes))
                .font(.playfairItalic(size: 34))
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }

    private func leaveDurationLabel(_ minutes: Int) -> String {
        if minutes == 0 { return "now" }
        if minutes == 1 { return "1 min" }
        if minutes < 60 { return "\(minutes) mins" }
        let hours = minutes / 60
        let remainder = minutes % 60
        if remainder == 0 { return hours == 1 ? "1 hour" : "\(hours) hours" }
        return "\(hours)h \(remainder)m"
    }
}
