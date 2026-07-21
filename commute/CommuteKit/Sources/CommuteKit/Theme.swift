import SwiftUI

/// Shared design tokens for Commute, consumed by both the app and the
/// Live Activity / widget extension so both render from one source of truth.
public enum Theme {
    public enum Colors {
        public static let backgroundPrimary = Color(
            dynamic: (light: "#F7F6F3", dark: "#0B0D10")
        )
        public static let backgroundSurface = Color(
            dynamic: (light: "#FFFFFF", dark: "#16191D")
        )
        public static let textPrimary = Color(
            dynamic: (light: "#14171A", dark: "#F2F1EE")
        )
        public static let textSecondary = Color(
            dynamic: (light: "#6B6F76", dark: "#9CA0A6")
        )
        public static let statusOnTime = Color(hex: "#34C759")
        public static let statusWarning = Color(hex: "#FF9F0A")
        public static let statusDisrupted = Color(hex: "#FF3B30")
    }

    public enum Fonts {
        /// Semibold body text used for labels, values, and button titles.
        public static let bodyEmphasis = Font.system(.body, design: .rounded).weight(.semibold)
        /// Regular secondary body text.
        public static let secondary = Font.system(.subheadline, design: .default)
        /// Small supporting text.
        public static let caption = Font.system(.caption, design: .default)
        /// The serif accent used for the highlighted word inside a headline
        /// (e.g. "Your **Commute** settings").
        public static let serifAccent = Font.system(.title2, design: .serif).weight(.semibold)
        /// The plain portion of a headline.
        public static let headline = Font.system(.title2, design: .default).weight(.semibold)
    }

    public enum Metrics {
        public static let cardCornerRadius: CGFloat = 18
        public static let badgeDiameter: CGFloat = 34
        public static let horizontalPadding: CGFloat = 20
    }
}

extension Color {
    /// A color that adapts between light and dark appearance, defined from hex strings.
    init(dynamic pair: (light: String, dark: String)) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: pair.dark) : UIColor(hex: pair.light)
        })
        #else
        self.init(hex: pair.light)
        #endif
    }

    init(hex: String) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor(hex: hex))
        #else
        self = .primary
        #endif
    }
}

#if canImport(UIKit)
extension UIColor {
    convenience init(hex: String) {
        var trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        if trimmed.count == 6 { trimmed.append("FF") }
        let value = UInt64(trimmed, radix: 16) ?? 0
        let r = CGFloat((value & 0xFF00_0000) >> 24) / 255
        let g = CGFloat((value & 0x00FF_0000) >> 16) / 255
        let b = CGFloat((value & 0x0000_FF00) >> 8) / 255
        let a = CGFloat(value & 0x0000_00FF) / 255
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
#endif
