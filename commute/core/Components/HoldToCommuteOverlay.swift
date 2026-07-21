import SwiftUI
import UIKit

struct HoldToCommuteOverlay: View {
    let accent: AccentStyle
    let isEnabled: Bool
    let destinationName: String?
    @Binding var holdProgress: CGFloat
    /// Normalized location of the touch, fed back so the full-screen bloom can
    /// expand from the same point once the hold completes.
    @Binding var holdOrigin: UnitPoint
    let onHoldStart: () -> Void
    let onHoldComplete: () -> Void
    let onHoldCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var touchLocation: CGPoint?
    @State private var pressStartLocation: CGPoint?
    @State private var holdTask: Task<Void, Never>?
    @State private var didFireHalfwayHaptic = false
    @State private var burstScale: CGFloat = 1

    private let holdDuration: TimeInterval = 2
    private let ringDiameter: CGFloat = 56
    private let maxFingerTravel: CGFloat = 24

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(holdGesture(in: proxy.size))

                if let touchLocation, holdProgress > 0 {
                    thumbRing(at: touchLocation)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isEnabled ? "Press and hold for two seconds" : "Choose a destination first")
        .accessibilityAction(named: "Get directions") {
            guard isEnabled else { return }
            holdProgress = 1
            onHoldStart()
            onHoldComplete()
        }
        .onDisappear {
            // A completed hold removes this overlay (journey reveals), which
            // would otherwise be treated as a cancellation here and wipe the
            // just-preloaded routes out from under the reveal. Only cancel if
            // the hold didn't actually finish, matching the guard in onEnded.
            guard holdProgress < 1 else { return }
            cancelHold(resetProgress: true)
        }
    }

    private var accessibilityLabel: String {
        if let destinationName {
            return "Hold for two seconds to get directions to \(destinationName)"
        }
        return "Hold for two seconds to get directions"
    }

    private func holdGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard isEnabled else { return }

                let clamped = clampedPoint(value.location, in: size)
                touchLocation = clamped
                if size.width > 0, size.height > 0 {
                    holdOrigin = UnitPoint(x: clamped.x / size.width, y: clamped.y / size.height)
                }

                guard holdProgress < 1 else { return }

                if holdTask == nil {
                    pressStartLocation = clamped
                    beginHold(at: clamped)
                } else if let start = pressStartLocation {
                    let dx = value.location.x - start.x
                    let dy = value.location.y - start.y
                    if abs(dx) > abs(dy), abs(dx) > 12 {
                        cancelHold(resetProgress: true)
                    } else if hypot(dx, dy) > maxFingerTravel {
                        cancelHold(resetProgress: true)
                    }
                }
            }
            .onEnded { _ in
                if holdProgress < 1 {
                    cancelHold(resetProgress: true)
                }
            }
    }

    private func beginHold(at location: CGPoint) {
        touchLocation = location
        didFireHalfwayHaptic = false
        onHoldStart()

        holdTask?.cancel()
        holdTask = Task {
            if reduceMotion {
                holdProgress = 1
                fireCompletionHaptic()
                onHoldComplete()
                holdTask = nil
                return
            }

            let steps = 40
            for step in 1...steps {
                try? await Task.sleep(for: .milliseconds(Int(holdDuration * 1000) / steps))
                guard !Task.isCancelled else { return }

                let progress = CGFloat(step) / CGFloat(steps)
                holdProgress = progress

                if progress >= 0.5, !didFireHalfwayHaptic {
                    didFireHalfwayHaptic = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    pulseBurst(to: 1.14)
                }

                if step == steps {
                    fireCompletionHaptic()
                    onHoldComplete()
                    holdTask = nil
                }
            }
        }
    }

    private func cancelHold(resetProgress: Bool) {
        holdTask?.cancel()
        holdTask = nil
        didFireHalfwayHaptic = false
        if resetProgress {
            holdProgress = 0
            touchLocation = nil
            pressStartLocation = nil
        }
        onHoldCancel()
    }

    private func fireCompletionHaptic() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        pulseBurst(to: 1.28)
    }

    private func pulseBurst(to scale: CGFloat) {
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.16, dampingFraction: 0.45)) {
            burstScale = scale
        }
        Task {
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                burstScale = 1
            }
        }
    }

    @ViewBuilder
    private func thumbRing(at location: CGPoint) -> some View {
        bloomGlow
            .scaleEffect(burstScale)
            .position(location)
            .allowsHitTesting(false)
    }

    /// Soft light bleeding out from underneath the thumb, foreshadowing the
    /// full-screen iris bloom this hold will open into. This is the only touch
    /// feedback — no progress ring or color wheel, just the glow growing.
    private var bloomGlow: some View {
        let bloomDiameter = ringDiameter * (1.6 + holdProgress * 4.8)
        return RadialGradient(
            colors: [
                accent.tintColor.opacity(0.5 * holdProgress),
                accent.tintColor.opacity(0.16 * holdProgress),
                .clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: bloomDiameter / 2
        )
        .frame(width: bloomDiameter, height: bloomDiameter)
        .blur(radius: 8)
        .allowsHitTesting(false)
    }

    private func clampedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        let inset = ringDiameter / 2 + 8
        return CGPoint(
            x: min(max(point.x, inset), size.width - inset),
            y: min(max(point.y, inset), size.height - inset)
        )
    }
}

#Preview {
    @Previewable @State var progress: CGFloat = 0
    @Previewable @State var origin: UnitPoint = .center

    HoldToCommuteOverlay(
        accent: NeatConfig.defaultAccent,
        isEnabled: true,
        destinationName: "Work",
        holdProgress: $progress,
        holdOrigin: $origin,
        onHoldStart: {},
        onHoldComplete: {},
        onHoldCancel: {}
    )
}
