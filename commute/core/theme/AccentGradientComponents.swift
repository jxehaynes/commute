import SwiftUI

// MARK: - Neat control fills (single engine for all UI chrome)

/// Scales `NeatGradientView` to cover the control bounds, then clips to `shape`.
struct NeatControlFill<S: Shape>: View {
    let accent: AccentStyle
    let shape: S
    var speed: Double = 1.0
    var presentation: AccentGradientPresentation = .standard

    private let minRenderSize: CGFloat = 120

    var body: some View {
        Rectangle()
            .fill(.clear)
            .background {
                GeometryReader { proxy in
                    let side = max(max(proxy.size.width, proxy.size.height), minRenderSize)
                    NeatGradientView(
                        accentStyle: accent,
                        speed: speed,
                        presentation: presentation
                    )
                    .frame(width: side, height: side)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                }
                .allowsHitTesting(false)
            }
            .compositingGroup()
            .clipShape(shape)
            .allowsHitTesting(false)
    }
}

struct AccentGradientUnderline: View {
    let accent: AccentStyle
    var height: CGFloat = 3.5
    var isActive: Bool = true
    var speed: Double = 1.0

    var body: some View {
        NeatControlFill(accent: accent, shape: Capsule(), speed: speed)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .opacity(isActive ? 1 : 0.35)
            .allowsHitTesting(false)
    }
}

struct AccentGradientIcon: View {
    let systemName: String
    let accent: AccentStyle
    var fontSize: CGFloat = 56
    var speed: Double = 0.9

    var body: some View {
        NeatControlFill(accent: accent, shape: Circle(), speed: speed)
            .mask {
                Image(systemName: systemName)
                    .font(.system(size: fontSize))
            }
            .frame(width: fontSize * 1.15, height: fontSize * 1.15)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct AccentGradientCircle: View {
    let accent: AccentStyle
    var diameter: CGFloat = 44
    var systemImage: String?
    var iconSize: CGFloat = 18
    var speed: Double = 0.85

    var body: some View {
        ZStack {
            NeatControlFill(accent: accent, shape: Circle(), speed: speed)
                .frame(width: diameter, height: diameter)
                .allowsHitTesting(false)

            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
            }
        }
        .frame(width: diameter, height: diameter)
    }
}

struct AccentButtonBackground: View {
    let accent: AccentStyle
    var speed: Double = 0.85

    var body: some View {
        NeatControlFill(accent: accent, shape: Capsule(), speed: speed)
    }
}

struct AccentProgressFill: View {
    let accent: AccentStyle

    var body: some View {
        NeatControlFill(accent: accent, shape: Capsule(), speed: 0.7)
    }
}

struct UnderlineTextField: View {
    let placeholder: String
    @Binding var text: String
    let accent: AccentStyle
    var font: Font = Theme.Fonts.routeSummary
    var accessibilityLabel: String
    var focusBinding: FocusState<Bool>.Binding?

    @FocusState private var internalFocus: Bool

    private var isFocused: Bool {
        focusBinding?.wrappedValue ?? internalFocus
    }

    private var underlineActive: Bool {
        isFocused || !text.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let focusBinding {
                    TextField(placeholder, text: $text)
                        .focused(focusBinding)
                } else {
                    TextField(placeholder, text: $text)
                        .focused($internalFocus)
                }
            }
            .font(font)
            .foregroundStyle(Theme.Colors.textPrimary)
            .padding(.vertical, 4)
            .accessibilityLabel(accessibilityLabel)

            AccentGradientUnderline(accent: accent, height: 3, isActive: underlineActive)
                .animation(.easeInOut(duration: 0.25), value: isFocused)
                .animation(.easeInOut(duration: 0.25), value: text.isEmpty)
        }
    }
}

extension View {
    func accentGradientBorder(
        accent: AccentStyle,
        cornerRadius: CGFloat,
        lineWidth: CGFloat = 2,
        isActive: Bool = true
    ) -> some View {
        overlay {
            if isActive {
                NeatControlFill(accent: accent, shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .mask {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(lineWidth: lineWidth)
                    }
                    .allowsHitTesting(false)
            }
        }
    }
}

struct AccentGradientToggle: View {
    let label: String
    @Binding var isOn: Bool
    let accent: AccentStyle

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(label)
                .font(Theme.Fonts.bodyEmphasis)
        }
        .toggleStyle(AccentGradientToggleStyle(accent: accent))
        .accessibilityLabel(label)
    }
}

struct AccentGradientToggleStyle: ToggleStyle {
    let accent: AccentStyle

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer()
            ZStack {
                if configuration.isOn {
                    NeatControlFill(
                        accent: accent,
                        shape: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.Colors.backgroundElevated)
                }
            }
            .frame(width: 51, height: 31)
            .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
                    .padding(2)
                    .frame(width: 27, height: 27)
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    configuration.isOn.toggle()
                }
            }
        }
    }
}
