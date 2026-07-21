import SwiftUI

struct AddressLocationEditor: View {
    let title: String
    let serifTitle: String
    let icon: String
    @Binding var address: String
    var name: Binding<String>?
    let accent: AccentStyle
    let mapsProvider: UserProfile.MapsProvider
    var onSelect: (ResolvedLocationSearchResult) -> Void

    @FocusState private var addressFocused: Bool
    @State private var showSuggestions = false
    @State private var isResolving = false
    @StateObject private var searchModel = LocationSearchViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                AccentGradientCircle(
                    accent: accent,
                    diameter: 44,
                    systemImage: icon
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Text(serifTitle)
                        .font(.playfairItalic(size: 24))
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            }

            if let name {
                UnderlineTextField(
                    placeholder: "Label (e.g. Gym)",
                    text: name,
                    accent: accent,
                    accessibilityLabel: "Location name"
                )
            }

            UnderlineTextField(
                placeholder: "Search address",
                text: $address,
                accent: accent,
                accessibilityLabel: "\(title) address",
                focusBinding: $addressFocused
            )
            .onChange(of: addressFocused) { _, focused in
                showSuggestions = focused && address.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
                if !focused {
                    searchModel.clear()
                }
            }
            .onChange(of: address) { _, _ in
                showSuggestions = addressFocused && address.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
                searchModel.updateQuery(address)
            }
            .onChange(of: mapsProvider) { _, provider in
                searchModel.useProvider(for: provider)
            }
            .onAppear {
                searchModel.useProvider(for: mapsProvider)
            }

            if !mapsProvider.isLocationSearchEnabled {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(mapsProvider.displayName) search is coming soon. You can still type the address manually.")
                        .font(Theme.Fonts.caption)
                }
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if showSuggestions {
                suggestionsPanel
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showSuggestions)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: searchModel.suggestions)
    }

    @ViewBuilder
    private var suggestionsPanel: some View {
        if searchModel.isSearching || isResolving || !searchModel.suggestions.isEmpty {
            VStack(spacing: 0) {
                if searchModel.isSearching || isResolving {
                    HStack(spacing: 10) {
                        ProgressView()
                            .controlSize(.small)
                        Text(isResolving ? "Checking address..." : "Searching London...")
                            .font(Theme.Fonts.secondary)
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                }

                ForEach(searchModel.suggestions.prefix(6)) { suggestion in
                    Button {
                        select(suggestion)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(accent.tintColor)
                                .frame(width: 22, height: 22)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(suggestion.title)
                                    .font(Theme.Fonts.bodyEmphasis)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                    .multilineTextAlignment(.leading)

                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(Theme.Fonts.secondary)
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                        .multilineTextAlignment(.leading)
                                }
                            }

                            Spacer(minLength: 8)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if suggestion.id != searchModel.suggestions.prefix(6).last?.id {
                        Divider()
                    }
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.Colors.backgroundSurface)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private func select(_ suggestion: LocationSearchSuggestion) {
        isResolving = true
        Task {
            defer { isResolving = false }
            guard let result = await searchModel.resolve(suggestion) else { return }
            address = result.formattedAddress
            showSuggestions = false
            addressFocused = false
            searchModel.clear()
            onSelect(result)
        }
    }
}
