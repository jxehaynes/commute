import SwiftUI

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct JourneyOptionsView: View {
    @ObservedObject var viewModel: HomeViewModel
    let userProfile: UserProfile
    let firstName: String
    let destination: SavedLocation
    let accentStyle: AccentStyle
    var revealProgress: CGFloat = 1
    var topBarClearance: CGFloat = 96
    var dismissEnabled: Bool = true
    @Binding var collapseOffset: CGFloat
    @Binding var directionsRoute: Route?
    var onDismiss: (() -> Void)?

    @State private var showAlternatives = false
    @State private var expandedRouteID: UUID?
    @State private var scrollOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var cardRevealProgress: CGFloat {
        min(max(revealProgress, 0), 1)
    }

    private var defaultRoute: Route? {
        viewModel.defaultRoute(for: userProfile)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                JourneyRouteLoadingView(accent: accentStyle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let route = defaultRoute {
                journeyScrollContent(route: route)
            } else {
                journeyUnavailableContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .opacity(Double(cardRevealProgress))
        .animation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.42, dampingFraction: 0.86), value: cardRevealProgress)
    }

    private func journeyScrollContent(route: Route) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Capsule()
                    .fill(.white.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 4)

                activeRouteSection(route)

                if showAlternatives {
                    alternativesSection
                } else {
                    revealAlternativesHint
                }
            }
            .frame(maxWidth: OnboardingMetrics.contentMaxWidth)
            .padding(.top, topBarClearance)
            .padding(.bottom, 48)
            .frame(maxWidth: .infinity)
            .background {
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geo.frame(in: .named("journeyScroll")).minY
                    )
                }
            }
        }
        .coordinateSpace(name: "journeyScroll")
        .scrollIndicators(.hidden)
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { scrollOffset = $0 }
        .simultaneousGesture(pullToDismissGesture)
        .simultaneousGesture(revealAlternativesGesture)
        .offset(y: collapseOffset * 0.4)
    }

    private var journeyUnavailableContent: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(.white.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 4)

            if let origin = viewModel.journeyIntent?.origin {
                Text("\(origin.displayName) → \(destination.displayName)")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .textCase(.uppercase)
            }

            OnboardingHeadline(
                parts: [
                    .serif(firstName.isEmpty ? "We" : firstName),
                    .plain(firstName.isEmpty
                        ? " couldn't find a route."
                        : ", we couldn't find a route.")
                ],
                centered: true,
                foregroundColor: .white
            )

            Text(viewModel.errorMessage ?? "Check your connection and try again.")
                .font(Theme.Fonts.secondary)
                .foregroundStyle(.white.opacity(0.82))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)

            Button {
                viewModel.retryPreload(for: userProfile)
            } label: {
                Text("Try again")
                    .font(Theme.Fonts.bodyEmphasis)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(accentStyle.tintColor.opacity(0.35))
                            .overlay {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(.white.opacity(0.28), lineWidth: 1)
                            }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityHint("Reloads journey options for this destination")
        }
        .frame(maxWidth: OnboardingMetrics.contentMaxWidth)
        .padding(.top, topBarClearance)
        .padding(.horizontal, OnboardingMetrics.horizontalPadding)
        .padding(.bottom, 48)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func activeRouteSection(_ route: Route) -> some View {
        VStack(spacing: 12) {
            if let origin = viewModel.journeyIntent?.origin {
                Text("\(origin.displayName) → \(destination.displayName)")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .textCase(.uppercase)
            }

            OnboardingHeadline(
                parts: [
                    .serif(firstName.isEmpty ? "You" : firstName),
                    .plain(", your best route \(route.status.isOnTime ? "is ready." : "for now.")")
                ],
                centered: true,
                foregroundColor: .white
            )

            Text("Swipe right to start navigation")
                .font(Theme.Fonts.caption)
                .foregroundStyle(.white.opacity(0.72))

            TimelineView(.periodic(from: .now, by: 60)) { context in
                SwipeableActiveCommuteCard(
                    route: route,
                    destinationLabel: destination.displayName,
                    minutesUntilLeave: viewModel.minutesUntilLeave(
                        for: userProfile,
                        route: route,
                        now: context.date
                    ),
                    leaveByTime: viewModel.leaveByTime(
                        for: userProfile,
                        route: route,
                        now: context.date
                    ),
                    accent: accentStyle,
                    lineDisruptions: viewModel.disruptions(for: route),
                    statusLastUpdated: viewModel.lastUpdated,
                    onSwipeToDirections: {
                        directionsRoute = route
                    }
                )
            }
        }
    }

    private var alternativesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Other options")
                .font(Theme.Fonts.bodyEmphasis)
                .foregroundStyle(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(viewModel.alternativeRoutes(for: userProfile)) { route in
                SwipeableJourneyRouteCard(
                    route: route,
                    isSelected: false,
                    accent: accentStyle,
                    lineDisruptions: viewModel.disruptions(for: route),
                    statusLastUpdated: viewModel.lastUpdated,
                    destinationLabel: destination.displayName,
                    isExpandedBinding: expansionBinding(for: route),
                    onTap: {},
                    onSwipeToDirections: {
                        directionsRoute = route
                    }
                )
            }
        }
    }

    private func expansionBinding(for route: Route) -> Binding<Bool> {
        Binding(
            get: { expandedRouteID == route.id },
            set: { isExpanded in
                expandedRouteID = isExpanded ? route.id : nil
            }
        )
    }

    private var revealAlternativesHint: some View {
        VStack(spacing: 6) {
            Image(systemName: "chevron.up")
                .font(.system(size: 14, weight: .semibold))
            Text("Swipe up for other routes")
                .font(Theme.Fonts.caption)
        }
        .foregroundStyle(.white.opacity(0.65))
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var pullToDismissGesture: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                guard dismissEnabled else { return }
                guard value.translation.height > 0 else { return }
                guard abs(value.translation.height) > abs(value.translation.width) else { return }
                let canDismiss = scrollOffset >= -4 || value.startLocation.y < 260
                guard canDismiss else { return }
                collapseOffset = value.translation.height
            }
            .onEnded { value in
                guard dismissEnabled else {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        collapseOffset = 0
                    }
                    return
                }
                let downward = max(0, value.translation.height)
                let predicted = max(0, value.predictedEndTranslation.height)
                if downward > 80 || predicted > 160 {
                    onDismiss?()
                } else {
                    let animation = reduceMotion
                        ? Animation.easeOut(duration: 0.2)
                        : Animation.spring(response: 0.38, dampingFraction: 0.82)
                    withAnimation(animation) {
                        collapseOffset = 0
                    }
                }
            }
    }

    private var revealAlternativesGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onEnded { value in
                guard !showAlternatives else { return }
                guard value.translation.height < -50 else { return }
                guard abs(value.translation.height) > abs(value.translation.width) else { return }
                withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.38, dampingFraction: 0.84)) {
                    showAlternatives = true
                }
            }
    }
}
