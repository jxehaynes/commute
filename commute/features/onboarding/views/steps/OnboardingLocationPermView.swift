import SwiftUI

struct OnboardingLocationPermView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    @EnvironmentObject private var appState: AppState
    @StateObject private var locationPermission = LocationPermissionManager()

    var body: some View {
        OnboardingScreen(
            viewModel: viewModel,
            showsSkip: true,
            scrollable: true,
            onSkip: { viewModel.skip(appState: appState) },
            onContinue: { viewModel.advance(appState: appState) }
        ) {
            VStack(spacing: OnboardingMetrics.sectionSpacing) {
                OnboardingHeadline(parts: [.plain("Enable "), .serif("location")])
                OnboardingSubheadline(text: "Commute uses your location for live route context, proactive leave times and accurate nearby place search.")

                VStack(spacing: 14) {
                    permissionCard
                    mapsProviderCard
                }
            }
        }
        .onAppear {
            if !viewModel.mapsProvider.isLocationSearchEnabled {
                viewModel.mapsProvider = .apple
            }
        }
    }

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                AccentGradientCircle(
                    accent: viewModel.accentStyle,
                    diameter: 44,
                    systemImage: "location.circle.fill"
                )
                VStack(alignment: .leading, spacing: 3) {
                    Text("Location access")
                        .font(Theme.Fonts.bodyEmphasis)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(locationPermission.statusLabel)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(locationPermission.isAlwaysAllowed ? Theme.Colors.statusGood : Theme.Colors.textSecondary)
                }
                Spacer()
            }

            Text(locationPermission.explanation)
                .font(Theme.Fonts.secondary)
                .foregroundStyle(Theme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                locationPermission.requestAlwaysAccess()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(locationPermission.isAlwaysAllowed ? "Always access enabled" : "Allow Always location")
                        .font(Theme.Fonts.bodyEmphasis)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background {
                    AccentButtonBackground(accent: viewModel.accentStyle)
                }
                .clipShape(Capsule())
            }
            .buttonStyle(OnboardingPressStyle())
            .disabled(locationPermission.isAlwaysAllowed)
            .opacity(locationPermission.isAlwaysAllowed ? 0.65 : 1)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.Colors.backgroundSurface)
                .accentGradientBorder(
                    accent: viewModel.accentStyle,
                    cornerRadius: 18,
                    lineWidth: 1.5,
                    isActive: locationPermission.isAlwaysAllowed
                )
        }
    }

    private var mapsProviderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Maps and search provider")
                    .font(Theme.Fonts.bodyEmphasis)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("Apple MapKit powers live address search now. More providers can be added once their APIs are ready.")
                    .font(Theme.Fonts.secondary)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            MapsProviderPicker(
                selection: $viewModel.mapsProvider,
                accentStyle: viewModel.accentStyle,
                showsUnavailableProviders: false
            )
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.Colors.backgroundSurface)
        }
    }
}
