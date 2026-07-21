import SwiftUI

/// The user's chosen accent, picked from a grid in Settings and applied
/// throughout the app — icon badges, toggles, buttons, and the Live Activity.
public enum AccentStyle: String, Codable, CaseIterable, Hashable, Sendable {
    case indigo
    case teal
    case coral
    case amber
    case violet

    public var tintColor: Color {
        switch self {
        case .indigo: Color(hex: "#5856D6")
        case .teal: Color(hex: "#2FB0C7")
        case .coral: Color(hex: "#FF6B5B")
        case .amber: Color(hex: "#FFB020")
        case .violet: Color(hex: "#AF52DE")
        }
    }

    private var secondaryColor: Color {
        switch self {
        case .indigo: Color(hex: "#7A79E8")
        case .teal: Color(hex: "#63D6C9")
        case .coral: Color(hex: "#FF9478")
        case .amber: Color(hex: "#FFD060")
        case .violet: Color(hex: "#D97BE0")
        }
    }

    /// Diagonal gradient used for icon badges and the "leave now" emphasis fill.
    public var gradient: LinearGradient {
        LinearGradient(
            colors: [tintColor, secondaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// A soft, low-opacity wash of the accent for chip/pill backgrounds.
    public func softBackground(opacity: Double = 0.14) -> Color {
        tintColor.opacity(opacity)
    }

    public var displayName: String {
        switch self {
        case .indigo: "Indigo"
        case .teal: "Teal"
        case .coral: "Coral"
        case .amber: "Amber"
        case .violet: "Violet"
        }
    }
}
