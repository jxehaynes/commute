import SwiftUI

struct DestinationConflictPicker: View {
    let destinations: [SavedLocation]
    let accent: AccentStyle
    let onSelect: (SavedLocation) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Where are you headed?")
                .font(Theme.Fonts.bodyEmphasis)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("A few places match your schedule right now.")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)

            VStack(spacing: 10) {
                ForEach(destinations) { destination in
                    Button {
                        onSelect(destination)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: icon(for: destination.label))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(accent.tintColor)
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(destination.displayName)
                                    .font(Theme.Fonts.bodyEmphasis)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Text(destination.schedule.summaryText)
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }

                            Spacer(minLength: 8)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        .padding(14)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Theme.Colors.backgroundSurface)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, OnboardingMetrics.horizontalPadding)
    }

    private func icon(for label: SavedLocation.LocationLabel) -> String {
        switch label {
        case .home: "house.fill"
        case .work: "briefcase.fill"
        case .other: "star.fill"
        }
    }
}
