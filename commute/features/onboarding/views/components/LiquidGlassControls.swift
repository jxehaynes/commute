import SwiftUI

struct LiquidGlassButton: View {
    let systemImage: String
    let label: String
    let accentStyle: AccentStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .semibold))
                Text(label)
                    .font(Theme.Fonts.bodyEmphasis)
            }
            .foregroundStyle(Theme.Colors.textPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background { glassBackground }
        }
        .buttonStyle(OnboardingPressStyle())
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var glassBackground: some View {
        Capsule()
            .fill(.ultraThinMaterial)
            .overlay {
                NeatControlFill(accent: accentStyle, shape: Capsule(), speed: 0.6)
                    .opacity(0.35)
            }
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.45), lineWidth: 0.5)
            }
    }
}

struct OnboardingPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct AccentGlassContinueButton: View {
    let label: String
    let accentStyle: AccentStyle
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(label)
                    .font(Theme.Fonts.bodyEmphasis)
                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background { continueBackground }
        }
        .buttonStyle(OnboardingPressStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel(label)
        .accessibilityHint("Continue to the next step")
    }

    @ViewBuilder
    private var continueBackground: some View {
        AccentButtonBackground(accent: accentStyle)
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.3), lineWidth: 0.5)
            }
    }
}

typealias RainbowGlassContinueButton = AccentGlassContinueButton
