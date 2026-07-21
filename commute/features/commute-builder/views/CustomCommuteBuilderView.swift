import SwiftUI

struct CustomCommuteBuilderView: View {
    @ObservedObject var viewModel: CustomCommuteBuilderViewModel
    let accent: AccentStyle
    var mapsProvider: UserProfile.MapsProvider = .apple
    let onSave: (CustomCommuteRoute, SavedLocation, SavedLocation) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.phase {
                case .chooseJourney:
                    chooseJourneyPhase
                case .steps:
                    stepsPhase
                }
            }
            .background(Theme.Colors.backgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .sheet(isPresented: $viewModel.isAddingStep) {
                AddCommuteStepSheet(
                    viewModel: viewModel,
                    accent: accent,
                    mapsProvider: mapsProvider
                )
            }
        }
    }

    private var stepsPhase: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    OnboardingHeadline(
                        parts: [.plain("Build your "), .serif("commute")],
                        centered: false
                    )
                    OnboardingSubheadline(
                        text: "Add each leg of your journey. Each step picks up where the last one left off.",
                        centered: false
                    )

                    journeyHeader

                    if viewModel.steps.isEmpty {
                        emptyState
                    } else {
                        stepsList
                        autoFinishHint
                    }

                    addStepButton
                }
                .padding(.horizontal, OnboardingMetrics.horizontalPadding)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }

            footer
        }
    }

    @ViewBuilder
    private var journeyHeader: some View {
        if let pair = viewModel.resolvedPair {
            HStack(spacing: 10) {
                Image(systemName: "arrow.forward.circle.fill")
                    .foregroundStyle(accent.tintColor)
                Text("\(pair.from.displayName) → \(pair.to.displayName)")
                    .font(Theme.Fonts.bodyEmphasis)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                if !viewModel.isJourneyLocked {
                    Button("Change") { viewModel.changeJourney() }
                        .font(Theme.Fonts.secondary)
                        .foregroundStyle(accent.tintColor)
                }
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accent.tintColor.opacity(0.1))
            }
        }
    }

    @ViewBuilder
    private var autoFinishHint: some View {
        if let destination = viewModel.pendingAutoFinishLabel {
            HStack(spacing: 8) {
                Image(systemName: "flag.checkered.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textTertiary)
                Text("Finishes automatically at \(destination)")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(.leading, 6)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(accent.tintColor.opacity(0.7))
            Text("No steps yet")
                .font(Theme.Fonts.bodyEmphasis)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("Tap below to add your first walk, drive, bus or train leg.")
                .font(Theme.Fonts.secondary)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.Colors.backgroundElevated.opacity(0.6))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Theme.Colors.border.opacity(0.35), lineWidth: 1)
                }
        }
    }

    private var stepsList: some View {
        VStack(spacing: 12) {
            ForEach(Array(viewModel.steps.enumerated()), id: \.element.id) { index, step in
                if index > 0 {
                    HStack {
                        Rectangle()
                            .fill(accent.tintColor.opacity(0.35))
                            .frame(width: 2, height: 16)
                            .padding(.leading, 19)
                        Spacer()
                    }
                }
                CommuteBuilderStepRow(step: step, accent: accent) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        viewModel.removeStep(step)
                    }
                }
            }
        }
    }

    private var addStepButton: some View {
        Button {
            viewModel.startAddingStep()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Add a step")
                    .font(Theme.Fonts.bodyEmphasis)
            }
            .foregroundStyle(accent.tintColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accent.tintColor.opacity(0.1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(accent.tintColor.opacity(0.35), lineWidth: 1.5)
                    }
            }
        }
        .buttonStyle(OnboardingPressStyle())
        .accessibilityLabel("Add a step")
    }

    private var footer: some View {
        HStack {
            Spacer()
            AccentGlassContinueButton(
                label: "Save route",
                accentStyle: accent,
                isEnabled: viewModel.canSaveRoute,
                action: save
            )
        }
        .padding(.horizontal, OnboardingMetrics.horizontalPadding)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func save() {
        guard let pair = viewModel.resolvedPair else { return }
        let configuration = viewModel.buildConfiguration()
        onSave(configuration, pair.from, pair.to)
        dismiss()
    }

    private var chooseJourneyPhase: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    OnboardingHeadline(
                        parts: [.plain("Which "), .serif("journey"), .plain(" is this?")],
                        centered: false
                    )
                    OnboardingSubheadline(
                        text: "Pick two saved places. Commute keeps a separate route for each direction.",
                        centered: false
                    )

                    SavedLocationPicker(
                        title: "From",
                        locations: viewModel.availableLocations,
                        selected: viewModel.originLocation,
                        accent: accent,
                        onSelect: viewModel.selectOrigin
                    )

                    if viewModel.originLocation != nil {
                        HStack {
                            Spacer()
                            Button {
                                viewModel.swapJourneyDirection()
                            } label: {
                                Image(systemName: "arrow.up.arrow.down.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(accent.tintColor)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Swap direction")
                            Spacer()
                        }
                    }

                    SavedLocationPicker(
                        title: "To",
                        locations: viewModel.availableLocations,
                        selected: viewModel.destinationLocation,
                        accent: accent,
                        onSelect: viewModel.selectDestination
                    )

                    if let reverseSuggestion = viewModel.reverseSuggestion,
                       let pair = viewModel.resolvedPair {
                        reverseSuggestionBanner(reverseSuggestion, pair: pair)
                    }
                }
                .padding(.horizontal, OnboardingMetrics.horizontalPadding)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }

            HStack {
                Spacer()
                AccentGlassContinueButton(
                    label: "Continue",
                    accentStyle: accent,
                    isEnabled: viewModel.canConfirmJourney,
                    action: viewModel.confirmJourneySelection
                )
            }
            .padding(.horizontal, OnboardingMetrics.horizontalPadding)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }

    private func reverseSuggestionBanner(
        _ suggestion: CustomCommuteRoute,
        pair: (from: SavedLocation, to: SavedLocation)
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("You already have a \(pair.to.displayName) → \(pair.from.displayName) route.")
                .font(Theme.Fonts.secondary)
                .foregroundStyle(Theme.Colors.textPrimary)
            Button("Start from a reversed copy") {
                viewModel.applyReverseSuggestion()
            }
            .font(Theme.Fonts.bodyEmphasis)
            .foregroundStyle(accent.tintColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(accent.tintColor.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(accent.tintColor.opacity(0.3), lineWidth: 1)
                }
        }
    }
}

