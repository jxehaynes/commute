import SwiftUI

struct OnboardingDoneView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    @EnvironmentObject private var appState: AppState

    var body: some View {
        OnboardingScreen(
            viewModel: viewModel,
            showsBack: true,
            continueLabel: "Start commuting",
            onContinue: { viewModel.completeOnboarding(appState: appState) }
        ) {
            VStack(spacing: OnboardingMetrics.sectionSpacing) {
                OnboardingHeadline(
                    parts: [
                        .plain("You're set, "),
                        .serif(viewModel.firstName.isEmpty ? "traveller" : viewModel.firstName),
                        .plain(".")
                    ]
                )
                OnboardingSubheadline(text: "Tap Commute whenever you're ready to go.")
            }
        }
    }
}
