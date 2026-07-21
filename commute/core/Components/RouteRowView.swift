import SwiftUI

struct RouteRowView: View {
    let route: Route
    let isExpanded: Bool
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(route.summary)
                        .font(Theme.Fonts.routeSummary)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    Text("\(route.totalMinutes) mins")
                        .font(Theme.Fonts.routeTime)
                        .monospacedDigit()
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                legIconStrip

                if isExpanded {
                    expandedContent
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .opacity.combined(with: .move(edge: .top))
                        )
                }
            }
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(route.summary), \(route.totalMinutes) minutes")
        .accessibilityHint(isExpanded ? "Collapse route details" : "Expand route details")
    }

    private var legIconStrip: some View {
        HStack(spacing: 8) {
            ForEach(Array(route.legs.enumerated()), id: \.offset) { index, leg in
                if index > 0 {
                    Text("→")
                        .font(Theme.Fonts.secondary)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                legView(leg)
            }
        }
    }

    @ViewBuilder
    private func legView(_ leg: RouteLeg) -> some View {
        switch leg {
        case .walk:
            Image(systemName: "figure.walk")
                .foregroundStyle(Theme.Colors.textSecondary)
                .accessibilityHidden(true)
        case .transit(let line, _, _, _, _, _, let lineLabel):
            TransitLineChipView(line: line, lineLabel: lineLabel)
        }
    }

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(route.legs.enumerated()), id: \.offset) { _, leg in
                switch leg {
                case .walk(let minutes, let distance):
                    Text("Walk \(minutes) min · \(String(format: "%.1f", distance)) mi")
                        .font(Theme.Fonts.journeyDetail)
                        .foregroundStyle(Theme.Colors.textPrimary)
                case .transit(let line, let from, let to, let time, let platform, let stops, let lineLabel):
                    Text("Departs \(from) at \(time)")
                        .font(Theme.Fonts.journeyDetail)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    if let platform {
                        Text("Platform \(platform)")
                            .font(Theme.Fonts.secondary)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    HStack(spacing: 8) {
                        TransitLineChipView(line: line, lineLabel: lineLabel)
                        Text("\(lineLabel ?? line.displayName) to \(to) · \(stops) stops")
                            .font(Theme.Fonts.journeyDetail)
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                    HStack(spacing: 6) {
                        Circle()
                            .fill(route.status.themeColor)
                            .frame(width: 8, height: 8)
                        Text(route.status.displayLabel)
                            .font(Theme.Fonts.secondary)
                            .foregroundStyle(route.status.themeColor)
                    }
                    HStack(spacing: 12) {
                        Text("Next: \(nextDeparture(after: time, offset: 3))")
                        Text("Next: \(nextDeparture(after: time, offset: 8))")
                    }
                    .font(Theme.Fonts.secondary)
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
    }

    private func nextDeparture(after time: String, offset: Int) -> String {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else {
            return time
        }
        let total = hour * 60 + minute + offset
        return String(format: "%02d:%02d", (total / 60) % 24, total % 60)
    }
}
