import CoreLocation
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var userLocationProvider = UserLocationProvider()
    @State private var showSettings = false
    @State private var dragProgress: CGFloat = 0
    @State private var journeyRevealed = false
    @State private var collapseDragOffset: CGFloat = 0
    @State private var directionsRoute: Route?
    @State private var holdOrigin: UnitPoint = .center
    @State private var statusRevealProgress: CGFloat = 0
    @State private var statusDragTranslation: CGFloat = 0
    @State private var destPickerProgress: CGFloat = 0
    @State private var destPickerDragTranslation: CGFloat = 0
    @State private var showsDestPickerHint = true
    @State private var showsStatusSwipeHint = true
    @State private var statusHintCycle = 0
    @State private var destPickerHintCycle = 0
    @State private var journeyDismissEnabled = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var firstName: String { appState.userProfile.firstName }
    private var accentStyle: AccentStyle { appState.accentStyle }

    private let topControlHeight: CGFloat = 32
    private let clockDiameter: CGFloat = 60
    private let topBarPadding: CGFloat = 6
    private let contentBelowTopBar: CGFloat = 16
    private let greetingPeekWidth: CGFloat = 44
    private let statusRevealThreshold: CGFloat = 0.38
    private let statusDismissThreshold: CGFloat = 0.62

    private let destPickerRevealThreshold: CGFloat = 0.38
    private let destPickerDismissThreshold: CGFloat = 0.62

    private var isStatusRevealed: Bool {
        statusRevealProgress > 0.01
    }

    private var isDestinationPickerRevealed: Bool {
        destPickerProgress > 0.01
    }

    private var isHomeOverlayActive: Bool {
        isStatusRevealed || isDestinationPickerRevealed
    }

    private var hasSelectableDestinations: Bool {
        !viewModel.selectableDestinations(for: appState.userProfile).isEmpty
    }

    private func topChromeHeight() -> CGFloat {
        topBarPadding + clockDiameter + contentBelowTopBar
    }

    private func journeyTopBarClearance(topSafeInset: CGFloat) -> CGFloat {
        topSafeInset + topBarPadding + topControlHeight + contentBelowTopBar
    }

    private func bottomChromePadding(bottomSafeInset: CGFloat) -> CGFloat {
        max(24, bottomSafeInset + 16)
    }

    private func statusRevealAmount(for progress: CGFloat) -> CGFloat {
        min(max(progress, 0), 1)
    }

    private func liveStatusProgress(maxShift: CGFloat) -> CGFloat {
        let shift = maxShift > 0 ? statusDragTranslation / maxShift : 0
        return min(max(statusRevealProgress + shift, 0), 1)
    }

    private func liveDestPickerProgress(maxLift: CGFloat) -> CGFloat {
        let shift = maxLift > 0 ? destPickerDragTranslation / maxLift : 0
        return min(max(destPickerProgress + shift, 0), 1)
    }

    private func destPickerRevealAmount(for progress: CGFloat) -> CGFloat {
        min(max(progress, 0), 1)
    }

    private func destPickerMaxLift(for height: CGFloat) -> CGFloat {
        min(max(height * 0.34, 220), 320)
    }

    private var gradientCoverage: CGFloat {
        if journeyRevealed {
            return max(0, 1 - min(collapseDragOffset / 340, 1))
        }
        return dragProgress
    }

    private var gradientMaskProgress: CGFloat {
        if journeyRevealed {
            return max(gradientCoverage, 1)
        }
        return dragProgress
    }

    private var usesImmersiveGradient: Bool {
        journeyRevealed || dragProgress > 0.2
    }

    private var showsPersonalisedMessage: Bool {
        !journeyRevealed || personalisedMessageOpacity > 0.02
    }

    private var homeGreetingMessageOpacity: Double {
        if journeyRevealed {
            return Double(personalisedMessageOpacity)
        }
        guard dragProgress > 0.01 else { return 1 }
        return Double(max(0, 1 - dragProgress / 0.55))
    }

    private var personalisedMessageOpacity: CGFloat {
        if journeyRevealed {
            return max(0, 1 - gradientCoverage * 1.1)
        }
        return 1
    }

    private var shouldShowStatusSwipeHint: Bool {
        showsStatusSwipeHint && statusRevealProgress < 0.08 && destPickerProgress < 0.08 && !journeyRevealed
    }

    private var shouldShowDestPickerHint: Bool {
        showsDestPickerHint
            && destPickerProgress < 0.08
            && statusRevealProgress < 0.08
            && !journeyRevealed
            && hasSelectableDestinations
    }

    private var showsJourneyOptions: Bool {
        journeyRevealed
    }

    private var showsHomeChrome: Bool {
        !journeyRevealed || gradientCoverage < 0.92
    }

    private var homeBlanketFade: CGFloat {
        guard !journeyRevealed else { return 0 }
        return min(max(dragProgress, 0), 1)
    }

    private var homeContentOpacity: Double {
        Double(max(0, 1 - homeBlanketFade * 0.92))
    }

    private var journeyContentOpacity: Double {
        if journeyRevealed {
            return Double(min(gradientCoverage * 1.2, 1))
        }
        return 0
    }

    private var isGradientFullyExpanded: Bool {
        journeyRevealed
    }

    private var holdIsEnabled: Bool {
        !viewModel.needsDestinationPicker(for: appState.userProfile)
            && viewModel.canStartJourney(for: appState.userProfile)
    }

    private var resolvedDestinationName: String? {
        viewModel.resolvedDestination(for: appState.userProfile)?.displayName
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.backgroundPrimary
                    .ignoresSafeArea()

                gradientReveal()

                GeometryReader { proxy in
                    let maxShift = max(proxy.size.width - greetingPeekWidth, 1)
                    let maxLift = destPickerMaxLift(for: proxy.size.height)
                    let statusProgress = liveStatusProgress(maxShift: maxShift)
                    let destPickerProgressLive = liveDestPickerProgress(maxLift: maxLift)
                    let topSafeInset = proxy.safeAreaInsets.top
                    let bottomSafeInset = proxy.safeAreaInsets.bottom
                    let topInset = topChromeHeight()
                    let bottomPadding = bottomChromePadding(bottomSafeInset: bottomSafeInset)

                    ZStack(alignment: .bottom) {
                        mainContent(
                            statusProgress: statusProgress,
                            destPickerProgress: destPickerProgressLive,
                            maxShift: maxShift,
                            maxLift: maxLift,
                            size: proxy.size,
                            topInset: topInset,
                            bottomPadding: bottomPadding,
                            bottomSafeInset: bottomSafeInset,
                            topSafeInset: topSafeInset
                        )
                        .coordinateSpace(name: "homeRoot")
                        .zIndex(1)

                        if !journeyRevealed, holdIsEnabled, !isHomeOverlayActive {
                            HoldToCommuteOverlay(
                                accent: accentStyle,
                                isEnabled: holdIsEnabled,
                                destinationName: resolvedDestinationName,
                                holdProgress: $dragProgress,
                                holdOrigin: $holdOrigin,
                                onHoldStart: beginHoldPreload,
                                onHoldComplete: { revealJourney() },
                                onHoldCancel: cancelHoldPreload
                            )
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .simultaneousGesture(homeScreenGesture(maxShift: maxShift, maxLift: maxLift))
                            .zIndex(15)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .top) {
                        if journeyRevealed, directionsRoute == nil {
                            journeyTopBar
                                .padding(.top, topSafeInset + topBarPadding)
                                .zIndex(20)
                        } else if showsHomeChrome {
                            homeTopBar
                                .padding(.top, topSafeInset + topBarPadding)
                                .offset(x: maxShift * statusProgress)
                                .opacity(
                                    (1 - max(
                                        statusRevealAmount(for: statusProgress),
                                        destPickerRevealAmount(for: destPickerProgressLive)
                                    ) * 0.5)
                                    * homeContentOpacity
                                )
                                .zIndex(20)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .navigationDestination(item: $directionsRoute) { route in
                DirectionsView(
                    route: route,
                    destination: directionsDestination,
                    firstName: firstName,
                    accentStyle: accentStyle
                )
            }
            .task {
                userLocationProvider.prepareForUse()
                refreshJourneyIntent()
                await viewModel.refreshDisruptions()

                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(60))
                    guard !Task.isCancelled else { return }
                    await viewModel.refreshDisruptions()
                }
            }
            .onChange(of: journeyRevealed) { _, isRevealed in
                if isRevealed {
                    resetStatusReveal(animated: true)
                    resetDestinationPicker(animated: true)
                } else {
                    statusHintCycle += 1
                    destPickerHintCycle += 1
                }
            }
            .task(id: statusHintCycle) {
                guard !journeyRevealed else { return }
                showsStatusSwipeHint = true
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled, !journeyRevealed else { return }
                withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .easeOut(duration: 0.35)) {
                    showsStatusSwipeHint = false
                }
            }
            .task(id: destPickerHintCycle) {
                guard !journeyRevealed, hasSelectableDestinations else { return }
                showsDestPickerHint = true
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled, !journeyRevealed else { return }
                withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .easeOut(duration: 0.35)) {
                    showsDestPickerHint = false
                }
            }
            .onChange(of: userLocationProvider.currentLocation) { _, _ in
                refreshJourneyIntent()
            }
            .onChange(of: appState.userProfile.locations) { _, _ in
                refreshJourneyIntent()
                viewModel.resetPreloadState()
            }
            .onAppear {
                userLocationProvider.prepareForUse()
                refreshJourneyIntent()
            }
        }
    }

    private func refreshJourneyIntent() {
        viewModel.refreshIntent(
            profile: appState.userProfile,
            userLocation: userLocationProvider.currentLocation
        )
    }

    private var homeTopBar: some View {
        HStack(alignment: .center, spacing: 12) {
            RetroAnalogClockView(diameter: clockDiameter)

            Spacer(minLength: 16)

            settingsButton(useLightStyle: false)
        }
        .padding(.horizontal, OnboardingMetrics.horizontalPadding)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var journeyTopBar: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: collapseJourney) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.92))
                    .frame(width: topControlHeight, height: topControlHeight)
            }
            .accessibilityLabel("Close journey options")
            .accessibilityHint("Returns to the home screen")

            Spacer(minLength: 16)

            settingsButton(useLightStyle: true)
        }
        .padding(.horizontal, OnboardingMetrics.horizontalPadding)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func gradientReveal() -> some View {
        if gradientMaskProgress > 0.04 {
            ZStack {
                accentStyle.tintColor
                    .opacity(usesImmersiveGradient ? 0.5 : 0.3)
                    .ignoresSafeArea()

                NeatGradientView(
                    accentStyle: accentStyle,
                    speed: 0.65,
                    presentation: usesImmersiveGradient ? .immersive : .standard
                )

                if isGradientFullyExpanded {
                    AirTopAtmosphere(accent: accentStyle, strength: 0.2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Flattens the blurred, animating gradient into a single rendered
            // texture before masking. Masking a live `.blur()` layer-by-layer
            // (the default) visibly strobed as the mask edge swept across it.
            .drawingGroup()
            .mask {
                AirIrisMask(progress: gradientMaskProgress, origin: holdOrigin)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            // Short, tight spring rather than the previous slow one: during a
            // hold, progress arrives in ~50ms discrete steps, and a slower
            // spring kept getting re-targeted before it settled, compounding
            // into visible jitter the longer the hold went on.
            .animation(.spring(response: 0.22, dampingFraction: 0.88), value: gradientMaskProgress)
        }
    }

    private func settingsButton(useLightStyle: Bool) -> some View {
        Button {
            showSettings = true
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(useLightStyle ? .white.opacity(0.9) : Theme.Colors.textSecondary)
                .frame(width: topControlHeight, height: topControlHeight)
        }
        .accessibilityLabel("Settings")
        .accessibilityHint("Open settings")
    }

    private func mainContent(
        statusProgress: CGFloat,
        destPickerProgress: CGFloat,
        maxShift: CGFloat,
        maxLift: CGFloat,
        size: CGSize,
        topInset: CGFloat,
        bottomPadding: CGFloat,
        bottomSafeInset: CGFloat,
        topSafeInset: CGFloat
    ) -> some View {
        ZStack {
            if !journeyRevealed {
                homeSwipeLayer(
                    statusProgress: statusProgress,
                    destPickerProgress: destPickerProgress,
                    size: size,
                    maxShift: maxShift,
                    maxLift: maxLift,
                    topInset: topInset,
                    bottomPadding: bottomPadding
                )
            } else {
                journeyGreetingLayer(topInset: topInset)
            }

            if destPickerProgress > 0.01, !journeyRevealed {
                HomeDestinationBubblesView(
                    destinations: viewModel.selectableDestinations(for: appState.userProfile),
                    accent: accentStyle,
                    revealProgress: destPickerProgress,
                    containerSize: size,
                    bottomInset: bottomSafeInset,
                    maxLift: maxLift,
                    pickerDragTranslation: $destPickerDragTranslation,
                    holdProgress: $dragProgress,
                    holdOrigin: $holdOrigin,
                    onHoldStart: beginDestinationHold,
                    onHoldComplete: completeDestinationHold,
                    onHoldCancel: cancelDestinationHold,
                    onPickerDragEnded: { vertical, predictedVertical in
                        let animation = reduceMotion
                            ? Animation.easeInOut(duration: 0.25)
                            : Animation.spring(response: 0.38, dampingFraction: 0.86)

                        withAnimation(animation) {
                            settleDestinationPicker(
                                vertical: vertical,
                                predictedVertical: predictedVertical,
                                maxLift: maxLift
                            )
                            destPickerDragTranslation = 0
                        }
                    },
                    onDismiss: { resetDestinationPicker(animated: true) }
                )
                .zIndex(5)
            }

            if showsJourneyOptions, let destination = routeDestination {
                JourneyOptionsView(
                    viewModel: viewModel,
                    userProfile: appState.userProfile,
                    firstName: firstName,
                    destination: destination,
                    accentStyle: accentStyle,
                    revealProgress: journeyRevealed ? gradientCoverage : dragProgress,
                    topBarClearance: journeyTopBarClearance(topSafeInset: topSafeInset),
                    dismissEnabled: journeyDismissEnabled,
                    collapseOffset: $collapseDragOffset,
                    directionsRoute: $directionsRoute,
                    onDismiss: collapseJourney
                )
                .frame(maxHeight: .infinity)
                .opacity(journeyContentOpacity)
                .allowsHitTesting(journeyRevealed)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func homeSwipeLayer(
        statusProgress: CGFloat,
        destPickerProgress: CGFloat,
        size: CGSize,
        maxShift: CGFloat,
        maxLift: CGFloat,
        topInset: CGFloat,
        bottomPadding: CGFloat
    ) -> some View {
        let swipeHeight = size.height
        let statusPanelWidth = max(size.width - greetingPeekWidth, 1)
        let drawerOffset = -statusPanelWidth + statusProgress * maxShift

        return ZStack(alignment: .top) {
            HStack(spacing: 0) {
                HomeCurrentStatusView(
                    disruptions: viewModel.networkDisruptions(matching: appState.userProfile.lineVisibility),
                    lastUpdated: viewModel.lastUpdated,
                    topInset: topInset,
                    usesSolidBackground: true
                )
                .frame(width: statusPanelWidth, height: swipeHeight)

                homeGreetingLayer(
                    topInset: topInset,
                    bottomPadding: bottomPadding
                )
                .frame(width: size.width, height: swipeHeight)
            }
            .offset(x: drawerOffset)
            .frame(width: size.width, height: swipeHeight, alignment: .leading)
            .clipped()
        }
        .frame(width: size.width, height: size.height, alignment: .top)
        .overlay(alignment: .trailing) {
            if statusProgress > 0.9 {
                statusDismissHandle
            }
        }
        .gesture(
            isHomeOverlayActive ? nil : homeScreenGesture(maxShift: maxShift, maxLift: maxLift),
            including: .gesture
        )
        .highPriorityGesture(
            isHomeOverlayActive ? homeScreenGesture(maxShift: maxShift, maxLift: maxLift) : nil
        )
        .accessibilityAction(named: "Show current status") {
            revealStatus(animated: true)
        }
        .accessibilityAction(named: "Choose destination") {
            revealDestinationPicker(animated: true)
        }
        .accessibilityAction(named: "Return to greeting") {
            resetStatusReveal(animated: true)
            resetDestinationPicker(animated: true)
        }
    }

    private var statusDismissHandle: some View {
        Button {
            resetStatusReveal(animated: true)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
                Text("Home")
                    .font(Theme.Fonts.caption)
                    .rotationEffect(.degrees(-90))
            }
            .foregroundStyle(Theme.Colors.textSecondary)
            .frame(width: greetingPeekWidth)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Return home")
        .accessibilityHint("Closes line status and returns to the home screen")
    }

    private func homeGreetingLayer(
        topInset: CGFloat,
        bottomPadding: CGFloat
    ) -> some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: topInset)

            Spacer()

            homeGreetingContent

            Spacer()
            Spacer()

            if !journeyRevealed {
                homeBottomControls(bottomPadding: bottomPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Theme.Colors.backgroundPrimary
                .opacity(Double(1 - min(dragProgress / 0.2, 1)))
        )
    }

    @ViewBuilder
    private func homeBottomControls(bottomPadding: CGFloat) -> some View {
        VStack(spacing: 10) {
            if let destination = viewModel.journeyIntent?.defaultDestination {
                destinationSuggestionChip(for: destination)
            }

            holdHint
        }
        .opacity(homeContentOpacity)
        .padding(.horizontal, OnboardingMetrics.horizontalPadding)
        .padding(.bottom, bottomPadding)
    }

    private func destinationSuggestionChip(for destination: SavedLocation) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                .font(.system(size: 13, weight: .semibold))
            Text("Directions to \(destination.displayName)")
                .font(Theme.Fonts.bodyEmphasis)
        }
        .foregroundStyle(accentStyle.tintColor)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var holdHint: some View {
        Group {
            if holdIsEnabled {
                Text("Hold anywhere for directions")
            } else if hasSelectableDestinations {
                Text("Swipe up to choose a place, or set up your commute schedule")
            } else {
                Text("Set up your places to get directions")
            }
        }
        .font(Theme.Fonts.caption)
        .foregroundStyle(Theme.Colors.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var homeGreetingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            personalisedMessage

            if let presence = viewModel.journeyIntent?.presence {
                Text(presence.displayText)
                    .font(Theme.Fonts.secondary)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            ZStack(alignment: .topLeading) {
                Color.clear
                    .frame(height: 36)

                VStack(alignment: .leading, spacing: 6) {
                    statusSwipeHint
                        .opacity(shouldShowStatusSwipeHint ? 1 : 0)

                    destPickerHint
                        .opacity(shouldShowDestPickerHint ? 1 : 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .allowsHitTesting(false)
            .accessibilityHidden(!shouldShowStatusSwipeHint && !shouldShowDestPickerHint)
        }
        .padding(.horizontal, OnboardingMetrics.horizontalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(homeGreetingMessageOpacity)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: shouldShowStatusSwipeHint)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: shouldShowDestPickerHint)
    }

    private var destPickerHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.up")
                .font(.system(size: 11, weight: .semibold))
            Text("Swipe up for saved places")
                .font(Theme.Fonts.caption)
        }
        .foregroundStyle(Theme.Colors.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHint("Swipe up on the main screen to choose a destination")
    }

    private var statusSwipeHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .semibold))
            Text("Swipe right for line status")
                .font(Theme.Fonts.caption)
        }
        .foregroundStyle(Theme.Colors.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHint("Swipe right on the main screen to view TfL line status")
    }

    private func journeyGreetingLayer(topInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: topInset)

            Spacer()

            if showsPersonalisedMessage {
                personalisedMessage
                    .opacity(Double(personalisedMessageOpacity))
                    .padding(.horizontal, OnboardingMetrics.horizontalPadding)
            }

            Spacer()
            Spacer()
        }
    }

    private var personalisedMessage: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            HomeGreetingView(
                parts: HomeGreetingBuilder.headlineParts(
                    firstName: firstName,
                    phase: viewModel.commutePhase(
                        for: appState.userProfile,
                        now: context.date
                    )
                )
            )
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: OnboardingMetrics.contentMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func homeScreenGesture(maxShift: CGFloat, maxLift: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !journeyRevealed else { return }

                let horizontal = value.translation.width
                let vertical = value.translation.height

                if isDestinationPickerRevealed {
                    guard vertical > 0, abs(vertical) > abs(horizontal) * 0.85 else { return }
                    destPickerDragTranslation = -vertical
                    statusDragTranslation = 0
                    return
                }

                if isStatusRevealed {
                    guard abs(horizontal) > abs(vertical) * 0.85 else { return }
                    let proposed = statusRevealProgress + horizontal / maxShift
                    statusDragTranslation = (proposed - statusRevealProgress) * maxShift
                    destPickerDragTranslation = 0
                    return
                }

                if abs(horizontal) > abs(vertical) * 0.85 {
                    guard destPickerProgress < 0.01 else { return }
                    let proposed = statusRevealProgress + horizontal / maxShift
                    statusDragTranslation = (proposed - statusRevealProgress) * maxShift
                    destPickerDragTranslation = 0
                } else if vertical < 0, abs(vertical) > abs(horizontal) * 0.85, hasSelectableDestinations {
                    guard statusRevealProgress < 0.01 else { return }
                    destPickerDragTranslation = -vertical
                    statusDragTranslation = 0
                }
            }
            .onEnded { value in
                guard !journeyRevealed else { return }

                let horizontal = value.translation.width
                let vertical = value.translation.height
                let animation = reduceMotion
                    ? Animation.easeInOut(duration: 0.25)
                    : Animation.spring(response: 0.38, dampingFraction: 0.86)

                withAnimation(animation) {
                    if abs(vertical) > abs(horizontal) * 0.85 {
                        if destPickerProgress > 0.01 || (vertical < 0 && hasSelectableDestinations && statusRevealProgress < 0.01) {
                            settleDestinationPicker(
                                vertical: vertical,
                                predictedVertical: value.predictedEndTranslation.height,
                                maxLift: maxLift
                            )
                        }
                    } else if abs(horizontal) > abs(vertical) * 0.85 {
                        if statusRevealProgress > 0.01 || horizontal > 0 {
                            settleStatusDrawer(
                                horizontal: horizontal,
                                predictedHorizontal: value.predictedEndTranslation.width,
                                maxShift: maxShift
                            )
                        }
                    }
                    statusDragTranslation = 0
                    destPickerDragTranslation = 0
                }
            }
    }

    private func settleStatusDrawer(horizontal: CGFloat, predictedHorizontal: CGFloat, maxShift: CGFloat) {
        let final = min(max(statusRevealProgress + horizontal / maxShift, 0), 1)
        let predictedFinal = min(max(statusRevealProgress + predictedHorizontal / maxShift, 0), 1)

        if statusRevealProgress > 0.5 {
            if predictedFinal < statusDismissThreshold || final < statusDismissThreshold {
                statusRevealProgress = 0
            } else {
                statusRevealProgress = 1
                destPickerProgress = 0
            }
        } else if predictedFinal > 0.5 || final > statusRevealThreshold {
            statusRevealProgress = 1
            destPickerProgress = 0
        } else {
            statusRevealProgress = 0
        }
    }

    private func settleDestinationPicker(vertical: CGFloat, predictedVertical: CGFloat, maxLift: CGFloat) {
        let final = min(max(destPickerProgress - vertical / maxLift, 0), 1)
        let predictedFinal = min(max(destPickerProgress - predictedVertical / maxLift, 0), 1)

        if destPickerProgress > 0.5 {
            if predictedFinal < destPickerDismissThreshold || final < destPickerDismissThreshold {
                destPickerProgress = 0
            } else {
                destPickerProgress = 1
                statusRevealProgress = 0
            }
        } else if predictedFinal > 0.5 || final > destPickerRevealThreshold {
            destPickerProgress = 1
            statusRevealProgress = 0
        } else {
            destPickerProgress = 0
        }
    }

    private func revealStatus(animated: Bool) {
        let animation = reduceMotion
            ? Animation.easeOut(duration: 0.25)
            : Animation.spring(response: 0.38, dampingFraction: 0.86)

        if animated {
            withAnimation(animation) {
                statusRevealProgress = 1
                statusDragTranslation = 0
                destPickerProgress = 0
                destPickerDragTranslation = 0
            }
        } else {
            statusRevealProgress = 1
            statusDragTranslation = 0
            destPickerProgress = 0
            destPickerDragTranslation = 0
        }
    }

    private func revealDestinationPicker(animated: Bool) {
        guard hasSelectableDestinations else { return }

        let animation = reduceMotion
            ? Animation.easeOut(duration: 0.25)
            : Animation.spring(response: 0.38, dampingFraction: 0.86)

        if animated {
            withAnimation(animation) {
                destPickerProgress = 1
                destPickerDragTranslation = 0
                statusRevealProgress = 0
                statusDragTranslation = 0
            }
        } else {
            destPickerProgress = 1
            destPickerDragTranslation = 0
            statusRevealProgress = 0
            statusDragTranslation = 0
        }
    }

    private func resetStatusReveal(animated: Bool) {
        let animation = reduceMotion
            ? Animation.easeOut(duration: 0.25)
            : Animation.spring(response: 0.38, dampingFraction: 0.86)

        if animated {
            withAnimation(animation) {
                statusRevealProgress = 0
                statusDragTranslation = 0
            }
        } else {
            statusRevealProgress = 0
            statusDragTranslation = 0
        }
    }

    private func resetDestinationPicker(animated: Bool) {
        let animation = reduceMotion
            ? Animation.easeOut(duration: 0.25)
            : Animation.spring(response: 0.38, dampingFraction: 0.86)

        if animated {
            withAnimation(animation) {
                destPickerProgress = 0
                destPickerDragTranslation = 0
            }
        } else {
            destPickerProgress = 0
            destPickerDragTranslation = 0
        }
    }

    private func beginDestinationHold(for location: SavedLocation, origin: UnitPoint) {
        holdOrigin = origin
        userLocationProvider.requestLocation()
        viewModel.selectDestination(location)
        refreshJourneyIntent()

        guard let intent = viewModel.journeyIntent else { return }
        viewModel.preloadRoutes(from: intent.origin, to: location)
    }

    private func completeDestinationHold(for location: SavedLocation, origin: UnitPoint) {
        holdOrigin = origin
        resetDestinationPicker(animated: true)
        revealJourney(from: origin)
    }

    private func cancelDestinationHold() {
        viewModel.cancelPreload()
        if !journeyRevealed, destPickerProgress < 0.02 {
            dragProgress = 0
        }
    }

    private var routeDestination: SavedLocation? {
        viewModel.routeEndpoints(for: appState.userProfile)?.to
    }

    private var directionsDestination: SavedLocation {
        routeDestination
            ?? appState.userProfile.locations.first(where: { $0.label == .home })
            ?? SavedLocation.mock(label: .home)
    }

    private func beginHoldPreload() {
        userLocationProvider.requestLocation()
        refreshJourneyIntent()

        guard let endpoints = viewModel.routeEndpoints(for: appState.userProfile) else { return }
        viewModel.preloadRoutes(from: endpoints.from, to: endpoints.to)
    }

    private func cancelHoldPreload() {
        viewModel.cancelPreload()
        if !journeyRevealed {
            dragProgress = 0
        }
    }

    private func revealJourney(from origin: UnitPoint? = nil) {
        if let origin {
            holdOrigin = origin
        }

        let animation = reduceMotion
            ? Animation.easeOut(duration: 0.25)
            : Animation.spring(response: 0.36, dampingFraction: 0.86)

        withAnimation(animation) {
            dragProgress = 1
            journeyRevealed = true
        }
        journeyDismissEnabled = false
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            guard journeyRevealed else { return }
            journeyDismissEnabled = true
        }
    }

    private func collapseJourney() {
        let animation = reduceMotion
            ? Animation.easeOut(duration: 0.25)
            : Animation.spring(response: 0.42, dampingFraction: 0.84)

        withAnimation(animation) {
            journeyRevealed = false
            dragProgress = 0
            collapseDragOffset = 0
            journeyDismissEnabled = false
        }
        viewModel.resetPreloadState()
    }
}

#Preview {
    HomeView()
        .environmentObject({
            let state = AppState()
            state.userProfile = UserProfile(
                firstName: "Joe",
                useSerif: true,
                accentStyle: .gradient(.pink),
                mapsProvider: .apple,
                locations: [
                    .mock(label: .home),
                    .mock(label: .work),
                    .mock(label: .other, customName: "The Gym")
                ],
                usualRoutes: []
            )
            return state
        }())
}
