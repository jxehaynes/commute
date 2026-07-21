import SwiftUI

struct HomeGreetingView: View {
    let parts: [OnboardingHeadline.HeadlinePart]

    var body: some View {
        OnboardingHeadline(parts: parts, centered: false)
            .accessibilityElement(children: .combine)
    }
}

#Preview("Pre-commute") {
    HomeGreetingView(parts: HomeGreetingBuilder.headlineParts(
        firstName: "Joe",
        phase: .preCommute(timeRemaining: 75 * 60)
    ))
    .padding(.horizontal, OnboardingMetrics.horizontalPadding)
    .background(Theme.Colors.backgroundPrimary)
}

#Preview("During day") {
    HomeGreetingView(parts: HomeGreetingBuilder.headlineParts(
        firstName: "Joe",
        phase: .duringDay(timeRemaining: (8 * 60 + 14) * 60)
    ))
    .padding(.horizontal, OnboardingMetrics.horizontalPadding)
    .background(Theme.Colors.backgroundPrimary)
}
