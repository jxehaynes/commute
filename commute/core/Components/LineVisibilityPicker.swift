import SwiftUI

/// Lets a user choose which transit line categories they want surfaced across
/// the app, with National Rail expanding to individual London-area operators.
/// Shared between onboarding and Settings so both stay in sync.
struct LineVisibilityPicker: View {
    @Binding var preferences: LineVisibilityPreferences
    let accent: AccentStyle

    var body: some View {
        VStack(spacing: 14) {
            ForEach(TransitLineCategory.allCases) { category in
                CategoryToggleRow(
                    category: category,
                    isOn: binding(for: category),
                    accent: accent
                )

                if category == .nationalRail, preferences.isEnabled(.nationalRail) {
                    NationalRailOperatorList(preferences: $preferences)
                        .padding(.leading, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: preferences.enabledCategories)
    }

    private func binding(for category: TransitLineCategory) -> Binding<Bool> {
        Binding(
            get: { preferences.isEnabled(category) },
            set: { preferences.setEnabled($0, for: category) }
        )
    }
}

private struct CategoryToggleRow: View {
    let category: TransitLineCategory
    @Binding var isOn: Bool
    let accent: AccentStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                CategorySwatch(colors: category.representativeColors)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.displayName)
                        .font(Theme.Fonts.bodyEmphasis)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(category.summary)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .toggleStyle(AccentGradientToggleStyle(accent: accent))
                    .frame(width: 51)
            }
            .padding(.vertical, 10)

            Rectangle()
                .fill(Theme.Colors.divider)
                .frame(height: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.displayName). \(category.summary)")
    }
}

private struct CategorySwatch: View {
    let colors: [Color]

    private let diameter: CGFloat = 34

    var body: some View {
        ZStack {
            ForEach(Array(colors.prefix(4).enumerated()), id: \.offset) { index, color in
                let count = min(colors.count, 4)
                Circle()
                    .fill(color)
                    .frame(width: segmentSize(for: count), height: segmentSize(for: count))
                    .offset(offset(for: index, count: count))
            }
        }
        .frame(width: diameter, height: diameter)
    }

    private func segmentSize(for count: Int) -> CGFloat {
        count <= 1 ? diameter : diameter * 0.62
    }

    private func offset(for index: Int, count: Int) -> CGSize {
        guard count > 1 else { return .zero }
        let radius = diameter * 0.22
        let angle = (2 * Double.pi / Double(count)) * Double(index) - .pi / 2
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }
}

private struct NationalRailOperatorList: View {
    @Binding var preferences: LineVisibilityPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Which operators?")
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textTertiary)

            ForEach(TransitLineCategory.londonAreaNationalRailOperators, id: \.self) { line in
                OperatorRow(
                    line: line,
                    isSelected: preferences.enabledNationalRailOperators.contains(line)
                ) {
                    preferences.toggleNationalRailOperator(line)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct OperatorRow: View {
    let line: TfLLine
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                TfLLineRoundelView(line: line, size: 22)
                Text(line.displayName)
                    .font(Theme.Fonts.secondary)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Theme.Colors.statusGood : Theme.Colors.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
