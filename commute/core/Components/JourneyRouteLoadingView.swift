import SwiftUI

/// Minimal accent ring loader for journey route fetch.
struct JourneyRouteLoadingView: View {
    let accent: AccentStyle

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let size: CGFloat = 48
    private let lineWidth: CGFloat = 2.5
    private let arcLength: CGFloat = 0.28

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 / 4 : 1 / 60)) { timeline in
            let rotation = reduceMotion
                ? 0
                : timeline.date.timeIntervalSinceReferenceDate * 110

            ZStack {
                Circle()
                    .strokeBorder(.white.opacity(0.22), lineWidth: lineWidth)

                Circle()
                    .trim(from: 0, to: arcLength)
                    .stroke(
                        accentGradient,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(rotation))
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Finding your route")
    }

    private var accentGradient: AngularGradient {
        let colors = accent.neatColors.isEmpty ? NeatConfig.presetColors : accent.neatColors
        let gradientColors = colors.count == 1 ? colors + colors : colors
        return AngularGradient(colors: gradientColors, center: .center)
    }
}

#Preview {
    ZStack {
        NeatGradientView(accentStyle: .gradient(.pink), clipsContent: false)
            .ignoresSafeArea()
        JourneyRouteLoadingView(accent: .gradient(.pink))
    }
}
