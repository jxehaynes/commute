import CommuteKit
import SwiftUI

extension LiveActivityAccent {
    init(accentStyle: AccentStyle) {
        switch accentStyle {
        case .solid(let solid):
            let hex = solid.hexString
            self.init(tintHex: hex, secondaryHex: hex)
        case .gradient(let gradient):
            let stops = gradient.neatColorStops
            let tint = stops.first?.hexString ?? "#5856D6"
            let secondary = stops.dropFirst().first?.hexString ?? tint
            self.init(tintHex: tint, secondaryHex: secondary)
        }
    }
}

private extension SolidAccent {
    var hexString: String {
        switch self {
        case .blue: "#007AFF"
        case .purple: "#AF52DE"
        case .pink: "#FF2D55"
        case .red: "#FF3B30"
        case .orange: "#FF9500"
        case .yellow: "#FFCC00"
        case .green: "#34C759"
        case .graphite: "#8E8E93"
        }
    }
}

private extension Color {
    var hexString: String {
        #if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "#%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
        #else
        return "#5856D6"
        #endif
    }
}
