import SwiftUI

/// Values from `NEAT_PRESET` in `neat-main/editor/src/components/presets.ts`.
enum NeatConfig {
    static let presetColors: [Color] = [
        Color(hex: "D63D56"),
        Color(hex: "4CB4BB"),
        Color(hex: "D4AF37"),
        Color(hex: "8B6AE6"),
        Color(hex: "2E0EC7"),
        Color(hex: "FF9A9E")
    ]

    static let background = Color(hex: "003FFF")
    static let speed: Double = 2.5
    static let horizontalPressure: Double = 0.12
    static let verticalPressure: Double = 0.14
    static let waveFrequencyX: Double = 2.0
    static let waveFrequencyY: Double = 3.0
    static let waveAmplitude: Double = 0.10
    static let colorSaturation: Double = 1.35

    static var defaultAccent: AccentStyle {
        .gradient(.grey)
    }
}

extension AccentStyle {
    /// Colours fed into the Neat canvas for this accent.
    var neatColors: [Color] {
        switch self {
        case .solid(let solid):
            [solid.color, solid.color, NeatConfig.presetColors[2], NeatConfig.presetColors[4]]
        case .gradient(let gradient):
            gradient.neatColorStops
        }
    }

    var tintColor: Color {
        neatColors.first ?? NeatConfig.presetColors[0]
    }
}
