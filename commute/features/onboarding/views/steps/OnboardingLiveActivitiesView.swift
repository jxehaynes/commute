import SwiftUI

struct OnboardingLiveActivitiesView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    @EnvironmentObject private var appState: AppState

    var body: some View {
        OnboardingScreen(
            viewModel: viewModel,
            showsSkip: true,
            onSkip: { viewModel.skip(appState: appState) },
            onContinue: { viewModel.advance(appState: appState) }
        ) {
            VStack(spacing: OnboardingMetrics.sectionSpacing) {
                OnboardingHeadline(parts: [.plain("Live Activities on your "), .serif("Lock Screen")])
                OnboardingSubheadline(text: "Get automatic live activities when it's time to go.")
                AccentGradientToggle(
                    label: "Enable Live Activities",
                    isOn: $viewModel.enableLiveActivities,
                    accent: viewModel.accentStyle
                )
                .padding(.top, 8)
            }
        }
    }
}
