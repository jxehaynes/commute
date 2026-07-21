import SwiftUI

struct CommuteStepModePicker: View {
    let accent: AccentStyle
    let onSelect: (CommuteStepMode) -> Void

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(CommuteStepMode.allCases) { mode in
                Button {
                    onSelect(mode)
                } label: {
                    VStack(spacing: 10) {
                        Image(systemName: mode.systemImage)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(accent.tintColor)
                        Text(mode.label)
                            .font(Theme.Fonts.bodyEmphasis)
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay {
                                NeatControlFill(
                                    accent: accent,
                                    shape: RoundedRectangle(cornerRadius: 16, style: .continuous),
                                    presentation: .subtle
                                )
                                .opacity(0.22)
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Theme.Colors.border.opacity(0.4), lineWidth: 1)
                            }
                    }
                }
                .buttonStyle(OnboardingPressStyle())
                .accessibilityLabel("Add \(mode.label) step")
            }
        }
    }
}

struct CommuteBuilderStepRow: View {
    let step: CommuteBuilderStep
    let accent: AccentStyle
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.tintColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: step.mode.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accent.tintColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(step.summary)
                    .font(Theme.Fonts.bodyEmphasis)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(step.estimatedMinutes) min")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Spacer(minLength: 8)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove step")
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.Colors.backgroundSurface)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                .accentGradientBorder(accent: accent, cornerRadius: 16, lineWidth: 1.5, isActive: false)
        }
    }
}

struct StopSearchPicker: View {
    let title: String
    let stops: [String]
    let selected: String?
    let accent: AccentStyle
    var showsLineOrder: Bool = false
    var expandsVertically: Bool = false
    let onSelect: (String) -> Void

    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var filteredStops: [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return stops }
        return stops.filter { $0.localizedCaseInsensitiveContains(trimmed) }
    }

    private var listHeight: CGFloat {
        let rowHeight: CGFloat = 52
        let spacing: CGFloat = 8
        let content = CGFloat(filteredStops.count) * rowHeight
            + CGFloat(max(filteredStops.count - 1, 0)) * spacing
            + 8
        return min(max(content, 120), 9999)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            searchField
            listSection
                .layoutPriority(1)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Theme.Fonts.bodyEmphasis)
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer(minLength: 8)
            Text(stops.count == 1 ? "1 stop" : "\(stops.count) stops")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(searchFocused ? accent.tintColor : Theme.Colors.textTertiary)

            TextField("Search stops", text: $query)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.textPrimary)
                .focused($searchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.Colors.backgroundSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            searchFocused ? accent.tintColor.opacity(0.55) : Theme.Colors.border.opacity(0.6),
                            lineWidth: searchFocused ? 1.5 : 1
                        )
                }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Search stops")
    }

    @ViewBuilder
    private var listSection: some View {
        if filteredStops.isEmpty {
            emptyResults
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredStops, id: \.self) { stop in
                        StopPickerRow(
                            stop: stop,
                            lineIndex: showsLineOrder ? lineIndex(for: stop) : nil,
                            isSelected: selected == stop,
                            accent: accent,
                            onSelect: { onSelect(stop) }
                        )
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: expandsVertically ? .infinity : listHeight)
            .scrollIndicators(.visible)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.Colors.backgroundElevated.opacity(0.45))
            }
        }
    }

    private var emptyResults: some View {
        VStack(spacing: 8) {
            Image(systemName: "tram.fill.tunnel")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Theme.Colors.textTertiary)
            Text("No stops match “\(query)”")
                .font(Theme.Fonts.secondary)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.Colors.backgroundElevated.opacity(0.45))
        }
    }

    private func lineIndex(for stop: String) -> Int? {
        guard let index = stops.firstIndex(of: stop) else { return nil }
        return index + 1
    }
}

struct LivePlaceSearchPicker: View {
    let title: String
    let selected: String?
    let accent: AccentStyle
    let mapsProvider: UserProfile.MapsProvider
    let onSelect: (String) -> Void

