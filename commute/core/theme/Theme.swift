import SwiftUI
import UIKit

enum Theme {

    enum Colors {
        static let primary = Color.adaptive(
            light: UIColor(red: 0.10, green: 0.44, blue: 0.71, alpha: 1),
            dark: UIColor(red: 0.30, green: 0.64, blue: 1.00, alpha: 1)
        )
        static let primaryMuted = Color.adaptive(
            light: UIColor(red: 0.85, green: 0.92, blue: 0.98, alpha: 1),
            dark: UIColor(red: 0.12, green: 0.22, blue: 0.34, alpha: 1)
        )
        static let accent = Color.adaptive(
            light: UIColor(red: 0.00, green: 0.66, blue: 0.59, alpha: 1),
            dark: UIColor(red: 0.20, green: 0.86, blue: 0.76, alpha: 1)
        )

        static let backgroundPrimary = Color.adaptive(
            light: UIColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1),
            dark: UIColor(red: 0.051, green: 0.051, blue: 0.059, alpha: 1)
        )
        static let backgroundSurface = Color.adaptive(
            light: .white,
            dark: UIColor(red: 0.102, green: 0.102, blue: 0.118, alpha: 1)
        )
        static let backgroundElevated = Color.adaptive(
            light: UIColor(red: 0.922, green: 0.922, blue: 0.941, alpha: 1),
            dark: UIColor(red: 0.141, green: 0.141, blue: 0.157, alpha: 1)
        )

        static let textPrimary = Color.adaptive(
            light: UIColor(red: 0.102, green: 0.102, blue: 0.118, alpha: 1),
            dark: UIColor(red: 0.941, green: 0.941, blue: 0.949, alpha: 1)
        )
        static let textSecondary = Color.adaptive(
            light: UIColor(red: 0.431, green: 0.431, blue: 0.502, alpha: 1),
            dark: UIColor(red: 0.541, green: 0.541, blue: 0.604, alpha: 1)
        )
        static let textTertiary = Color.adaptive(
            light: UIColor(red: 0.55, green: 0.59, blue: 0.64, alpha: 1),
            dark: UIColor(red: 0.48, green: 0.52, blue: 0.57, alpha: 1)
        )
        static let textInverse = Color.adaptive(
            light: .white,
            dark: UIColor(red: 0.10, green: 0.11, blue: 0.13, alpha: 1)
        )

        static let border = Color.adaptive(
            light: UIColor(red: 0.86, green: 0.88, blue: 0.91, alpha: 1),
            dark: UIColor(red: 0.22, green: 0.25, blue: 0.30, alpha: 1)
        )
        static let divider = Color.adaptive(
            light: UIColor(red: 0.90, green: 0.92, blue: 0.94, alpha: 1),
            dark: UIColor(red: 0.18, green: 0.21, blue: 0.25, alpha: 1)
        )

        static let statusGood = Color.adaptive(
            light: UIColor(red: 0.204, green: 0.780, blue: 0.349, alpha: 1),
            dark: UIColor(red: 0.188, green: 0.820, blue: 0.345, alpha: 1)
        )
        static let statusWarning = Color.adaptive(
            light: UIColor(red: 1.000, green: 0.584, blue: 0.000, alpha: 1),
            dark: UIColor(red: 1.000, green: 0.624, blue: 0.039, alpha: 1)
        )
        static let statusDisrupted = Color.adaptive(
            light: UIColor(red: 1.000, green: 0.231, blue: 0.188, alpha: 1),
            dark: UIColor(red: 1.000, green: 0.271, blue: 0.227, alpha: 1)
        )

        static let routeLine = accent
        static let onTime = statusGood
        static let delayed = statusWarning
    }

    enum Fonts {
        static let display = Font.system(size: 34, weight: .regular, design: .default)
        static let routeSummary = Font.system(size: 17, weight: .regular, design: .default)
        static let routeTime = Font.system(size: 17, weight: .semibold, design: .default)
        static let journeyDetail = Font.system(size: 15, weight: .regular, design: .default)
        static let secondary = Font.system(size: 13, weight: .regular, design: .default)
        static let lineChip = Font.system(size: 13, weight: .semibold, design: .default)
        static let body = Font.system(.body, design: .default, weight: .regular)
        static let bodyEmphasis = Font.system(.body, design: .default, weight: .medium)
        static let caption = Font.system(.caption, design: .default, weight: .regular)
    }
}

// MARK: - Accent Colour

enum AccentStyle: Equatable {
    case solid(SolidAccent)
    case gradient(GradientAccent)
}

extension AccentStyle: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let value = try container.decode(String.self, forKey: .value)
        switch type {
        case "solid":
            guard let accent = SolidAccent(rawValue: value) else {
                throw DecodingError.dataCorruptedError(forKey: .value, in: container, debugDescription: "Invalid solid accent")
            }
            self = .solid(accent)
        case "gradient":
            guard let accent = GradientAccent.migrated(from: value) else {
                throw DecodingError.dataCorruptedError(forKey: .value, in: container, debugDescription: "Invalid gradient accent")
            }
            self = .gradient(accent)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid accent type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .solid(let accent):
            try container.encode("solid", forKey: .type)
            try container.encode(accent.rawValue, forKey: .value)
        case .gradient(let accent):
            try container.encode("gradient", forKey: .type)
            try container.encode(accent.rawValue, forKey: .value)
        }
    }
}

