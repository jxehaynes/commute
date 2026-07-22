import SwiftUI
import UIKit

struct HomeDestinationBubblesView: View {
    let destinations: [SavedLocation]
    let accent: AccentStyle
    let revealProgress: CGFloat
    let containerSize: CGSize
    let bottomInset: CGFloat
    let maxLift: CGFloat
    @Binding var pickerDragTranslation: CGFloat
    @Binding var holdProgress: CGFloat
    @Binding var holdOrigin: UnitPoint
    let onHoldStart: (SavedLocation, UnitPoint) -> Void
    let onHoldComplete: (SavedLocation, UnitPoint) -> Void
    let onHoldCancel: () -> Void
    let onPickerDragEnded: (_ vertical: CGFloat, _ predictedVertical: CGFloat) -> Void
    let onDismiss: () -> Void

    @State private var activeHoldDestinationID: UUID?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: onDismiss)
                .gesture(pickerDismissGesture)

            bubbleCluster
                .padding(.bottom, bottomInset + 36)
                .padding(.horizontal, OnboardingMetrics.horizontalPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Theme.Colors.backgroundPrimary
                .opacity(0.55 * Double(revealAmount))
                .ignoresSafeArea()
        }
        .allowsHitTesting(revealProgress > 0.12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Choose a destination")
        .accessibilityHint("Hold a place for two seconds, or swipe down to close")
    }

    private var revealAmount: CGFloat {
        min(max(revealProgress, 0), 1)
    }

    private var bubbleCluster: some View {
        ZStack(alignment: .bottom) {
            ForEach(Array(destinations.enumerated()), id: \.element.id) { index, destination in
                let placement = Self.placement(
                    for: index,
                    count: destinations.count,
                    containerWidth: containerSize.width
                )
                let motion = bubbleMotion(for: placement)

                HoldDestinationBubble(
                    destination: destination,
                    accent: accent,
                    containerSize: containerSize,
                    isActiveHold: activeHoldDestinationID == destination.id,
                    holdProgress: holdProgressBinding(for: destination.id),
                    holdOrigin: $holdOrigin,
                    onHoldBegan: { activeHoldDestinationID = destination.id },
                    onHoldStart: onHoldStart,
                    onHoldComplete: { location, origin in
                        activeHoldDestinationID = nil
                        onHoldComplete(location, origin)
                    },
                    onHoldCancel: {
                        if activeHoldDestinationID == destination.id {
                            activeHoldDestinationID = nil
                        }
                        onHoldCancel()
                    }
                )
                .scaleEffect(motion.scale, anchor: .bottom)
                .offset(x: motion.xOffset, y: motion.yOffset)
                .rotationEffect(.degrees(motion.rotation), anchor: .bottom)
                .opacity(motion.opacity)
                .blur(radius: motion.blur)
                .zIndex(Double(destinations.count - index))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private func holdProgressBinding(for destinationID: UUID) -> Binding<CGFloat> {
        Binding(
            get: {
                activeHoldDestinationID == destinationID ? holdProgress : 0
            },
            set: { newValue in
                guard activeHoldDestinationID == destinationID || newValue == 0 else { return }
                holdProgress = newValue
            }
        )
    }

    private struct BubbleMotion {
        let scale: CGFloat
        let xOffset: CGFloat
        let yOffset: CGFloat
        let rotation: Double
        let opacity: Double
        let blur: CGFloat
    }

    private func bubbleMotion(for placement: BubblePlacement) -> BubbleMotion {
        let linear = bubbleProgress(for: placement)
        let pop = Self.easeOutBack(linear)
        let travel = Self.easeOutExpo(linear)
        let fade = Self.smoothStep(linear)

        return BubbleMotion(
            scale: 0.08 + 0.92 * pop,
            xOffset: placement.xOffset * travel,
            yOffset: placement.yOffset * travel + (1 - travel) * 26,
            rotation: placement.rotation * travel,
            opacity: fade,
            blur: (1 - fade) * 3.5
        )
    }

    private func bubbleProgress(for placement: BubblePlacement) -> CGFloat {
        let stagger = placement.delay
        guard revealAmount > stagger else { return 0 }
        let span = max(1 - stagger, 0.01)
        return min((revealAmount - stagger) / span, 1)
    }

    private var pickerDismissGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard vertical > 0, abs(vertical) > abs(horizontal) * 0.85 else { return }
                pickerDragTranslation = -vertical
            }
            .onEnded { value in
                onPickerDragEnded(
                    value.translation.height,
                    value.predictedEndTranslation.height
                )
                pickerDragTranslation = 0
            }
    }

    private struct BubblePlacement {
        let xOffset: CGFloat
        let yOffset: CGFloat
        let rotation: Double
        let delay: CGFloat
    }

    private static func easeOutBack(_ value: CGFloat) -> CGFloat {
        let t = min(max(value, 0), 1)
        let c1 = 1.70158
        let c3 = c1 + 1
        let x = t - 1
        return 1 + c3 * x * x * x + c1 * x * x
    }

    private static func easeOutExpo(_ value: CGFloat) -> CGFloat {
        let t = min(max(value, 0), 1)
        guard t < 1 else { return 1 }
        return 1 - pow(2, -10 * t)
    }

    private static func smoothStep(_ value: CGFloat) -> CGFloat {
        let t = min(max(value, 0), 1)
        return t * t * (3 - 2 * t)
    }

    private static func placement(for index: Int, count: Int, containerWidth: CGFloat) -> BubblePlacement {
        let spread = min(containerWidth * 0.22, 88)

        switch count {
        case 1:
            return BubblePlacement(xOffset: 6, yOffset: -108, rotation: 0.8, delay: 0.04)
        case 2:
            return index == 0
                ? BubblePlacement(xOffset: -spread * 0.92, yOffset: -92, rotation: -3.2, delay: 0.02)
                : BubblePlacement(xOffset: spread * 0.78, yOffset: -118, rotation: 2.6, delay: 0.1)
        case 3:
            switch index {
            case 0: return BubblePlacement(xOffset: -spread * 1.05, yOffset: -78, rotation: -4.5, delay: 0)
            case 1: return BubblePlacement(xOffset: 10, yOffset: -138, rotation: 0.4, delay: 0.07)
            default: return BubblePlacement(xOffset: spread * 1.02, yOffset: -86, rotation: 4.2, delay: 0.13)
            }
        case 4:
            switch index {
            case 0: return BubblePlacement(xOffset: -spread * 1.15, yOffset: -62, rotation: -5, delay: 0)
            case 1: return BubblePlacement(xOffset: -spread * 0.18, yOffset: -132, rotation: -1.2, delay: 0.06)
            case 2: return BubblePlacement(xOffset: spread * 0.72, yOffset: -124, rotation: 2.8, delay: 0.11)
            default: return BubblePlacement(xOffset: spread * 1.18, yOffset: -68, rotation: 5.5, delay: 0.16)
            }
        default:
            let angle = -42 + Double(index) * (84 / Double(max(count - 1, 1)))
            let radians = angle * .pi / 180
            let radius = spread * (0.85 + CGFloat(index % 2) * 0.18)
            return BubblePlacement(
                xOffset: sin(radians) * radius + CGFloat(index.isMultiple(of: 2) ? -8 : 10),
                yOffset: -72 - cos(radians) * radius * 0.95 - CGFloat(index / 2) * 28,
                rotation: angle * 0.08,
                delay: CGFloat(index) * 0.05
            )
        }
    }
}

