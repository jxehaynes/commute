import SwiftUI

struct SwipeableJourneyRouteCard: View {
    let route: Route
    let isSelected: Bool
    let accent: AccentStyle
    var lineDisruptions: [Disruption]
    var statusLastUpdated: Date?
    var statusUnavailable: Bool = false
    var destinationLabel: String
    var isExpandedBinding: Binding<Bool>? = nil
    let onTap: () -> Void
    let onSwipeToDirections: () -> Void

    @State private var horizontalOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let dismissThreshold: CGFloat = 110

    var body: some View {
        JourneyRouteCard(
            route: route,
            isSelected: isSelected,
            accent: accent,
            appearance: .home,
            showsStatus: true,
            lineDisruptions: lineDisruptions,
            statusLastUpdated: statusLastUpdated,
            statusUnavailable: statusUnavailable,
            destinationLabel: destinationLabel,
            isExpandedBinding: isExpandedBinding,
            onTap: onTap
        )
        .offset(x: horizontalOffset)
        .opacity(1 - Double(min(horizontalOffset / 320, 0.35)))
        .highPriorityGesture(horizontalSwipeGesture)
        .overlay(alignment: .leading) {
            if horizontalOffset > 24 {
                directionsHint
                    .opacity(Double(min(horizontalOffset / 80, 1)))
                    .offset(x: -56)
            }
        }
        .accessibilityAction(named: "Open directions") {
            onSwipeToDirections()
        }
    }

    private var directionsHint: some View {
        VStack(spacing: 4) {
            Image(systemName: "arrow.turn.up.right")
                .font(.system(size: 18, weight: .semibold))
            Text("Directions")
                .font(Theme.Fonts.caption)
        }
        .foregroundStyle(.white.opacity(0.85))
    }

    private var horizontalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                let horizontal = value.translation.width
                let vertical = abs(value.translation.height)
                guard horizontal > 0, horizontal > vertical * 0.85 else { return }
                horizontalOffset = horizontal
            }
            .onEnded { value in
                let horizontal = max(0, value.translation.width)
                let predicted = max(0, value.predictedEndTranslation.width)

                if horizontal > dismissThreshold || predicted > 180 {
                    commitSwipeOffScreen()
                } else {
                    resetOffset()
                }
            }
    }

    private func commitSwipeOffScreen() {
        let animation = reduceMotion
            ? Animation.easeOut(duration: 0.22)
            : Animation.spring(response: 0.32, dampingFraction: 0.86)

        withAnimation(animation) {
            horizontalOffset = 420
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.15 : 0.22)) {
            onSwipeToDirections()
            horizontalOffset = 0
        }
    }

    private func resetOffset() {
        withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.38, dampingFraction: 0.82)) {
            horizontalOffset = 0
        }
    }
}

#Preview {
    SwipeableJourneyRouteCard(
        route: Route.mockRoutes(from: .mock(label: .home), to: .mock(label: .work)).first!,
        isSelected: true,
        accent: .gradient(.green),
        lineDisruptions: [],
        statusLastUpdated: .now,
        destinationLabel: "Home",
        onTap: {},
        onSwipeToDirections: {}
    )
    .padding()
    .background(Color.teal)
}
