import SwiftUI

/// Radial mask that blooms outward from a point — like a portal opening — rather
/// than wiping across the screen. `origin` is the point the reveal grows from
/// (typically wherever the user's thumb was holding).
struct AirIrisMask: View {
    let progress: CGFloat
    var origin: UnitPoint = .center

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let clamped = min(max(progress, 0), 1)
            let center = CGPoint(x: size.width * origin.x, y: size.height * origin.y)
            let corners = [
                CGPoint(x: 0, y: 0),
                CGPoint(x: size.width, y: 0),
                CGPoint(x: 0, y: size.height),
                CGPoint(x: size.width, y: size.height)
            ]
            let maxRadius = corners.reduce(CGFloat(1)) { partial, corner in
                max(partial, hypot(corner.x - center.x, corner.y - center.y))
            }

            // Slight ease-out on the growth curve so the bloom opens quickly
            // then settles into place, rather than expanding linearly. Always
            // renders a RadialGradient (never swaps to Color.clear) so the mask
            // never changes view identity mid-reveal, which was causing a flash.
            let eased = clamped >= 1 ? 1 : pow(clamped, 0.78)
            let radius = max(maxRadius * eased, 0.01)
            let feather: CGFloat = clamped >= 0.98
                ? 0
                : min(radius * 0.55, max(maxRadius * 0.16, 24))

            RadialGradient(
                stops: [
                    .init(color: .white, location: 0),
                    .init(color: .white, location: max(0, 1 - feather / radius)),
                    .init(color: .clear, location: 1)
                ],
                center: origin,
                startRadius: 0,
                endRadius: radius
            )
        }
    }
}

/// Soft rising mask — gradient bleeds in like air rather than a hard horizontal edge.
struct AirRisingMask: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            let height = geo.size.height
            let clamped = min(max(progress, 0), 1)
            let revealed = height * clamped
            let feather: CGFloat = clamped >= 0.98
                ? 0
                : min(height * 0.2, max(revealed * 0.42, height * 0.06))

            VStack(spacing: 0) {
                Spacer(minLength: max(height - revealed, 0))

                if feather > 1 {
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.18), location: 0.2),
                            .init(color: .white.opacity(0.55), location: 0.55),
                            .init(color: .white, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: feather)
                }

                if revealed > feather {
                    Rectangle()
                        .fill(.white)
                        .frame(height: revealed - feather)
                }
            }
        }
    }
}

/// Top vignette when the gradient fills the screen — eases into the status bar.
struct AirTopAtmosphere: View {
    let accent: AccentStyle
    var strength: Double = 0.35

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Theme.Colors.backgroundPrimary.opacity(strength), location: 0),
                .init(color: Theme.Colors.backgroundPrimary.opacity(strength * 0.35), location: 0.45),
                .init(color: .clear, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview("Rising") {
    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()
        Color.teal
            .mask { AirRisingMask(progress: 0.65) }
            .ignoresSafeArea()
    }
}
