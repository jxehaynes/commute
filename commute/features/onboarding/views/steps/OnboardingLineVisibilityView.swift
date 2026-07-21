import SwiftUI

struct OnboardingLineVisibilityView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    @EnvironmentObject private var appState: AppState

    var body: some View {
        OnboardingScreen(
            viewModel: viewModel,
            showsSkip: true,
            scrollable: true,
            onSkip: { viewModel.skip(appState: appState) },
            onContinue: { viewModel.advance(appState: appState) }
        ) {
            VStack(spacing: OnboardingMetrics.sectionSpacing) {
                OnboardingHeadline(parts: [.plain("Which "), .serif("lines"), .plain(" do you take?")])
                OnboardingSubheadline(text: "Choose what shows up in your network status. You can change this later in Settings.")
                LineVisibilityPicker(
                    preferences: $viewModel.lineVisibility,
                    accent: viewModel.resolvedAccent(appState: appState)
                )
                .padding(.top, 4)
            }
        }
    }
}
