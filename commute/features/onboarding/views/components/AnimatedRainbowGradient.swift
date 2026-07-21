import SwiftUI

/// Default onboarding background — Neat preset from `neat-main`.
struct AnimatedRainbowGradient: View {
    var accent: AccentStyle = AccentPalette.defaultStyle
    var speed: Double = 1.0

    var body: some View {
        AnimatedAccentGradient(accent: accent, speed: speed)
    }
}
