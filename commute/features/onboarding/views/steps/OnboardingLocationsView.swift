import SwiftUI

struct OnboardingLocationsView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    @EnvironmentObject private var appState: AppState

    private var canContinue: Bool {
        !viewModel.homeAddress.trimmingCharacters(in: .whitespaces).isEmpty
            && !viewModel.workAddress.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        OnboardingScreen(
            viewModel: viewModel,
            continueEnabled: canContinue,
            onContinue: {
                viewModel.commitLocationEdits()
                viewModel.advance(appState: appState)
            }
        ) {
            VStack(spacing: 28) {
                OnboardingHeadline(
                    parts: [.plain("Where do you "), .serif("live"), .plain(" and "), .serif("work"), .serif("?")]
                )
                OnboardingSubheadline(text: "Add the places you travel between most often. We'll suggest the best routes.")

                AddressLocationEditor(
                    title: "Start",
                    serifTitle: "Home",
                    icon: "house.fill",
                    address: $viewModel.homeAddress,
                    accent: viewModel.resolvedAccent(appState: appState),
                    mapsProvider: viewModel.mapsProvider,
                    onSelect: { viewModel.selectLocation($0, label: .home) }
                )

                AddressLocationEditor(
                    title: "Destination",
                    serifTitle: "Work",
                    icon: "briefcase.fill",
                    address: $viewModel.workAddress,
                    accent: viewModel.resolvedAccent(appState: appState),
                    mapsProvider: viewModel.mapsProvider,
                    onSelect: { viewModel.selectLocation($0, label: .work) }
                )

                AddressLocationEditor(
                    title: "Optional",
                    serifTitle: "Other",
                    icon: "star.fill",
                    address: $viewModel.otherAddress,
                    name: $viewModel.otherName,
                    accent: viewModel.resolvedAccent(appState: appState),
                    mapsProvider: viewModel.mapsProvider,
                    onSelect: { viewModel.selectLocation($0, label: .other) }
                )
            }
        }
    }
}
