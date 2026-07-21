import SwiftUI

struct OnboardingStepLayout<Content: View>: View {
    let progress: Double
    let accent: AccentStyle
    let content: Content

    init(progress: Double, accent: AccentStyle, @ViewBuilder content: () -> Content) {
        self.progress = progress
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            progressBar
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.Colors.backgroundPrimary.ignoresSafeArea())
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.Colors.backgroundElevated)

                AccentProgressFill(accent: accent)
                    .frame(width: max(8, proxy.size.width * progress), height: 6)
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: progress)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(height: 8)
        .padding(.horizontal, OnboardingMetrics.horizontalPadding)
        .padding(.top, 4)
        .accessibilityLabel("Onboarding progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}
