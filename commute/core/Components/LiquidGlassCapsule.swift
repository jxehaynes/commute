import SwiftUI

struct LiquidGlassBackground<S: InsettableShape>: View {
    let accentStyle: AccentStyle
    let shape: S
    var fillOpacity: Double = 0.38
    var presentation: AccentGradientPresentation = .subtle

    var body: some View {
        shape
            .fill(.ultraThinMaterial)
            .overlay {
                NeatControlFill(
                    accent: accentStyle,
                    shape: shape,
                    speed: 0.5,
                    presentation: presentation
                )
                .opacity(fillOpacity)
            }
            .overlay {
                shape.strokeBorder(.white.opacity(0.52), lineWidth: 0.5)
            }
    }
}

struct LiquidGlassCapsule<Content: View>: View {
    let accentStyle: AccentStyle
    var fillOpacity: Double = 0.36
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .background {
                LiquidGlassBackground(
                    accentStyle: accentStyle,
                    shape: Capsule(),
                    fillOpacity: fillOpacity
                )
            }
    }
}

struct LiquidGlassPanel<Content: View>: View {
    let accentStyle: AccentStyle
    var cornerRadius: CGFloat = 18
    var fillOpacity: Double = 0.4
    @ViewBuilder let content: () -> Content

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    var body: some View {
        content()
            .background {
                LiquidGlassBackground(
                    accentStyle: accentStyle,
                    shape: shape,
                    fillOpacity: fillOpacity
                )
            }
            .clipShape(shape)
            .shadow(color: .black.opacity(0.06), radius: 20, y: 8)
    }
}
