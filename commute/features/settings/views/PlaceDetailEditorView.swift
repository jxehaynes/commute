import SwiftUI

struct PlaceDetailEditorView: View {
    @Binding var location: SavedLocation
    let accent: AccentStyle
    let mapsProvider: UserProfile.MapsProvider
    let canDelete: Bool
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var addressText = ""
    @State private var nameText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    addressSection
                    PlaceScheduleEditor(schedule: $location.schedule, accent: accent)

                    if canDelete {
                        Button(role: .destructive) {
                            dismiss()
                            onDelete()
                        } label: {
                            Label("Delete place", systemImage: "trash")
                                .font(Theme.Fonts.bodyEmphasis)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(.horizontal, OnboardingMetrics.horizontalPadding)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .background(Theme.Colors.backgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        applyTextEdits()
                        dismiss()
                    }
                    .foregroundStyle(accent.tintColor)
                }
            }
            .onAppear {
                addressText = location.address
                nameText = location.customName ?? ""
            }
            .onDisappear {
                applyTextEdits()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            OnboardingHeadline(
                parts: [.plain("Edit "), .serif(location.displayName)],
                centered: false
            )
            OnboardingSubheadline(
                text: "Set the address and when you usually travel here.",
                centered: false
            )
        }
    }

    @ViewBuilder
    private var addressSection: some View {
        Group {
            if location.label == .other {
                AddressLocationEditor(
                    title: "Place",
                    serifTitle: nameText.isEmpty ? "Somewhere" : nameText,
                    icon: "star.fill",
                    address: $addressText,
                    name: $nameText,
                    accent: accent,
                    mapsProvider: mapsProvider,
                    onSelect: { result in
                        addressText = result.formattedAddress
                        location.address = result.formattedAddress
                        location.coordinate = result.coordinate
                    }
                )
                .onChange(of: nameText) { _, value in
                    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    location.customName = trimmed.isEmpty ? "New place" : trimmed
                }
            } else {
                AddressLocationEditor(
                    title: location.label == .home ? "Start" : "Destination",
                    serifTitle: location.displayName,
                    icon: location.label == .home ? "house.fill" : "briefcase.fill",
                    address: $addressText,
                    accent: accent,
                    mapsProvider: mapsProvider,
                    onSelect: { result in
                        addressText = result.formattedAddress
                        location.address = result.formattedAddress
                        location.coordinate = result.coordinate
                    }
                )
            }
        }
        .onChange(of: addressText) { _, value in
            location.address = value
        }
    }

    private func applyTextEdits() {
        location.address = addressText
        if location.label == .other {
            let trimmed = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
            location.customName = trimmed.isEmpty ? "New place" : trimmed
        }
    }
}
