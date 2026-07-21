import SwiftUI

struct OnboardingUsualTimesView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    @EnvironmentObject private var appState: AppState

    private var accent: AccentStyle {
        viewModel.resolvedAccent(appState: appState)
    }

    var body: some View {
        OnboardingScreen(
            viewModel: viewModel,
            showsSkip: true,
            scrollable: true,
            onSkip: { viewModel.skip(appState: appState) },
            onContinue: { viewModel.advance(appState: appState) }
        ) {
            VStack(spacing: 28) {
                OnboardingHeadline(parts: [.plain("When do you need to "), .serif("arrive"), .serif("?")])
                OnboardingSubheadline(text: "Tell us when you need to be there. We'll plan your leave time around it.")

                VStack(spacing: 24) {
                    SerifExpandableTimePicker(
                        title: "Morning commute",
                        serifLabel: "At work by",
                        time: $viewModel.arriveAtWorkBy,
                        accent: accent
                    )
                    ArrivalPreferencePicker(
                        label: "How do you like to arrive?",
                        preference: $viewModel.workArrivalPreference,
                        accent: accent,
                        context: .work
                    )
                }

                Divider()
                    .padding(.vertical, 4)

                VStack(spacing: 24) {
                    SerifExpandableTimePicker(
                        title: "Evening commute",
                        serifLabel: "At home after",
                        time: $viewModel.arriveHomeBy,
                        accent: accent
                    )
                    ArrivalPreferencePicker(
                        label: "How do you like to arrive?",
                        preference: $viewModel.homeArrivalPreference,
                        accent: accent,
                        context: .home
                    )
                }
            }
        }
    }
}