private struct SavedLocationPicker: View {
    let title: String
    let locations: [SavedLocation]
    let selected: SavedLocation?
    let accent: AccentStyle
    let onSelect: (SavedLocation) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Theme.Fonts.bodyEmphasis)
                .foregroundStyle(Theme.Colors.textPrimary)

            if locations.isEmpty {
                Text("Add saved places in Settings first.")
                    .font(Theme.Fonts.secondary)
                    .foregroundStyle(Theme.Colors.textSecondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(locations) { location in
                        Button {
                            onSelect(location)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(selected?.id == location.id ? accent.tintColor : Theme.Colors.textTertiary)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(location.displayName)
                                        .font(Theme.Fonts.bodyEmphasis)
                                        .foregroundStyle(Theme.Colors.textPrimary)
                                    if !location.address.isEmpty {
                                        Text(location.address)
                                            .font(Theme.Fonts.caption)
                                            .foregroundStyle(Theme.Colors.textSecondary)
                                            .lineLimit(1)
                                    }
                                }

                                Spacer(minLength: 8)

                                if selected?.id == location.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(accent.tintColor)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                            .background {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Theme.Colors.backgroundSurface)
                                    .overlay {
                                        if selected?.id == location.id {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .strokeBorder(accent.tintColor.opacity(0.45), lineWidth: 1.5)
                                        }
                                    }
                            }
                        }
                        .buttonStyle(OnboardingPressStyle())
                    }
                }
            }
        }
    }
}

#Preview {
    let viewModel = CustomCommuteBuilderViewModel()
    viewModel.configure(availableLocations: [
        SavedLocation.mock(label: .home),
        SavedLocation.mock(label: .work, customName: "Work")
    ])
    return CustomCommuteBuilderView(
        viewModel: viewModel,
        accent: .gradient(.green),
        onSave: { _, _, _ in }
    )
}