    @State private var query = ""
    @State private var isResolving = false
    @StateObject private var searchModel = LocationSearchViewModel()
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            searchField
            if let selected, !selected.isEmpty {
                selectedPlaceRow(selected)
            }
            suggestionsPanel
                .layoutPriority(1)
        }
        .onAppear {
            searchModel.useProvider(for: mapsProvider)
            query = selected ?? ""
        }
        .onChange(of: mapsProvider) { _, provider in
            searchModel.useProvider(for: provider)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Theme.Fonts.bodyEmphasis)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(mapsProvider.isLocationSearchEnabled ? "Search live addresses and places" : "Type this address manually")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(searchFocused ? accent.tintColor : Theme.Colors.textTertiary)

            TextField("Search address or place", text: $query)
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.textPrimary)
                .focused($searchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .onChange(of: query) { _, value in
                    searchModel.updateQuery(value)
                }

            if !query.isEmpty {
                Button {
                    query = ""
                    searchModel.clear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.Colors.backgroundSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            searchFocused ? accent.tintColor.opacity(0.55) : Theme.Colors.border.opacity(0.6),
                            lineWidth: searchFocused ? 1.5 : 1
                        )
                }
        }
    }

    @ViewBuilder
    private var suggestionsPanel: some View {
        if searchModel.isSearching || isResolving || !searchModel.suggestions.isEmpty {
            ScrollView {
                LazyVStack(spacing: 8) {
                    if searchModel.isSearching || isResolving {
                        HStack(spacing: 10) {
                            ProgressView()
                                .controlSize(.small)
                            Text(isResolving ? "Checking place..." : "Searching MapKit...")
                                .font(Theme.Fonts.secondary)
                                .foregroundStyle(Theme.Colors.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(rowBackground)
                    }

                    ForEach(searchModel.suggestions.prefix(8)) { suggestion in
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
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(rowBackground)
                        }
                        .buttonStyle(OnboardingPressStyle())
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: .infinity)
            .scrollIndicators(.visible)
        }
    }

    private func selectedPlaceRow(_ place: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(accent.tintColor)
            Text(place)
                .font(Theme.Fonts.secondary)
                .foregroundStyle(Theme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(accent.tintColor.opacity(0.1))
        }
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Theme.Colors.backgroundSurface)
            .shadow(color: .black.opacity(0.03), radius: 3, y: 1)
    }

    private func select(_ suggestion: LocationSearchSuggestion) {
        isResolving = true
        Task {
            defer { isResolving = false }
            guard let result = await searchModel.resolve(suggestion) else { return }
            query = result.formattedAddress
            searchFocused = false
            searchModel.clear()
            onSelect(result.formattedAddress)
        }
    }
}

private struct StopPickerRow: View {
    let stop: String
    let lineIndex: Int?
    let isSelected: Bool
    let accent: AccentStyle
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                leadingMarker

                Text(stop)
                    .font(Theme.Fonts.bodyEmphasis)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(accent.tintColor)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background { rowBackground }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(OnboardingPressStyle())
        .accessibilityLabel(stop)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    @ViewBuilder
    private var leadingMarker: some View {
        if let lineIndex {
            Text("\(lineIndex)")
                .font(Theme.Fonts.lineChip)
                .foregroundStyle(isSelected ? accent.tintColor : Theme.Colors.textSecondary)
                .frame(width: 28, height: 28)
                .background {
                    Circle()
                        .fill(isSelected ? accent.tintColor.opacity(0.14) : Theme.Colors.backgroundSurface)
                }
        } else {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(isSelected ? accent.tintColor : Theme.Colors.textTertiary)
        }
    }

    @ViewBuilder
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(isSelected ? Theme.Colors.backgroundSurface : Theme.Colors.backgroundSurface.opacity(0.85))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(accent.tintColor.opacity(0.45), lineWidth: 1.5)
                }
            }
            .shadow(color: .black.opacity(isSelected ? 0.06 : 0.03), radius: isSelected ? 6 : 3, y: 1)
    }
}

struct BusRoutePicker: View {
    let routes: [BusRoute]
    let selected: BusRoute?
    let accent: AccentStyle
    let onSelect: (BusRoute) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Pick your bus route")
                .font(Theme.Fonts.bodyEmphasis)
                .foregroundStyle(Theme.Colors.textPrimary)

            VStack(spacing: 8) {
                ForEach(routes) { route in
                    Button {
                        onSelect(route)
                    } label: {
                        HStack(spacing: 12) {
                            routeBadge(for: route)

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Route \(route.displayNumber)")
                                    .font(Theme.Fonts.bodyEmphasis)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Text(route.name)
                                    .font(Theme.Fonts.caption)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer(minLength: 8)

                            if selected == route {
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
                                    if selected == route {
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

    private func routeBadge(for route: BusRoute) -> some View {
        Text(route.displayNumber)
            .font(Theme.Fonts.lineChip)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(TfLLine.bus.brandColor)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct ChainedFromBanner: View {
    let stop: String
    let accent: AccentStyle

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "link")
                .font(.system(size: 13, weight: .semibold))
            (Text("Starting from ")
                .font(Theme.Fonts.secondary)
             + Text(stop)
                .font(Theme.Fonts.bodyEmphasis))
        }
        .foregroundStyle(Theme.Colors.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(accent.tintColor.opacity(0.1))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(accent.tintColor.opacity(0.25), lineWidth: 1)
                }
        }
    }
}
