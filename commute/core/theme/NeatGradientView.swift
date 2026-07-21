import SwiftUI

enum AccentGradientPresentation {
    case standard
    case subtle
    /// Full-screen backdrop — softer blobs, lower saturation.
    case immersive

    var opacity: Double {
        switch self {
        case .standard: 1.0
        case .subtle: 0.55
        case .immersive: 1.0
        }
    }

    var blobOpacity: Double {
        switch self {
        case .standard: 0.9
        case .subtle: 0.9
        case .immersive: 0.52
        }
    }

    var colorSaturation: Double {
        switch self {
        case .standard, .subtle: NeatConfig.colorSaturation
        case .immersive: 1.05
        }
    }
}

/// SwiftUI port of the Neat fluid gradient (`neat-main/lib/src/NeatGradient.ts`).
struct NeatGradientView: View {
    var accentStyle: AccentStyle = NeatConfig.defaultAccent
    var speed: Double = 1.0
    var presentation: AccentGradientPresentation = .standard
    /// When false, gradient bleeds past bounds so blur does not clip to hard edges.
    var clipsContent: Bool = true
    /// Canvas wash behind blobs; `nil` skips the base fill (full-bleed backdrops).
    var canvasBase: Color? = NeatConfig.background.opacity(0.10)
    /// Off for full-screen backdrops — compositing can harden edges at bounds.
    var usesCompositingGroup: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let minDim = max(min(geo.size.width, geo.size.height), 1)
            let blurRadius = min(24, minDim * 0.22)

            TimelineView(.animation(minimumInterval: reduceMotion ? 1 / 5 : 1 / 30)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate * NeatConfig.speed * 0.35 * speed
                Canvas { context, size in
                    let colors = accentStyle.neatColors
                    guard !colors.isEmpty else { return }

                    if let canvasBase {
                        context.fill(
                            Path(CGRect(origin: .zero, size: size)),
                            with: .color(canvasBase)
                        )
                    }

                    for index in colors.indices {
                        let phase = time + Double(index) * 1.65
                        let cx = size.width * (
                            0.5 + NeatConfig.horizontalPressure * cos(phase * NeatConfig.waveFrequencyX * 0.15 + Double(index))
                        )
                        let cy = size.height * (
                            0.5 + NeatConfig.verticalPressure * sin(phase * NeatConfig.waveFrequencyY * 0.12 + Double(index) * 0.85)
                        )
                        let radius = max(size.width, size.height) * (
                            0.46 + NeatConfig.waveAmplitude * sin(phase * 0.45)
                        )

                        let rect = CGRect(
                            x: cx - radius,
                            y: cy - radius,
                            width: radius * 2,
                            height: radius * 2
                        )
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(colors[index].opacity(presentation.blobOpacity))
                        )
                    }
                }
                .blur(radius: blurRadius)
                .saturation(presentation.colorSaturation)
            }
        }
        .opacity(presentation.opacity)
        .modifier(ConditionalCompositingGroup(enabled: usesCompositingGroup))
        .modifier(ConditionalClip(enabled: clipsContent))
        .allowsHitTesting(false)
    }
}

private struct ConditionalCompositingGroup: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.compositingGroup()
        } else {
            content
        }
    }
}

private struct ConditionalClip: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.clipped()
        } else {
            content
        }
    }
}

struct AnimatedAccentGradient: View {
    let accent: AccentStyle
    var speed: Double = 1.0
    var presentation: AccentGradientPresentation = .standard

    var body: some View {
        NeatGradientView(accentStyle: accent, speed: speed, presentation: presentation)
    }
}
