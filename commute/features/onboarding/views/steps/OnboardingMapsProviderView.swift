import SwiftUI

struct OnboardingMapsProviderView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    @EnvironmentObject private var appState: AppState

    var body: some View {
        OnboardingScreen(
            viewModel: viewModel,
            onContinue: { viewModel.advance(appState: appState) }
        ) {
            VStack(spacing: OnboardingMetrics.sectionSpacing) {
                OnboardingHeadline(parts: [.plain("Choose your "), .serif("maps")])
                OnboardingSubheadline(text: "Where should we open directions and station maps?")
                MapsProviderPicker(
                    selection: $viewModel.mapsProvider,
                    accentStyle: viewModel.accentStyle
                )
            }
        }
    }
}

struct MapsProviderPicker: View {
    @Binding var selection: UserProfile.MapsProvider
    let accentStyle: AccentStyle
    var showsUnavailableProviders = false

    private var providers: [UserProfile.MapsProvider] {
        showsUnavailableProviders
            ? UserProfile.MapsProvider.allCases
            : UserProfile.MapsProvider.allCases.filter(\.isLocationSearchEnabled)
    }

    var body: some View {
        VStack(spacing: 16) {
            ForEach(providers, id: \.self) { provider in
                MapsProviderRow(
                    provider: provider,
                    isSelected: selection == provider,
                    accentStyle: accentStyle
                ) {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        selection = provider
                    }
                }
            }
        }
    }
}

struct MapsProviderRow: View {
    let provider: UserProfile.MapsProvider
    let isSelected: Bool
    let accentStyle: AccentStyle
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 14) {
                    providerIcon
                    VStack(alignment: .leading, spacing: 3) {
                        Text(provider.displayName)
                            .font(Theme.Fonts.bodyEmphasis)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text(provider.availabilityLabel)
                            .font(Theme.Fonts.caption)
                            .foregroundStyle(provider.isLocationSearchEnabled ? Theme.Colors.statusGood : Theme.Colors.textTertiary)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if isSelected {
                Text(provider.privacySummary)
                    .font(Theme.Fonts.secondary)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.leading, 54)
                    .padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Rectangle()
                .fill(Theme.Colors.divider)
                .frame(height: 1)
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.85), value: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var providerIcon: some View {
        let symbol: String = switch provider {
        case .apple: "map.fill"
        case .google: "globe.europe.africa.fill"
        case .openStreetMap: "map"
        }
        ZStack {
            if isSelected {
                AccentGradientCircle(
                    accent: accentStyle,
                    diameter: 40,
                    systemImage: symbol,
                    iconSize: 17
                )
            } else {
                Circle()
                    .fill(Theme.Colors.backgroundElevated)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: symbol)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
            }
        }
    }
}
