import SwiftUI

struct AccentColorGridPicker: View {
    @Binding var selection: AccentStyle

    private let options = AccentPalette.presetOptions
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 4)
    private let swatchSize: CGFloat = 52
    private let cellSize: CGFloat = 68

    var body: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(options.enumerated()), id: \.offset) { _, style in
                    AccentColorSwatch(
                        style: style,
                        isSelected: selection == style,
                        swatchSize: swatchSize,
                        cellSize: cellSize
                    ) {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                            selection = style
                        }
                    }
                }
            }

            Text(selection.displayName)
                .font(Theme.Fonts.secondary)
                .foregroundStyle(Theme.Colors.textSecondary)
                .animation(.easeInOut(duration: 0.2), value: selection)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AccentColorSwatch: View {
    let style: AccentStyle
    let isSelected: Bool
    let swatchSize: CGFloat
    let cellSize: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isSelected {
                    Circle()
                        .strokeBorder(Theme.Colors.textPrimary.opacity(0.12), lineWidth: 2)
                        .frame(width: swatchSize + 10, height: swatchSize + 10)

                    Circle()
                        .strokeBorder(style.tintColor, lineWidth: 2.5)
                        .frame(width: swatchSize + 5, height: swatchSize + 5)
                }

                NeatControlFill(accent: style, shape: Circle(), speed: 0.85)
                    .frame(width: swatchSize, height: swatchSize)
                    .overlay {
                        Circle()
                            .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                    }
                    .shadow(
                        color: .black.opacity(isSelected ? 0.18 : 0.1),
                        radius: isSelected ? 6 : 3,
                        y: 2
                    )
            }
            .frame(width: cellSize, height: cellSize)
            .contentShape(Circle())
            .scaleEffect(isSelected ? 1.04 : 1)
            .animation(.spring(response: 0.34, dampingFraction: 0.78), value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(style.displayName)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    @Previewable @State var selection: AccentStyle = .gradient(.blue)

    AccentColorGridPicker(selection: $selection)
        .padding(.horizontal, 32)
        .background(Theme.Colors.backgroundPrimary)
}