enum SolidAccent: String, Codable, CaseIterable {
    case blue, purple, pink, red, orange, yellow, green, graphite

    var color: Color {
        switch self {
        case .blue: Color(uiColor: .systemBlue)
        case .purple: Color(uiColor: .systemPurple)
        case .pink: Color(uiColor: .systemPink)
        case .red: Color(uiColor: .systemRed)
        case .orange: Color(uiColor: .systemOrange)
        case .yellow: Color(uiColor: .systemYellow)
        case .green: Color(uiColor: .systemGreen)
        case .graphite: Color(uiColor: .systemGray)
        }
    }
}

enum GradientAccent: String, Codable, CaseIterable {
    /// Full NEAT preset — available for previews; not the onboarding default.
    case neat
    case red, orange, yellow, green, blue, purple, pink, grey

    /// Eight hues evenly spaced on the wheel (~45° apart), shown in the accent picker.
    static let pickerCases: [GradientAccent] = [
        .red, .orange, .yellow, .green, .blue, .purple, .pink, .grey
    ]

    /// Maps legacy saved accent names to the new palette.
    static func migrated(from rawValue: String) -> GradientAccent? {
        if let match = GradientAccent(rawValue: rawValue) { return match }
        switch rawValue {
        case "prism", "dusk", "solar": return .orange
        case "aurora": return .green
        case "deepSpace": return .blue
        case "monochrome": return .grey
        default: return nil
        }
    }

    var label: String {
        switch self {
        case .neat: "Rainbow"
        case .red: "Red"
        case .orange: "Orange"
        case .yellow: "Gold"
        case .green: "Green"
        case .blue: "Blue"
        case .purple: "Purple"
        case .pink: "Pink"
        case .grey: "Grey"
        }
    }

    /// Colours fed into the Neat canvas — derived from `NeatConfig.presetColors`.
    var neatColorStops: [Color] {
        switch self {
        case .neat:
            NeatConfig.presetColors
        case .red:
            [
                Color(hex: "D63D56"),
                Color(hex: "C93348"),
                Color(hex: "B82E3F"),
                Color(hex: "E8506A")
            ]
        case .orange:
            [
                Color(hex: "FFC600"),
                Color(hex: "FF9F0A"),
                Color(hex: "FF8C42"),
                Color(hex: "FF6B4A")
            ]
        case .yellow:
            [
                Color(hex: "C9A227"),
                Color(hex: "D4AF37"),
                Color(hex: "B8860B"),
                Color(hex: "E6C35C")
            ]
        case .green:
            [
                Color(hex: "4CB4BB"),
                Color(hex: "32D74B"),
                Color(hex: "3DB878"),
                Color(hex: "00C9B1")
            ]
        case .blue:
            [
                Color(hex: "2E0EC7"),
                Color(hex: "003FFF"),
                Color(hex: "4CB4BB"),
                Color(hex: "0066FF")
            ]
        case .purple:
            [
                Color(hex: "8B6AE6"),
                Color(hex: "7B5EA7"),
                Color(hex: "BF5AF2"),
                Color(hex: "2E0EC7")
            ]
        case .pink:
            [
                Color(hex: "FF9A9E"),
                Color(hex: "FF5772"),
                Color(hex: "FF375F"),
                Color(hex: "FFB4B8")
            ]
        case .grey:
            [
                Color(hex: "3A3A3C"),
                Color(hex: "636366"),
                Color(hex: "8E8E93"),
                Color(hex: "AEAEB2")
            ]
        }
    }

    var stops: [Gradient.Stop] {
        neatColorStops.enumerated().map { index, color in
            .init(
                color: color,
                location: Double(index) / Double(max(neatColorStops.count - 1, 1))
            )
        }
    }
}

enum AccentPalette {
    /// Used across the app until the user completes the accent colour step.
    static let defaultStyle: AccentStyle = NeatConfig.defaultAccent

    static let presetOptions: [AccentStyle] = GradientAccent.pickerCases.map { .gradient($0) }
}

extension AccentStyle {
    var displayName: String {
        switch self {
        case .solid(let solid): solid.rawValue.capitalized
        case .gradient(let gradient): gradient.label
        }
    }

    @ViewBuilder
    var background: some View {
        AnimatedAccentGradient(accent: self)
    }
}

private extension Color {
    static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(
            uiColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
}

extension View {
    func themeFont(_ style: Font) -> some View {
        self.font(style)
    }

    func themeForeground(_ color: Color) -> some View {
        foregroundStyle(color)
    }

    func themeBackground(_ color: Color) -> some View {
        background(color)
    }
}
