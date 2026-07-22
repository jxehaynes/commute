import SwiftUI

struct DirectionsView: View {
    let route: Route
    let destination: SavedLocation
    let firstName: String
    let accentStyle: AccentStyle

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headline
                routeOverview
                stepsList
            }
            .frame(maxWidth: OnboardingMetrics.contentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, OnboardingMetrics.horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
        .scrollIndicators(.hidden)
        .background {
            ZStack {
                accentStyle.tintColor.opacity(0.45).ignoresSafeArea()
                NeatGradientView(accentStyle: accentStyle, speed: 0.6, presentation: .immersive)
                    .ignoresSafeArea()
                AirTopAtmosphere(accent: accentStyle, strength: 0.28)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                }
                .accessibilityLabel("Back to journey options")
            }
        }
    }

    private var headline: some View {
        OnboardingHeadline(
            parts: [
                .serif(firstName.isEmpty ? "Your" : firstName),
                .plain(", step-by-step to "),
                .serif(destination.displayName),
                .plain(".")
            ],
            centered: true,
            foregroundColor: .white
        )
    }

    private var routeOverview: some View {
        VStack(spacing: 12) {
            Text(route.summary)
                .font(Theme.Fonts.routeSummary)
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity)

            HStack(spacing: 10) {
                ForEach(Array(route.legs.enumerated()), id: \.offset) { _, leg in
                    legChip(leg)
                }
            }

            Text("\(route.totalMinutes) mins total")
                .font(.playfairItalic(size: 28))
                .foregroundStyle(Theme.Colors.textPrimary)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.Colors.backgroundSurface)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        }
    }

    private var stepsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(route.legs.enumerated()), id: \.offset) { index, leg in
                stepRow(leg, index: index)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.Colors.backgroundSurface)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        }
    }

    @ViewBuilder
    private func legChip(_ leg: RouteLeg) -> some View {
        switch leg {
        case .walk:
            Image(systemName: "figure.walk")
                .foregroundStyle(Theme.Colors.textSecondary)
        case .transit(let line, _, _, _, _, _, let lineLabel):
            TransitLineChipView(line: line, lineLabel: lineLabel)
        }
    }

    @ViewBuilder
    private func stepRow(_ leg: RouteLeg, index: Int) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(index + 1)")
                .font(Theme.Fonts.lineChip)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(accentStyle.tintColor))

            switch leg {
            case .walk(let minutes, let distance):
                VStack(alignment: .leading, spacing: 4) {
                    Text("Walk · \(minutes) min")
                        .font(Theme.Fonts.bodyEmphasis)
                    Text(String(format: "%.1f miles", distance))
                        .font(Theme.Fonts.secondary)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            case .transit(let line, let from, let to, let departureTime, let platform, let stops, let lineLabel):
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        TransitLineChipView(line: line, lineLabel: lineLabel)
                        if let departureTime {
                            Text(departureTime, format: .dateTime.hour().minute())
                                .font(Theme.Fonts.bodyEmphasis)
                                .monospacedDigit()
                        }
                    }
                    Text("\(from) → \(to)")
                        .font(Theme.Fonts.bodyEmphasis)
                    HStack(spacing: 12) {
                        if let platform {
                            Text("Platform \(platform)")
                        }
                        Text("\(stops) stops")
                    }
                    .font(Theme.Fonts.secondary)
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        DirectionsView(
            route: Route.mockRoutes(from: .mock(label: .work), to: .mock(label: .home)).first!,
            destination: .mock(label: .home),
            firstName: "Joe",
            accentStyle: .gradient(.green)
        )
    }
}
