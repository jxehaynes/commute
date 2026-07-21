import SwiftUI

/// Gradually fades scroll content at the bottom so navigation can float above it.
struct OnboardingScrollContentFade: View {
    var fadeHeight: CGFloat = OnboardingMetrics.scrollFadeHeight

    var body: some View {
        GeometryReader { proxy in
            let height = min(fadeHeight, proxy.size.height * 0.32)

            VStack(spacing: 0) {
                Rectangle().fill(.black)
                LinearGradient(
                    colors: [.black, .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: height)
            }
        }
    }
}

/// Whisper-light blur that strengthens toward the bottom — no colour block.
struct OnboardingBottomAtmosphere: View {
    var height: CGFloat = OnboardingMetrics.scrollAtmosphereHeight

    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .frame(height: height)
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black.opacity(0.18), location: 0.55),
                        .init(color: .black.opacity(0.42), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .allowsHitTesting(false)
    }
}
