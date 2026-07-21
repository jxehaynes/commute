import SwiftUI

struct HomeCurrentStatusView: View {
    let disruptions: [Disruption]
    let lastUpdated: Date?
    var topInset: CGFloat = 96
    var usesSolidBackground: Bool = true

    private let rowSpacing: CGFloat = 12

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: OnboardingMetrics.sectionSpacing) {
                header

                if disruptions.isEmpty {
                    goodServiceCard
                } else {
                    disruptionCard
                }
            }
            .padding(.horizontal, OnboardingMetrics.horizontalPadding)
            .padding(.trailing, 12)
            .padding(.top, topInset)
            .padding(.bottom, OnboardingMetrics.scrollBottomInset + 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(usesSolidBackground ? Theme.Colors.backgroundPrimary : Color.clear)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Status")
                .font(.playfairItalic(size: OnboardingMetrics.headlineSize))
                .foregroundStyle(Theme.Colors.textPrimary)

            TimelineView(.periodic(from: .now, by: 60)) { context in
                Text(queryStatusLabel(now: context.date))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Text("Swipe left to return home")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
    }

    private var goodServiceCard: some View {
        statusCard {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.Colors.statusGood)

                Text("Good service across TfL and National Rail.")
                    .font(Theme.Fonts.secondary)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var disruptionCard: some View {
        statusCard {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(disruptions.enumerated()), id: \.element.id) { index, disruption in
                    if index > 0 {
                        Divider()
                            .overlay(Theme.Colors.border.opacity(0.45))
                            .padding(.vertical, 4)
                    }

                    HStack(alignment: .center, spacing: rowSpacing) {
                        LineChipView(line: disruption.line)

                        Text(disruption.statusLabel)
                            .font(Theme.Fonts.secondary)
                            .fontWeight(.medium)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(disruption.line.displayName), \(disruption.statusLabel)")
                }
            }
        }
    }

    private func statusCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.Colors.backgroundSurface)
                    .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
            }
    }

    private func queryStatusLabel(now: Date) -> String {
        guard let lastUpdated else { return "Not yet queried" }

        let timeLabel = lastUpdated.formatted(date: .omitted, time: .shortened)
        let minutes = max(0, Int(now.timeIntervalSince(lastUpdated) / 60))

        if minutes == 0 {
            return "Queried at \(timeLabel) · just now"
        }
        if minutes == 1 {
            return "Queried at \(timeLabel) · 1 minute ago"
        }
        return "Queried at \(timeLabel) · \(minutes) minutes ago"
    }
}

#Preview("Disrupted") {
    HomeCurrentStatusView(
        disruptions: [
            Disruption(
                line: .central,
                severity: .minorDelays,
                statusLabel: "Minor Delays",
                reason: "Minor delays between Marble Arch and Liverpool Street."
            ),
            Disruption(
                line: .hammersmithAndCity,
                severity: .minorDelays,
                statusLabel: "Minor Delays",
                reason: "Minor delays on H&C."
            ),
            Disruption(
                line: .metropolitan,
                severity: .severeDelays,
                statusLabel: "Severe Delays",
                reason: "Severe delays on the Metropolitan line."
            )
        ],
        lastUpdated: Date().addingTimeInterval(-120)
    )
}

#Preview("Good service") {
    HomeCurrentStatusView(disruptions: [], lastUpdated: Date())
}