private struct HoldDestinationBubble: View {
    let destination: SavedLocation
    let accent: AccentStyle
    let containerSize: CGSize
    let isActiveHold: Bool
    @Binding var holdProgress: CGFloat
    @Binding var holdOrigin: UnitPoint
    let onHoldBegan: () -> Void
    let onHoldStart: (SavedLocation, UnitPoint) -> Void
    let onHoldComplete: (SavedLocation, UnitPoint) -> Void
    let onHoldCancel: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var touchLocation: CGPoint?
    @State private var pressStartLocation: CGPoint?
    @State private var holdTask: Task<Void, Never>?
    @State private var didFireHalfwayHaptic = false
    @State private var burstScale: CGFloat = 1
    @State private var holdOriginPoint: UnitPoint = .center

    private let holdDuration: TimeInterval = 2
    private let ringDiameter: CGFloat = 56
    private let maxFingerTravel: CGFloat = 28

    var body: some View {
        bubbleLabel
            .overlay {
                GeometryReader { geo in
                    Color.clear
                        .contentShape(Capsule())
                        .highPriorityGesture(holdGesture(buttonFrame: geo.frame(in: .named("homeRoot"))))
                }
            }
            .overlay {
                if isActiveHold, let touchLocation, holdProgress > 0 {
                    bloomGlow
                        .scaleEffect(burstScale)
                        .position(touchLocation)
                        .allowsHitTesting(false)
                }
            }
            .scaleEffect(isActiveHold && holdProgress > 0 ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isActiveHold && holdProgress > 0)
            .accessibilityLabel("Hold for directions to \(destination.displayName)")
            .accessibilityHint("Press and hold for two seconds")
            .accessibilityAction(named: "Get directions") {
                holdProgress = 1
                holdOrigin = holdOriginPoint
                onHoldBegan()
                onHoldStart(destination, holdOriginPoint)
                onHoldComplete(destination, holdOriginPoint)
            }
    }

