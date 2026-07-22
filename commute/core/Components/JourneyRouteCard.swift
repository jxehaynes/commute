import SwiftUI

enum JourneyRouteCardAppearance {
    case home
    case onboarding
}

struct JourneyRouteCard: View {
    let route: Route
    let isSelected: Bool
    let accent: AccentStyle
    var appearance: JourneyRouteCardAppearance = .home
    var showsStatus: Bool = true
    var lineDisruptions: [Disruption] = []
    var statusLastUpdated: Date?
    var statusUnavailable: Bool = false
    var destinationLabel: String = "work"
    var isExpandedBinding: Binding<Bool>? = nil
    let onTap: () -> Void

    @State private var internalIsExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var expansion: Binding<Bool> {
        isExpandedBinding ?? $internalIsExpanded
    }

    private var isExpanded: Bool {
        expansion.wrappedValue
    }

    private var cardExpanded: Bool {
        isSelected || isExpanded
    }

    private var expandAnimation: Animation {
        reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.35, dampingFraction: 0.82)
    }

    var body: some View {
        Button(action: toggleExpansion) {
            VStack(spacing: 0) {
                VStack(spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(route.summary)
                                .font(Theme.Fonts.routeSummary)
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            legIconStrip
                        }
                        VStack(alignment: .trailing, spacing: 0) {
                            Text("\(route.totalMinutes)")
                                .font(.playfairItalic(size: 32))
                                .foregroundStyle(Theme.Colors.textPrimary)
                                .monospacedDigit()
                            Text("mins")
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }

                    if cardExpanded {
                        expandedDetails
                            .transition(
                                reduceMotion
                                    ? .opacity
                                    : .opacity.combined(with: .move(edge: .top))
                            )
                    }
                }
                .padding(18)
                .padding(.bottom, showsStatus ? 4 : 0)

                if showsStatus {
                    RouteStatusPill(
                        status: route.status,
                        disruptions: lineDisruptions,
                        lastUpdated: statusLastUpdated,
                        isInteractive: false,
                        isExpanded: cardExpanded,
                        isUnavailable: statusUnavailable
                    )
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .background { cardBackground }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onChange(of: isSelected) { _, selected in
            withAnimation(expandAnimation) {
                if selected {
                    expansion.wrappedValue = true
                } else if isExpandedBinding == nil {
                    expansion.wrappedValue = false
                }
            }
        }
        .accessibilityLabel("\(route.summary), \(route.totalMinutes) minutes")
        .accessibilityHint(cardExpanded ? "Collapse route details" : "Expand route details")
    }

    private func toggleExpansion() {
        onTap()
        withAnimation(expandAnimation) {
            expansion.wrappedValue.toggle()
        }
    }

    private var legIconStrip: some View {
        HStack(spacing: 10) {
            ForEach(Array(route.legs.enumerated()), id: \.offset) { index, leg in
                legIcon(leg, alternatives: route.groupedAlternatives[index])
            }
        }
    }

    @ViewBuilder
    private func legIcon(_ leg: RouteLeg, alternatives: [TransitLineOption]?) -> some View {
        switch leg {
        case .walk:
            Image(systemName: "figure.walk")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(height: 26)
        case .transit(let line, _, _, _, _, _, let lineLabel):
            if let alternatives, alternatives.count > 1 {
                GroupedTransitLineChipView(options: alternatives)
            } else {
                TransitLineChipView(line: line, lineLabel: lineLabel)
            }
        }
    }

    private var expandedDetails: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(route.legs.enumerated()), id: \.offset) { index, leg in
                legNarrative(leg, index: index, alternatives: route.groupedAlternatives[index])
            }
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func legNarrative(_ leg: RouteLeg, index: Int, alternatives: [TransitLineOption]?) -> some View {
        switch leg {
        case .walk(let _, let distance):
            Text(walkNarrative(distance: distance, index: index))
                .font(Theme.Fonts.bodyEmphasis)
                .foregroundStyle(Theme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        case .transit(let line, _, let to, let departureTime, let platform, let stops, let lineLabel):
            let isGrouped = (alternatives?.count ?? 0) > 1
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if let alternatives, isGrouped {
                        GroupedTransitLineChipView(options: alternatives)
                    } else {
                        TransitLineChipView(line: line, lineLabel: lineLabel)
                    }
                    Text(isGrouped
                         ? transitNarrative(alternatives: alternatives ?? [], to: to)
                         : transitNarrative(line: line, lineLabel: lineLabel, to: to))
                        .font(Theme.Fonts.bodyEmphasis)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    if let platform {
                        Text("Platform \(platform)")
                    }
                    Text("\(stops) stops")
                    if let arrival = arrivalTime(before: departureTime, minutes: 2) {
                        Text("Arrive by \(arrival)")
                    }
                }
                .font(Theme.Fonts.secondary)
                .foregroundStyle(Theme.Colors.textSecondary)

                if let departures = route.upcomingDepartures[index], !departures.isEmpty {
                    nextTrainRow(departures: departures)
                }
            }
        }
    }

    private func walkNarrative(distance: Double, index: Int) -> String {
        let miles = String(format: "%.1f", distance)
        let isLast = index == route.legs.count - 1

        if isLast {
            return "Walk \(miles) miles to \(destinationLabel)"
        }

        if let nextIndex = route.legs.indices.first(where: { $0 > index }),
           case .transit(_, let from, _, _, _, _, _) = route.legs[nextIndex] {
            return "Walk for \(miles) miles to \(from)"
        }

        return "Walk for \(miles) miles"
    }

    private func transitNarrative(line: TfLLine, lineLabel: String?, to: String) -> String {
        if line == .bus || lineLabel?.localizedCaseInsensitiveContains("bus") == true {
            return "Take \(lineLabel ?? "the bus") to \(to)"
        }

        switch line {
        case .elizabethLine:
            return "Get the Elizabeth line to \(to)"
        case .nationalRail, .overground:
            return "Get the train to \(to)"
        default:
            return "Get the tube to \(to)"
        }
    }

    private func transitNarrative(alternatives: [TransitLineOption], to: String) -> String {
        let labels = alternatives.map { TransitLineChipView.shortLabel(line: $0.line, lineLabel: $0.lineLabel) }
        guard let first = alternatives.first else { return "Take transit to \(to)" }

        let isBus = first.line == .bus || first.lineLabel?.localizedCaseInsensitiveContains("bus") == true
        let prefix = isBus ? "Bus " : ""
        return "Take \(prefix)\(labels.joined(separator: " or ")) to \(to)"
    }

    private func nextTrainRow(departures: [Date]) -> some View {
        let formatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter
        }()
        return HStack(spacing: 8) {
            ForEach(departures, id: \.self) { departure in
                Text(formatter.string(from: departure))
                    .font(Theme.Fonts.caption)
                    .monospacedDigit()
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Theme.Colors.backgroundElevated.opacity(0.9))
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private var cardBackground: some View {
        switch appearance {
        case .home:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.Colors.backgroundSurface)
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
                .accentGradientBorder(
                    accent: accent,
                    cornerRadius: 18,
                    lineWidth: 2,
                    isActive: isSelected
                )
        case .onboarding:
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    NeatControlFill(
                        accent: accent,
                        shape: RoundedRectangle(cornerRadius: 18, style: .continuous),
                        presentation: .subtle
                    )
                    .opacity(isSelected ? 0.35 : 0.2)
                }
                .overlay {
                    if !isSelected {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Theme.Colors.border.opacity(0.5), lineWidth: 1)
                    }
                }
                .accentGradientBorder(
                    accent: accent,
                    cornerRadius: 18,
                    lineWidth: 2,
                    isActive: isSelected
                )
        }
    }

    private func arrivalTime(before departureTime: Date?, minutes: Int) -> String? {
        guard let departureTime else { return nil }
        return nextTime(after: departureTime, offset: -minutes)
    }

    private func nextTime(after time: Date, offset: Int) -> String {
        let shifted = time.addingTimeInterval(TimeInterval(offset * 60))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: shifted)
    }
}
