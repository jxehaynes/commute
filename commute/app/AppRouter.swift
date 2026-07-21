import SwiftUI

struct AppRouter: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        if appState.hasCompletedOnboarding {
            HomeView()
        } else {
            OnboardingFlowView()
        }
    }
}
