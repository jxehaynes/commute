import SwiftUI

/// Horizontal swipe track with accent gradient fill (onboarding + home).
struct AccentSwipeToUnlock: View {
    let accent: AccentStyle
    let label: String
    @Binding var progress: CGFloat
    let onUnlock: () -> Void
    /// When true, track is frosted so full-screen gradient blobs do not show through.
    var blendsWithFluidBackdrop: Bool = false
    var accessibilityLabel: String
    var accessibilityHint: String

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let trackHeight: CGFloat = 64
    private let thumbSize: CGFloat = 52
    private let unlockThreshold: CGFloat = 0.88

    init(
        accent: AccentStyle,
        label: String,
        progress: Binding<CGFloat> = .constant(0),
        blendsWithFluidBackdrop: Bool = false,
        accessibilityLabel: String = "Swipe to continue",
        accessibilityHint: String = "Drag the control to the right",
        onUnlock: @escaping () -> Void
    ) {
        self.accent = accent
        self.label = label
        self._progress = progress
        self.blendsWithFluidBackdrop = blendsWithFluidBackdrop
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.onUnlock = onUnlock
    }

    var body: some View {
        GeometryReader { proxy in
            let maxOffset = max(proxy.size.width - thumbSize - 12, 1)

            ZStack(alignment: .leading) {
                trackBackground
                    .overlay {
                        RoundedRectangle(cornerRadius: trackHeight / 2)
                            .strokeBorder(.white.opacity(blendsWithFluidBackdrop ? 0.55 : 0.4), lineWidth: 0.5)
                    }

                Text(label)
                    .font(Theme.Fonts.bodyEmphasis)
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .frame(maxWidth: .infinity)
                    .opacity(Double(1 - min(dragOffset / (maxOffset * 0.6), 1)))

                thumb
                    .offset(x: 6 + dragOffset)
                    .gesture(
                        DragGesture(minimumDistance: 4)
                            .onChanged { value in
                                isDragging = true
                                dragOffset = min(max(0, value.translation.width), maxOffset)
                                progress = maxOffset > 0 ? dragOffset / maxOffset : 0
                            }
                            .onEnded { _ in
                                isDragging = false
                                if dragOffset > maxOffset * unlockThreshold {
                                    unlock(maxOffset: maxOffset)
                                } else {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                        dragOffset = 0
                                        progress = 0
                                    }
                                }
                            }
                    )
            }
            .onAppear {
                syncDragOffset(maxOffset: maxOffset)
            }
            .onChange(of: progress) { _, _ in
                guard !isDragging else { return }
                syncDragOffset(maxOffset: maxOffset)
            }
        }
        .frame(height: trackHeight)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAction(named: "Complete swipe") {
            progress = 1
            onUnlock()
        }
        .onChange(of: progress) { _, newValue in
            guard newValue <= 0.001, dragOffset > 0, !isDragging else { return }
            dragOffset = 0
        }
    }

    private func syncDragOffset(maxOffset: CGFloat) {
        dragOffset = min(max(0, progress * maxOffset), maxOffset)
    }

    @ViewBuilder
    private var trackBackground: some View {
        let shape = RoundedRectangle(cornerRadius: trackHeight / 2, style: .continuous)
        if blendsWithFluidBackdrop {
            shape
                .fill(.ultraThinMaterial)
                .overlay {
                    shape.fill(accent.tintColor.opacity(0.28))
                }
        } else {
            shape
                .fill(Theme.Colors.backgroundElevated.opacity(0.35))
                .overlay {
                    AnimatedRainbowGradient(accent: accent)
                        .clipShape(shape)
                }
        }
    }

    private var thumb: some View {
        Circle()
            .fill(.white)
            .frame(width: thumbSize, height: thumbSize)
            .overlay {
                Image(systemName: "chevron.right.2")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.Colors.textPrimary)
            }
            .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
    }

    private func unlock(maxOffset: CGFloat) {
        if reduceMotion {
            dragOffset = maxOffset
            progress = 1
            onUnlock()
            return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            dragOffset = maxOffset
            progress = 1
        }
        onUnlock()
    }
}

#Preview {
    @Previewable @State var progress: CGFloat = 0

    AccentSwipeToUnlock(
        accent: .gradient(.pink),
        label: "Swipe to plan",
        progress: $progress,
        onUnlock: {}
    )
    .padding()
}
