import SwiftUI

struct RainbowSwipeToStart: View {
    let accent: AccentStyle
    let onUnlock: () -> Void

    var body: some View {
        AccentSwipeToUnlock(
            accent: accent,
            label: "Swipe to begin",
            accessibilityLabel: "Swipe to begin onboarding",
            accessibilityHint: "Drag the control to the right to start",
            onUnlock: onUnlock
        )
    }
}
