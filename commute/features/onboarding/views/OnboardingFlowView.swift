import SwiftUI

struct OnboardingFlowView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = OnboardingFlowViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        OnboardingStepLayout(
            progress: viewModel.currentStep.progressFraction,
            accent: viewModel.resolvedAccent(appState: appState)
        ) {
            stepContent
                .id(viewModel.currentStep)
                .transition(stepTransition)
        }
        .onAppear {
            if !appState.hasCompletedOnboarding {
                let step = OnboardingStep.migrated(from: appState.onboardingStep.rawValue)
                viewModel.restore(step: step)
                if step.rawValue > OnboardingStep.accentColour.rawValue {
                    viewModel.accentStyle = appState.accentStyle
                }
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .welcome:
            OnboardingWelcomeView(viewModel: viewModel)
        case .name:
            OnboardingNameView(viewModel: viewModel)
        case .accentColour:
            OnboardingAccentColourView(viewModel: viewModel)
        case .locationPerm:
            OnboardingLocationPermView(viewModel: viewModel)
        case .locations:
            OnboardingLocationsView(viewModel: viewModel)
        case .lineVisibility:
            OnboardingLineVisibilityView(viewModel: viewModel)
        case .mapsProvider:
            OnboardingMapsProviderView(viewModel: viewModel)
        case .usualCommute:
            OnboardingUsualCommuteView(viewModel: viewModel)
        case .usualTimes:
            OnboardingUsualTimesView(viewModel: viewModel)
        case .paceLearning:
            OnboardingPaceLearningView(viewModel: viewModel)
        case .liveActivities:
            OnboardingLiveActivitiesView(viewModel: viewModel)
        case .done:
            OnboardingDoneView(viewModel: viewModel)
        }
    }

    private var stepTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .opacity.combined(with: .offset(x: 28)),
                removal: .opacity.combined(with: .offset(x: -28))
            )
    }
}
