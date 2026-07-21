import Combine
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    private enum Keys {
        static let onboardingComplete = "onboarding.complete"
        static let onboardingStep = "onboarding.step"
        static let accentStyle = "accent.style"
        static let fontSerif = "font.serif"
        static let profile = "user.profile"
    }

    @Published var hasCompletedOnboarding: Bool
    @Published var onboardingStep: OnboardingStep
    @Published var accentStyle: AccentStyle
    @Published var useSerif: Bool
    @Published var userProfile: UserProfile

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.onboardingComplete)
        let stepRaw = UserDefaults.standard.integer(forKey: Keys.onboardingStep)
        onboardingStep = OnboardingStep.migrated(from: stepRaw > 0 ? stepRaw : 1)

        if let data = UserDefaults.standard.data(forKey: Keys.accentStyle),
           let decoded = try? JSONDecoder().decode(AccentStyle.self, from: data) {
            accentStyle = decoded
        } else {
            accentStyle = NeatConfig.defaultAccent
        }

        useSerif = UserDefaults.standard.object(forKey: Keys.fontSerif) as? Bool ?? true

        if let data = UserDefaults.standard.data(forKey: Keys.profile),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = decoded
        } else {
            userProfile = UserProfile(
                firstName: "",
                useSerif: true,
                accentStyle: NeatConfig.defaultAccent,
                mapsProvider: .apple,
                locations: [],
                usualRoutes: []
            )
        }
    }

    func persistOnboardingStep(_ step: OnboardingStep) {
        onboardingStep = step
        UserDefaults.standard.set(step.rawValue, forKey: Keys.onboardingStep)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: Keys.onboardingComplete)
        UserDefaults.standard.removeObject(forKey: Keys.onboardingStep)
        onboardingStep = .welcome
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        onboardingStep = .welcome
        UserDefaults.standard.set(false, forKey: Keys.onboardingComplete)
        UserDefaults.standard.set(OnboardingStep.welcome.rawValue, forKey: Keys.onboardingStep)
    }

    func setAccent(_ style: AccentStyle) {
        accentStyle = style
        userProfile.accentStyle = style
        persistProfile()
        if let data = try? JSONEncoder().encode(style) {
            UserDefaults.standard.set(data, forKey: Keys.accentStyle)
        }
    }

    func setFont(serif: Bool) {
        useSerif = serif
        userProfile.useSerif = serif
        UserDefaults.standard.set(serif, forKey: Keys.fontSerif)
        persistProfile()
    }

    func updateProfile(_ profile: UserProfile) {
        userProfile = profile
        accentStyle = profile.accentStyle
        useSerif = profile.useSerif
        persistProfile()
        if let data = try? JSONEncoder().encode(profile.accentStyle) {
            UserDefaults.standard.set(data, forKey: Keys.accentStyle)
        }
        UserDefaults.standard.set(profile.useSerif, forKey: Keys.fontSerif)
    }

    private func persistProfile() {
        if let data = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(data, forKey: Keys.profile)
        }
    }
}
