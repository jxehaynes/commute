import SwiftUI

/// Serializable accent colours for the Live Activity widget extension.
public struct LiveActivityAccent: Codable, Hashable, Sendable {
    public var tintHex: String
    public var secondaryHex: String

    public init(tintHex: String, secondaryHex: String) {
        self.tintHex = tintHex
        self.secondaryHex = secondaryHex
    }

    public var tintColor: Color {
        Color(hex: tintHex)
    }

    public var gradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: tintHex), Color(hex: secondaryHex)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public func softBackground(opacity: Double = 0.14) -> Color {
        tintColor.opacity(opacity)
    }
}
