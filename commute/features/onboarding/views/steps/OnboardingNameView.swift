import SwiftUI

struct OnboardingNameView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    @EnvironmentObject private var appState: AppState

    private var canContinue: Bool {
        !viewModel.firstName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        OnboardingScreen(
            viewModel: viewModel,
            continueEnabled: canContinue,
            onContinue: { viewModel.advance(appState: appState) }
        ) {
            VStack(spacing: OnboardingMetrics.sectionSpacing) {
                OnboardingHeadline(parts: [.plain("What's your "), .serif("first name"), .serif("?")])
                SerifNameEntryField(
                    text: $viewModel.firstName,
                    accent: viewModel.resolvedAccent(appState: appState)
                )
                .padding(.top, 8)
            }
        }
    }
}
