import SwiftUI

struct SwipeableActiveCommuteCard: View {
    let route: Route
    let destinationLabel: String
    let minutesUntilLeave: Int?
    let leaveByTime: String?
    let accent: AccentStyle
    var lineDisruptions: [Disruption] = []
    var statusLastUpdated: Date?
    var statusUnavailable: Bool = false
    let onSwipeToDirections: () -> Void

    @State private var horizontalOffset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let dismissThreshold: CGFloat = 100

    var body: some View {
        ActiveCommuteCard(
            route: route,
            destinationLabel: destinationLabel,
            minutesUntilLeave: minutesUntilLeave,
            leaveByTime: leaveByTime,
            accent: accent,
            lineDisruptions: lineDisruptions,
            statusLastUpdated: statusLastUpdated,
            statusUnavailable: statusUnavailable
        )
        .offset(x: horizontalOffset)
        .opacity(1 - Double(min(horizontalOffset / 300, 0.3)))
        .overlay(alignment: .leading) {
            if horizontalOffset > 20 {
                directionsHint
                    .opacity(Double(min(horizontalOffset / 70, 1)))
                    .padding(.leading, 18)
            }
        }
        .highPriorityGesture(horizontalSwipeGesture)
        .accessibilityLabel("Active commute to \(destinationLabel)")
        .accessibilityHint("Swipe right to start navigation")
        .accessibilityAction(named: "Start navigation") {
            onSwipeToDirections()
        }
    }

    private var directionsHint: some View {
        VStack(spacing: 4) {
            Image(systemName: "location.fill")
                .font(.system(size: 18, weight: .semibold))
            Text("Go")
                .font(Theme.Fonts.caption)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.black.opacity(0.18), in: Capsule())
    }

    private var horizontalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                let horizontal = value.translation.width
                let vertical = abs(value.translation.height)
                guard horizontal > 0, horizontal > vertical else { return }
                horizontalOffset = horizontal
            }
            .onEnded { value in
                let horizontal = max(0, value.translation.width)
                let predicted = max(0, value.predictedEndTranslation.width)

                if horizontal > dismissThreshold || predicted > 160 {
                    commitSwipe()
                } else {
                    resetOffset()
                }
            }
    }

    private func commitSwipe() {
        let animation = reduceMotion
            ? Animation.easeOut(duration: 0.22)
            : Animation.spring(response: 0.32, dampingFraction: 0.86)

        withAnimation(animation) {
            horizontalOffset = 440
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.14 : 0.2)) {
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
