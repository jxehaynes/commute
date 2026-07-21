import CommuteKit
import Foundation
import SwiftUI

/// App-wide state: the user's profile plus a couple of derived conveniences,
/// persisted locally so it survives relaunches.
@MainActor
final class AppState: ObservableObject {
    @Published private(set) var userProfile: UserProfile
    @Published private(set) var hasCompletedOnboarding: Bool

    private let store: UserDefaults
    private let profileKey = "commute.userProfile"
    private let onboardingKey = "commute.hasCompletedOnboarding"

    init(store: UserDefaults = .standard) {
        self.store = store
        if let data = store.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.userProfile = decoded
        } else {
            self.userProfile = UserProfile()
        }
        self.hasCompletedOnboarding = store.bool(forKey: onboardingKey)
    }

    var accentStyle: AccentStyle {
        userProfile.accent
    }

    func updateProfile(_ profile: UserProfile) {
        userProfile = profile
        persist()
    }

    func setAccent(_ accent: AccentStyle) {
        userProfile.accent = accent
        persist()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        store.set(true, forKey: onboardingKey)
    }

    func resetOnboarding() {
        userProfile = UserProfile()
        hasCompletedOnboarding = false
        store.removeObject(forKey: profileKey)
        store.removeObject(forKey: onboardingKey)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(userProfile) else { return }
        store.set(data, forKey: profileKey)
    }
}
