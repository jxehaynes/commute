import SwiftUI

struct SavedLocationsEditorView: View {
    @ObservedObject var viewModel: SavedLocationsEditorViewModel
    let accent: AccentStyle
    let mapsProvider: UserProfile.MapsProvider
    let onSave: ([SavedLocation]) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 28) {
                        OnboardingHeadline(
                            parts: [.plain("Edit your "), .serif("places")],
                            centered: false
                        )
                        OnboardingSubheadline(
                            text: "Update Home and Work, or add another place you travel to often.",
                            centered: false
                        )

                        AddressLocationEditor(
                            title: "Start",
                            serifTitle: "Home",
                            icon: "house.fill",
                            address: $viewModel.homeAddress,
                            accent: accent,
                            mapsProvider: mapsProvider,
                            onSelect: { viewModel.selectLocation($0, label: .home) }
                        )

                        AddressLocationEditor(
                            title: "Destination",
                            serifTitle: "Work",
                            icon: "briefcase.fill",
                            address: $viewModel.workAddress,
                            accent: accent,
                            mapsProvider: mapsProvider,
                            onSelect: { viewModel.selectLocation($0, label: .work) }
                        )

                        AddressLocationEditor(
                            title: "Optional",
                            serifTitle: "Other",
                            icon: "star.fill",
                            address: $viewModel.otherAddress,
                            name: $viewModel.otherName,
                            accent: accent,
                            mapsProvider: mapsProvider,
                            onSelect: { viewModel.selectLocation($0, label: .other) }
                        )
                    }
                    .padding(.horizontal, OnboardingMetrics.horizontalPadding)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }

                footer
            }
            .background(Theme.Colors.backgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            AccentGlassContinueButton(
                label: "Save places",
                accentStyle: accent,
                isEnabled: true
            ) {
                onSave(viewModel.buildLocations())
                dismiss()
            }
            .padding(.horizontal, OnboardingMetrics.horizontalPadding)
            .padding(.vertical, 12)
        }
        .background(Theme.Colors.backgroundPrimary)
    }
}

#Preview {
    SavedLocationsEditorView(
        viewModel: SavedLocationsEditorViewModel(),
        accent: NeatConfig.defaultAccent,
        mapsProvider: .apple,
        onSave: { _ in }
    )
}
