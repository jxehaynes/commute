import SwiftUI

struct OnboardingUsualCommuteView: View {
    @ObservedObject var viewModel: OnboardingFlowViewModel
    @EnvironmentObject private var appState: AppState
    @State private var showCustomBuilder = false
    @StateObject private var builderViewModel = CustomCommuteBuilderViewModel()

    private var canContinue: Bool { viewModel.selectedUsualRoute != nil }

    var body: some View {
        OnboardingScreen(
            viewModel: viewModel,
            showsContinue: false,
            continueEnabled: canContinue,
            scrollable: true,
            onContinue: { viewModel.advance(appState: appState) }
        ) {
            VStack(spacing: OnboardingMetrics.sectionSpacing) {
                OnboardingHeadline(parts: [.plain("Your "), .serif("usual commute")])
                OnboardingSubheadline(text: "Swipe right on the Apple Maps route you usually take. TfL will support status and train-time context.")
                routeList
                customRouteEntry
            }
        }
        .task { await viewModel.fetchRouteSuggestions() }
        .sheet(isPresented: $showCustomBuilder) {
            CustomCommuteBuilderView(
                viewModel: builderViewModel,
                accent: viewModel.resolvedAccent(appState: appState),
                mapsProvider: viewModel.mapsProvider,
                onSave: { route, _, _ in
                    viewModel.applyCustomRoute(route)
                    viewModel.advance(appState: appState)
                }
            )
        }
    }

    @ViewBuilder
    private var customRouteEntry: some View {
        if let custom = viewModel.customCommuteRoute, custom.isValid {
            VStack(spacing: 12) {
                customRouteSummary(custom)
                Button("Edit custom route") { startBuildingCustomRoute() }
                    .font(Theme.Fonts.secondary)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        } else {
            Button("Mine's different →") { startBuildingCustomRoute() }
                .font(Theme.Fonts.bodyEmphasis)
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityLabel("Mine's different")
        }
    }

    private func startBuildingCustomRoute() {
        guard let home = viewModel.homeLocation, let work = viewModel.workLocation else { return }
        builderViewModel.configure(
            availableLocations: [home, work],
            lockedOrigin: home,
            lockedDestination: work,
            existing: viewModel.customCommuteRoute
        )
        showCustomBuilder = true
    }

    private func customRouteSummary(_ custom: CustomCommuteRoute) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(viewModel.resolvedAccent(appState: appState).tintColor)
                Text(custom.toRoute().summary)
                    .font(Theme.Fonts.bodyEmphasis)
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            Text("\(custom.steps.count) steps · \(custom.steps.reduce(0) { $0 + $1.estimatedMinutes }) min")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.Colors.backgroundSurface)
                .accentGradientBorder(
                    accent: viewModel.resolvedAccent(appState: appState),
                    cornerRadius: 16,
                    lineWidth: 2,
                    isActive: true
                )
        }
    }

    @ViewBuilder
    private var routeList: some View {
        if viewModel.isFetchingSuggestions {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.backgroundElevated)
                    .frame(height: 88)
                    .redacted(reason: .placeholder)
            }
        } else if viewModel.suggestedRoutes.isEmpty {
            liveRoutesEmptyState
        } else {
            ForEach(Array(viewModel.suggestedRoutes.enumerated()), id: \.element.id) { index, route in
                OnboardingSwipeToSelectRouteCard(
                    route: route,
                    isSelected: viewModel.customCommuteRoute == nil && viewModel.selectedUsualRoute?.id == route.id,
                    accent: viewModel.resolvedAccent(appState: appState),
                    animationPhase: Double(index) * 0.8,
                    destinationLabel: "work",
                    onSelect: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.selectSuggestedRoute(route)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                            viewModel.advance(appState: appState)
                        }
                    }
                )
            }
        }
    }

    private var liveRoutesEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tram.fill.tunnel")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(viewModel.resolvedAccent(appState: appState).tintColor)
            Text("No live routes yet")
                .font(Theme.Fonts.bodyEmphasis)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("Apple Maps could not return transit routes for these saved places. Check the Home and Work locations, then try again.")
                .font(Theme.Fonts.secondary)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            Button("Reload routes") {
                Task { await viewModel.fetchRouteSuggestions() }
            }
            .font(Theme.Fonts.bodyEmphasis)
            .foregroundStyle(viewModel.resolvedAccent(appState: appState).tintColor)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.Colors.backgroundSurface)
        }
    }
}

private struct OnboardingSwipeToSelectRouteCard: View {
    let route: Route
    let isSelected: Bool
    let accent: AccentStyle
    let animationPhase: Double
    let destinationLabel: String
    let onSelect: () -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var isFloating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let selectionThreshold: CGFloat = 100

    var body: some View {
        JourneyRouteCard(
            route: route,
            isSelected: isSelected,
            accent: accent,
            appearance: .onboarding,
            showsStatus: true,
            destinationLabel: destinationLabel,
            onTap: {}
        )
        .offset(x: dragOffset)
        .opacity(1 - Double(min(dragOffset / 300, 0.3)))
        .rotationEffect(.degrees(rotationDegrees))
        .offset(y: floatOffset)
        .overlay(alignment: .leading) {
            if dragOffset > 20 {
                selectHint
                    .opacity(Double(min(dragOffset / 70, 1)))
                    .padding(.leading, 18)
            }
        }
        .highPriorityGesture(swipeGesture)
        .accessibilityHint("Swipe right to choose this route")
        .accessibilityAction(named: "Choose route") { onSelect() }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(
                .easeInOut(duration: 3.8)
                .repeatForever(autoreverses: true)
                .delay(animationPhase)
            ) {
                isFloating = true
            }
        }
    }

    private var selectHint: some View {
        VStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
            Text("Use")
                .font(Theme.Fonts.caption)
        }
        .foregroundStyle(Theme.Colors.textPrimary.opacity(0.85))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.white.opacity(0.72), in: Capsule())
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                let horizontal = value.translation.width
                let vertical = abs(value.translation.height)
                guard horizontal > 0, horizontal > vertical else { return }
                dragOffset = horizontal
            }
            .onEnded { value in
                let horizontal = max(0, value.translation.width)
                let predicted = max(0, value.predictedEndTranslation.width)

                if horizontal > selectionThreshold || predicted > 160 {
                    commitSwipe()
                } else {
                    resetOffset()
                }
            }
    }

    private func commitSwipe() {
        let animation = reduceMotion
            ? Animation.easeOut(duration: 0.22)
            : Animation.spring(response: 0.32, dampingFraction: 0.86)

        withAnimation(animation) {
            dragOffset = 440
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.14 : 0.2)) {
            onSelect()
            dragOffset = 0
        }
    }

    private func resetOffset() {
        withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.38, dampingFraction: 0.82)) {
            dragOffset = 0
        }
    }

    private var rotationDegrees: Double {
        if reduceMotion { return 0 }
        return (isFloating ? 0.7 : -0.7) + Double(dragOffset / 40)
    }

    private var floatOffset: CGFloat {
        guard !reduceMotion else { return 0 }
        return isFloating ? -3 : 3
    }
}
