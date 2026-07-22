import SwiftUI

struct RouteStatusPill: View {
    let status: Route.LineStatus
    let disruptions: [Disruption]
    let lastUpdated: Date?
    var isInteractive: Bool = true
    var isExpanded: Bool = false
    /// True when the most recent disruption check failed — shows "Status unavailable" rather
    /// than implying confirmed good service off stale or default data.
    var isUnavailable: Bool = false

    @State private var internalExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let animation = Animation.spring(response: 0.34, dampingFraction: 0.82)

    private var showsExpanded: Bool {
        isInteractive ? internalExpanded : isExpanded
    }

    /// `status` reflects the route provider's own status (currently always `.goodService` —
    /// none of them compute real line status), so the actual severity comes from the real,
    /// per-route disruptions that were separately fetched and matched to this route's lines.
    /// Only falls back to `status` when there's no matching disruption to derive it from.
    private var effectiveStatus: Route.LineStatus {
        disruptions.map(\.severity).max { $0.disruptionPriority < $1.disruptionPriority } ?? status
    }

    private var displayLabel: String {
        isUnavailable ? "Status unavailable" : effectiveStatus.displayLabel
    }

    private var displayColor: Color {
        isUnavailable ? Theme.Colors.textSecondary : effectiveStatus.themeColor
    }

    var body: some View {
        Group {
            if isInteractive {
                Button(action: toggleExpansion) {
                    pillContent
                }
                .buttonStyle(.plain)
            } else {
                pillContent
            }
        }
        .accessibilityLabel(displayLabel)
        .accessibilityHint(
            showsExpanded ? "Collapse service status" : "Expand service status details"
        )
    }

    private var pillContent: some View {
        Group {
            if showsExpanded {
                expandedContent
            } else {
                collapsedContent
            }
        }
        .frame(maxWidth: .infinity, alignment: showsExpanded ? .leading : .trailing)
    }

    private func toggleExpansion() {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : animation) {
            internalExpanded.toggle()
        }
    }

    private var collapsedContent: some View {
        Text(displayLabel)
            .font(Theme.Fonts.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(displayColor)
            .clipShape(Capsule())
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(displayLabel)
                .font(Theme.Fonts.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            if isUnavailable {
                Text("Couldn't check live status.")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(.white.opacity(0.85))
            } else if !disruptions.isEmpty {
                ForEach(disruptions) { disruption in
                    Text("\(disruption.line.displayName): \(disruption.statusLabel)")
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(.white.opacity(0.92))
                }
            } else if effectiveStatus != .goodService {
                Text("No further details available.")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }

            if let lastUpdated {
                Text("Last updated \(lastUpdated.relativeMinutesDescription)")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(displayColor)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private extension Date {
    var relativeMinutesDescription: String {
        let minutes = max(1, Int(Date().timeIntervalSince(self) / 60))
        if minutes == 1 { return "1 min ago" }
        return "\(minutes) mins ago"
    }
}

#Preview {
    VStack(spacing: 16) {
        RouteStatusPill(
            status: .goodService,
            disruptions: [],
            lastUpdated: Date().addingTimeInterval(-360)
        )
        RouteStatusPill(
            status: .minorDelays,
            disruptions: [
                Disruption(
                    line: .central,
                    severity: .minorDelays,
                    statusLabel: "Minor Delays",
                    reason: "Minor delays on the Central line."
                )
            ],
            lastUpdated: Date().addingTimeInterval(-360)
        )
    }
    .padding(18)
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 18))
    .padding()
}
