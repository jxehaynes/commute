import SwiftUI

struct OnboardingPaceLearningView: View {
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
                OnboardingHeadline(parts: [.plain("Learn your "), .serif("walking pace"), .serif("?")])
                OnboardingSubheadline(text: "We'll learn how fast you walk and adjust connection times so you're not rushing or waiting around.")
                AccentGradientToggle(
                    label: "Enable pace learning",
                    isOn: $viewModel.enablePaceLearning,
                    accent: viewModel.accentStyle
                )
                .padding(.top, 8)
            }
        }
    }
}
