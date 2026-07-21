import SwiftUI

struct OnboardingWelcomeView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: OnboardingMetrics.topContentInset + 24)
            VStack(spacing: OnboardingMetrics.sectionSpacing) {
                OnboardingHeadline(parts: [.plain("Welcome to "), .serif("Commute")])
                OnboardingSubheadline(text: "London travel guidance that knows where you are going.")
            }
            .frame(maxWidth: OnboardingMetrics.contentMaxWidth)
            .padding(.horizontal, OnboardingMetrics.horizontalPadding)
            Spacer()
            RainbowSwipeToStart(accent: viewModel.resolvedAccent(appState: appState)) {
                viewModel.advance(appState: appState)
            }
            .padding(.horizontal, OnboardingMetrics.horizontalPadding)
            .padding(.bottom, 40)
        }
    }
}
