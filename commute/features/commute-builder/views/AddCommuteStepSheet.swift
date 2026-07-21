import SwiftUI

struct AddCommuteStepSheet: View {
    @ObservedObject var viewModel: CustomCommuteBuilderViewModel
    let accent: AccentStyle
    let mapsProvider: UserProfile.MapsProvider

    private var isStopPhase: Bool {
        viewModel.addPhase == .fromStop || viewModel.addPhase == .toStop
    }

    var body: some View {
        NavigationStack {
            Group {
                if isStopPhase {
                    stopPhaseLayout
                } else {
                    scrollPhaseLayout
                }
            }
            .background(Theme.Colors.backgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.cancelAddingStep() }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .safeAreaInset(edge: .bottom) { footer }
        }
    }

    private var scrollPhaseLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                phaseHeader
                if let chained = viewModel.chainedFromStop, viewModel.addPhase != .mode {
                    ChainedFromBanner(stop: chained, accent: accent)
                }
                phaseContent
            }
            .padding(.horizontal, OnboardingMetrics.horizontalPadding)
            .padding(.top, 16)
            .padding(.bottom, 120)
        }
    }

    private var stopPhaseLayout: some View {
        VStack(alignment: .leading, spacing: 20) {
            phaseHeader
                .padding(.horizontal, OnboardingMetrics.horizontalPadding)
                .padding(.top, 16)

            if let chained = viewModel.chainedFromStop {
                ChainedFromBanner(stop: chained, accent: accent)
                    .padding(.horizontal, OnboardingMetrics.horizontalPadding)
            }

            phaseContent
                .padding(.horizontal, OnboardingMetrics.horizontalPadding)
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private var phaseHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            OnboardingHeadline(parts: headlineParts, centered: false)
            OnboardingSubheadline(text: subtitle, centered: false)
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.addPhase {
        case .mode:
            CommuteStepModePicker(accent: accent) { viewModel.selectMode($0) }
        case .line:
            linePicker
        case .fromStop:
            fromPicker
        case .toStop:
            toPicker
        }
    }

    @ViewBuilder
    private var fromPicker: some View {
        if viewModel.draftMode?.requiresLine == true {
            StopSearchPicker(
                title: "Where does this step start?",
                stops: viewModel.stopOptionsForDraft(),
                selected: viewModel.draftFromStop.nilIfEmpty,
                accent: accent,
                showsLineOrder: true,
                expandsVertically: true,
                onSelect: viewModel.selectFromStop
            )
        } else {
            LivePlaceSearchPicker(
                title: "Where does this step start?",
                selected: viewModel.draftFromStop.nilIfEmpty,
                accent: accent,
                mapsProvider: mapsProvider,
                onSelect: viewModel.selectFromStop
            )
        }
    }

    @ViewBuilder
    private var toPicker: some View {
        if viewModel.draftMode?.requiresLine == true {
            StopSearchPicker(
                title: toStopTitle,
                stops: viewModel.toStopOptions(),
                selected: viewModel.draftToStop.nilIfEmpty,
                accent: accent,
                showsLineOrder: true,
                expandsVertically: true,
                onSelect: { viewModel.draftToStop = $0 }
            )
        } else {
            LivePlaceSearchPicker(
                title: toStopTitle,
                selected: viewModel.draftToStop.nilIfEmpty,
                accent: accent,
                mapsProvider: mapsProvider,
                onSelect: { viewModel.draftToStop = $0 }
            )
        }
    }

    @ViewBuilder
    private var linePicker: some View {
        if viewModel.draftMode == .train {
            VStack(alignment: .leading, spacing: 12) {
                Text("Pick your line")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                    ForEach(LineStopCatalog.trainLines(), id: \.self) { line in
                        Button {
                            viewModel.selectTrainLine(line)
                        } label: {
                            VStack(spacing: 8) {
                                LineChipView(line: line)
                                if viewModel.draftTrainLine == line {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(accent.tintColor)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(viewModel.draftTrainLine == line ? Theme.Colors.backgroundElevated : .clear)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } else if viewModel.draftMode == .bus {
            BusRoutePicker(
                routes: BusRoute.londonRoutes,
                selected: viewModel.draftBusRoute,
                accent: accent,
                onSelect: viewModel.selectBusRoute
            )
        }
    }

    private var footer: some View {
        HStack {
            if viewModel.addPhase != .mode {
                LiquidGlassButton(
                    systemImage: "chevron.left",
                    label: "Back",
                    accentStyle: accent
                ) {
                    goBack()
                }
            } else {
                Color.clear.frame(width: 88, height: 44)
            }
            Spacer()
            AccentGlassContinueButton(
                label: viewModel.addPhase == .toStop ? "Add step" : "Next",
                accentStyle: accent,
                isEnabled: canAdvance,
                action: advance
            )
        }
        .padding(.horizontal, OnboardingMetrics.horizontalPadding)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private var canAdvance: Bool {
        switch viewModel.addPhase {
        case .mode: false
        case .line:
            viewModel.draftMode == .train ? viewModel.draftTrainLine != nil : viewModel.draftBusRoute != nil
        case .fromStop: !viewModel.draftFromStop.isEmpty
        case .toStop: viewModel.canSaveDraft
        }
    }

    private func advance() {
        switch viewModel.addPhase {
        case .line:
            viewModel.addPhase = viewModel.chainedFromStop == nil ? .fromStop : .toStop
        case .fromStop:
            viewModel.addPhase = .toStop
        case .toStop:
            viewModel.confirmDraftStep()
        case .mode:
            break
        }
    }

    private func goBack() {
        switch viewModel.addPhase {
        case .toStop:
            if viewModel.requiresFromPicker {
                viewModel.addPhase = .fromStop
            } else {
                viewModel.addPhase = viewModel.draftMode?.requiresLine == true ? .line : .mode
            }
        case .fromStop:
            viewModel.addPhase = viewModel.draftMode?.requiresLine == true ? .line : .mode
        case .line:
            viewModel.addPhase = .mode
        case .mode:
            break
        }
    }

    private var headlineParts: [OnboardingHeadline.HeadlinePart] {
        switch viewModel.addPhase {
        case .mode: [.plain("Add a "), .serif("step")]
        case .line: [.plain("Pick your "), .serif("line")]
        case .fromStop: [.plain("Where do you "), .serif("start"), .serif("?")]
        case .toStop: [.plain("Where do you "), .serif("finish"), .serif("?")]
        }
    }

    private var subtitle: String {
        switch viewModel.addPhase {
        case .mode: "Walk, drive, bus or train — build the commute you actually take."
        case .line: "Choose the line you'll ride."
        case .fromStop: "This becomes the start of this leg."
        case .toStop: "Your next step will continue from here."
        }
    }

    private var toStopTitle: String {
        viewModel.draftMode?.requiresLine == true ? "Which stop are you heading to?" : "Where are you going?"
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
