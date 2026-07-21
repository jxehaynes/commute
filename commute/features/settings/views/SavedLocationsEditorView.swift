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
                            text: "Home and Work are pinned. Add as many other places as you need.",
                            centered: false
                        )

                        homeWorkSection
                        extrasSection
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
            .sheet(isPresented: Binding(
                get: { viewModel.editingLocationID != nil },
                set: { if !$0 { viewModel.editingLocationID = nil } }
            ), onDismiss: {
                viewModel.clearStaleEditingLocations()
            }) {
                if let id = viewModel.editingLocationID,
                   let binding = viewModel.binding(for: id) {
                    PlaceDetailEditorView(
                        location: binding,
                        accent: accent,
                        mapsProvider: mapsProvider,
                        canDelete: viewModel.canDelete(binding.wrappedValue),
                        onDelete: {
                            viewModel.deleteExtra(id: id)
                        }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var homeWorkSection: some View {
        if let home = viewModel.homeBinding {
            AddressLocationEditor(
                title: "Start",
                serifTitle: "Home",
                icon: "house.fill",
                address: homeAddressBinding(home),
                accent: accent,
                mapsProvider: mapsProvider,
                onSelect: { applySearchResult($0, to: home) }
            )
        }

        if let work = viewModel.workBinding {
            AddressLocationEditor(
                title: "Destination",
                serifTitle: "Work",
                icon: "briefcase.fill",
                address: workAddressBinding(work),
                accent: accent,
                mapsProvider: mapsProvider,
                onSelect: { applySearchResult($0, to: work) }
            )
        }
    }

    private var extrasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Other places")
                .font(Theme.Fonts.bodyEmphasis)
                .foregroundStyle(Theme.Colors.textPrimary)

            if viewModel.extraLocations.isEmpty {
                Text("Gym, partner's place, parents — add anywhere you travel to often.")
                    .font(Theme.Fonts.secondary)
                    .foregroundStyle(Theme.Colors.textSecondary)
            } else {
                ForEach(viewModel.extraLocations) { location in
                    Button {
                        viewModel.editingLocationID = location.id
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(accent.tintColor)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(location.displayName)
                                    .font(Theme.Fonts.bodyEmphasis)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Text(location.address.isEmpty ? "Tap to set address" : location.address)
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.Colors.textTertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Theme.Colors.backgroundSurface)
                        }
                    }
                    .buttonStyle(OnboardingPressStyle())
                }
            }

            Button {
                viewModel.addExtra()
            } label: {
                Label("Add place", systemImage: "plus.circle.fill")
                    .font(Theme.Fonts.bodyEmphasis)
                    .foregroundStyle(accent.tintColor)
            }
            .buttonStyle(OnboardingPressStyle())
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

    private func homeAddressBinding(_ home: Binding<SavedLocation>) -> Binding<String> {
        Binding(
            get: { home.wrappedValue.address },
            set: { home.wrappedValue.address = $0 }
        )
    }

    private func workAddressBinding(_ work: Binding<SavedLocation>) -> Binding<String> {
        Binding(
            get: { work.wrappedValue.address },
            set: { work.wrappedValue.address = $0 }
        )
    }

    private func applySearchResult(_ result: ResolvedLocationSearchResult, to binding: Binding<SavedLocation>) {
        binding.wrappedValue.address = result.formattedAddress
        binding.wrappedValue.coordinate = result.coordinate
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
