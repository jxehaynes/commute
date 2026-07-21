import Foundation

enum OnboardingStep: Int, CaseIterable {
    case welcome = 1
    case name = 2
    case accentColour = 3
    case locationPerm = 4
    case locations = 5
    case usualTimes = 6
    case usualCommute = 7
    case paceLearning = 8
    case liveActivities = 9
    case done = 10
    case mapsProvider = 11
    case lineVisibility = 12

    var progressFraction: Double {
        let visibleSteps = OnboardingStep.visibleFlow
        guard let index = visibleSteps.firstIndex(of: self) else { return 1 }
        return Double(index + 1) / Double(visibleSteps.count)
    }

    var isRequired: Bool {
        [.welcome, .name, .accentColour, .locations, .usualTimes, .usualCommute].contains(self)
    }

    var nextStep: OnboardingStep? {
        guard let index = OnboardingStep.visibleFlow.firstIndex(of: self),
              index + 1 < OnboardingStep.visibleFlow.count else { return nil }
        return OnboardingStep.visibleFlow[index + 1]
    }

    var previousStep: OnboardingStep? {
        guard let index = OnboardingStep.visibleFlow.firstIndex(of: self),
              index > 0 else { return nil }
        return OnboardingStep.visibleFlow[index - 1]
    }

    private static let visibleFlow: [OnboardingStep] = [
        .welcome,
        .name,
        .accentColour,
        .locationPerm,
        .locations,
        .lineVisibility,
        .usualTimes,
        .usualCommute,
        .paceLearning,
        .liveActivities,
        .done
    ]

    /// Maps persisted step from builds that included the removed typeface step.
    static func migrated(from raw: Int) -> OnboardingStep {
        guard raw > 0 else { return .welcome }
        if raw == 3 { return .accentColour }
        if raw >= 4 { return OnboardingStep(rawValue: raw - 1) ?? .welcome }
        return OnboardingStep(rawValue: raw) ?? .welcome
    }
}
