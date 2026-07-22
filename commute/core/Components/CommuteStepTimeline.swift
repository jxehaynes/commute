import SwiftUI

struct CommuteStepTimeline: View {
    let legs: [RouteLeg]
    let destinationLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(legs.enumerated()), id: \.offset) { index, leg in
                CommuteStepRow(
                    leg: leg,
                    destinationLabel: destinationLabel,
                    isLast: index == legs.count - 1
                )
            }
        }
    }
}

private struct CommuteStepRow: View {
    let leg: RouteLeg
    let destinationLabel: String
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            timelineRail

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Fonts.bodyEmphasis)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let detail {
                    Text(detail)
                        .font(Theme.Fonts.secondary)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, isLast ? 0 : 18)
        }
    }

    private var timelineRail: some View {
        VStack(spacing: 0) {
            stepMarker
            if !isLast {
                Rectangle()
                    .fill(Theme.Colors.border.opacity(0.7))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
                    .padding(.vertical, 4)
            }
        }
        .frame(width: 28)
    }

    @ViewBuilder
    private var stepMarker: some View {
        switch leg {
        case .walk:
            Image(systemName: "figure.walk")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Theme.Colors.backgroundElevated))
        case .transit(let line, _, _, _, _, _, let lineLabel):
            TransitLineChipView(line: line, lineLabel: lineLabel)
                .frame(height: 28)
        }
    }

    private var title: String {
        switch leg {
        case .walk(let minutes, let distance):
            let miles = String(format: "%.1f", distance)
            if isLast {
                return "Walk \(minutes) min · \(miles) mi to \(destinationLabel)"
            }
            return "Walk \(minutes) min · \(miles) mi"
        case .transit(let line, let from, let to, let departureTime, _, _, let lineLabel):
            let name = lineLabel ?? "\(line.displayName) line"
            if let departureTime {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return "\(name) · \(formatter.string(from: departureTime)) · \(from) to \(to)"
            }
            return "\(name) · \(from) to \(to)"
        }
    }

    private var detail: String? {
        switch leg {
        case .walk(_, _):
            return nil
        case .transit(_, _, _, _, let platform, let stops, _):
            var parts: [String] = []
            if let platform { parts.append("Platform \(platform)") }
            parts.append("\(stops) stops")
            return parts.joined(separator: " · ")
        }
    }
}

#Preview {
    CommuteStepTimeline(
        legs: Route.mockRoutes(from: .mock(label: .home), to: .mock(label: .work)).first!.legs,
        destinationLabel: "Work"
    )
    .padding()
    .background(Color.white)
}