    private var bubbleLabel: some View {
        Text(destination.displayName)
            .font(.playfairItalic(size: 22))
            .foregroundStyle(.white.opacity(0.97))
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background {
                ZStack {
                    AccentButtonBackground(accent: accent)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .black.opacity(0.24),
                                    .black.opacity(0.1),
                                    .clear
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                }
            }
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.44), lineWidth: 0.5)
            }
    }

    private func holdGesture(buttonFrame: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let origin = unitPoint(from: buttonFrame)
                holdOriginPoint = origin
                holdOrigin = origin
                touchLocation = value.location

                guard holdProgress < 1 else { return }

                if holdTask == nil {
                    pressStartLocation = value.location
                    onHoldBegan()
                    beginHold(origin: origin)
                } else if let start = pressStartLocation {
                    let dx = value.location.x - start.x
                    let dy = value.location.y - start.y
                    if hypot(dx, dy) > maxFingerTravel {
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

    private func beginHold(origin: UnitPoint) {
        didFireHalfwayHaptic = false
        onHoldStart(destination, origin)

        holdTask?.cancel()
        holdTask = Task { @MainActor in
            if reduceMotion {
                holdProgress = 1
                fireCompletionHaptic()
                onHoldComplete(destination, origin)
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
                    onHoldComplete(destination, origin)
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

    private func unitPoint(from frame: CGRect) -> UnitPoint {
        guard containerSize.width > 0, containerSize.height > 0 else { return .center }
        return UnitPoint(
            x: min(max(frame.midX / containerSize.width, 0), 1),
            y: min(max(frame.midY / containerSize.height, 0), 1)
        )
    }
}

#Preview {
    @Previewable @State var progress: CGFloat = 0
    @Previewable @State var origin: UnitPoint = .center
    @Previewable @State var drag: CGFloat = 0

    ZStack {
        Theme.Colors.backgroundPrimary.ignoresSafeArea()

        HomeDestinationBubblesView(
            destinations: [
                .mock(label: .work),
                .mock(label: .other, customName: "The Gym"),
                .mock(label: .other, customName: "Mum's")
            ],
            accent: .gradient(.pink),
            revealProgress: 1,
            containerSize: CGSize(width: 390, height: 844),
            bottomInset: 34,
            maxLift: 280,
            pickerDragTranslation: $drag,
            holdProgress: $progress,
            holdOrigin: $origin,
            onHoldStart: { _, _ in },
            onHoldComplete: { _, _ in },
            onHoldCancel: {},
            onPickerDragEnded: { _, _ in },
            onDismiss: {}
        )
    }
    .coordinateSpace(name: "homeRoot")
}
