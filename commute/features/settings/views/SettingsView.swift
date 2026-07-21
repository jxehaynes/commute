import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showCommuteBuilder = false
    @State private var showLocationsEditor = false
    @StateObject private var builderViewModel = CustomCommuteBuilderViewModel()
    @StateObject private var locationsEditorViewModel = SavedLocationsEditorViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    profileCard
                    locationsCard
                    mapsCard
                    commuteTimesCard
                    customRouteCard
                    featuresCard
                    resetCard
                }
                .padding(.horizontal, OnboardingMetrics.horizontalPadding)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
            .background(Theme.Colors.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showCommuteBuilder) {
                CustomCommuteBuilderView(
                    viewModel: builderViewModel,
                    accent: appState.accentStyle,
                    mapsProvider: appState.userProfile.mapsProvider,
                    onSave: saveCustomRoute
                )
                .onAppear {
                    builderViewModel.load(appState.userProfile.customCommuteRoute)
                }
            }
            .sheet(isPresented: $showLocationsEditor) {
                SavedLocationsEditorView(
                    viewModel: locationsEditorViewModel,
                    accent: appState.accentStyle,
                    mapsProvider: appState.userProfile.mapsProvider,
                    onSave: saveLocations
                )
                .onAppear {
                    locationsEditorViewModel.load(from: appState.userProfile.locations)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            OnboardingHeadline(
                parts: [.plain("Your "), .serif("Commute"), .plain(" settings")],
                centered: false
            )
            Text("Everything from onboarding lives here, so you can change it later.")
                .font(Theme.Fonts.secondary)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var profileCard: some View {
        settingsCard(title: "Profile", systemImage: "person.crop.circle.fill") {
            UnderlineTextField(
                placeholder: "First name",
                text: profileStringBinding(\.firstName),
                accent: appState.accentStyle,
                accessibilityLabel: "First name"
            )
            AccentColorGridPicker(selection: accentBinding)
        }
    }

    private var locationsCard: some View {
        settingsCard(title: "Saved places", systemImage: "mappin.and.ellipse") {
            ForEach(appState.userProfile.locations) { location in
                SettingsInfoRow(
                    title: location.displayName,
                    subtitle: location.address,
                    systemImage: icon(for: location.label),
                    accent: appState.accentStyle
                )
            }

            if appState.userProfile.locations.isEmpty {
                Text("Add Home and Work so Commute can plan your journey.")
                    .font(Theme.Fonts.secondary)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Button {
                showLocationsEditor = true
            } label: {
                Label(
                    appState.userProfile.locations.isEmpty ? "Add places" : "Edit places",
                    systemImage: appState.userProfile.locations.isEmpty ? "plus.circle.fill" : "pencil.circle.fill"
                )
                .font(Theme.Fonts.bodyEmphasis)
            }
            .foregroundStyle(appState.accentStyle.tintColor)
        }
    }

    private var mapsCard: some View {
        settingsCard(title: "Maps provider", systemImage: "map.fill") {
            MapsProviderPicker(
                selection: mapsProviderBinding,
                accentStyle: appState.accentStyle,
                showsUnavailableProviders: false
            )
        }
    }

    private var commuteTimesCard: some View {
        settingsCard(title: "Arrival times", systemImage: "clock.fill") {
            DatePicker(
                "At work by",
                selection: scheduleDateBinding(\.arriveAtWorkBy),
                displayedComponents: .hourAndMinute
            )
            .font(Theme.Fonts.bodyEmphasis)

            DatePicker(
                "At home after",
                selection: scheduleDateBinding(\.arriveHomeBy),
                displayedComponents: .hourAndMinute
            )
            .font(Theme.Fonts.bodyEmphasis)
        }
    }

    private var customRouteCard: some View {
        settingsCard(title: "Your commute route", systemImage: "arrow.triangle.turn.up.right.diamond.fill") {
            if let custom = appState.userProfile.customCommuteRoute, custom.isValid {
                VStack(alignment: .leading, spacing: 8) {
                    Text(custom.toRoute().summary)
                        .font(Theme.Fonts.bodyEmphasis)
                    Text("\(custom.steps.count) steps · \(custom.steps.reduce(0) { $0 + $1.estimatedMinutes }) min")
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    ForEach(custom.steps) { step in
                        Label(step.summary, systemImage: step.mode.systemImage)
                            .font(Theme.Fonts.secondary)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            } else {
                Text(preferenceSummary)
                    .font(Theme.Fonts.secondary)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            Button {
                showCommuteBuilder = true
            } label: {
                Label(appState.userProfile.customCommuteRoute == nil ? "Build custom route" : "Edit custom route", systemImage: "plus.circle.fill")
                    .font(Theme.Fonts.bodyEmphasis)
            }
            .foregroundStyle(appState.accentStyle.tintColor)
        }
    }

    private var featuresCard: some View {
        settingsCard(title: "Smart features", systemImage: "sparkles") {
            AccentGradientToggle(
                label: "Pace learning",
                isOn: profileBoolBinding(\.enablePaceLearning),
                accent: appState.accentStyle
            )
            AccentGradientToggle(
                label: "Live Activities",
                isOn: profileBoolBinding(\.enableLiveActivities),
                accent: appState.accentStyle
            )
        }
    }

    private var resetCard: some View {
        Button {
            appState.resetOnboarding()
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                VStack(alignment: .leading, spacing: 3) {
                    Text("Reset onboarding")
                        .font(Theme.Fonts.bodyEmphasis)
                    Text("Clear onboarding progress and walk through setup again.")
                        .font(Theme.Fonts.caption)
                }
                Spacer()
            }
            .foregroundStyle(Theme.Colors.statusDisrupted)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.Colors.backgroundSurface)
            }
        }
        .buttonStyle(OnboardingPressStyle())
    }

    private func settingsCard<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                AccentGradientCircle(
                    accent: appState.accentStyle,
                    diameter: 34,
                    systemImage: systemImage,
                    iconSize: 14
                )
                Text(title)
                    .font(Theme.Fonts.bodyEmphasis)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
            }

            content()
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.Colors.backgroundSurface)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
        }
    }

    private func saveCustomRoute(_ route: CustomCommuteRoute) {
        var profile = appState.userProfile
        profile.customCommuteRoute = route
        appState.updateProfile(profile)
    }

    private func saveLocations(_ locations: [SavedLocation]) {
        var profile = appState.userProfile
        profile.locations = locations
        appState.updateProfile(profile)
    }

    private var preferenceSummary: String {
        guard let pattern = appState.userProfile.preferredCommutePattern else {
            return "No route preference saved yet. Commute will rank live routes by travel time."
        }

        let modes = pattern.legKinds.map(\.displayLabel).joined(separator: " -> ")
        if let label = pattern.lineLabels.first {
            return "Preferred pattern: \(modes). Usual line: \(label)."
        }
        return "Preferred pattern: \(modes)."
    }

    private var accentBinding: Binding<AccentStyle> {
        Binding(
            get: { appState.accentStyle },
            set: { appState.setAccent($0) }
        )
    }

    private var mapsProviderBinding: Binding<UserProfile.MapsProvider> {
        Binding(
            get: { appState.userProfile.mapsProvider },
            set: { provider in
                var profile = appState.userProfile
                profile.mapsProvider = provider.isLocationSearchEnabled ? provider : .apple
                appState.updateProfile(profile)
            }
        )
    }

    private func profileStringBinding(_ keyPath: WritableKeyPath<UserProfile, String>) -> Binding<String> {
        Binding(
            get: { appState.userProfile[keyPath: keyPath] },
            set: { value in
                var profile = appState.userProfile
                profile[keyPath: keyPath] = value
                appState.updateProfile(profile)
            }
        )
    }

    private func profileBoolBinding(_ keyPath: WritableKeyPath<UserProfile, Bool>) -> Binding<Bool> {
        Binding(
            get: { appState.userProfile[keyPath: keyPath] },
            set: { value in
                var profile = appState.userProfile
                profile[keyPath: keyPath] = value
                appState.updateProfile(profile)
            }
        )
    }

    private func scheduleDateBinding(_ keyPath: WritableKeyPath<CommuteSchedule, DateComponents>) -> Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: appState.userProfile.commuteSchedule[keyPath: keyPath]) ?? .now
            },
            set: { date in
                var profile = appState.userProfile
                profile.commuteSchedule[keyPath: keyPath] = Calendar.current.dateComponents([.hour, .minute], from: date)
                appState.updateProfile(profile)
            }
        )
    }

    private func icon(for label: SavedLocation.LocationLabel) -> String {
        switch label {
        case .home: "house.fill"
        case .work: "briefcase.fill"
        case .other: "star.fill"
        }
    }
}

private struct SettingsInfoRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: AccentStyle

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accent.tintColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.Fonts.bodyEmphasis)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(subtitle)
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}
