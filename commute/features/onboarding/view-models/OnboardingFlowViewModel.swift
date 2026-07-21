import Combine
import Foundation
import SwiftUI

@MainActor
final class OnboardingFlowViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var firstName: String = ""
    @Published var useSerif: Bool = true
    @Published var accentStyle: AccentStyle = AccentPalette.defaultStyle
    @Published var hasLockedAccent: Bool = false

    @Published var homeAddress: String = ""
    @Published var workAddress: String = ""
    @Published var otherName: String = ""
    @Published var otherAddress: String = ""
    @Published var homeLocation: SavedLocation?
    @Published var workLocation: SavedLocation?
    @Published var otherLocation: SavedLocation?

    @Published var mapsProvider: UserProfile.MapsProvider = .apple
    @Published var selectedUsualRoute: Route?
    @Published var customCommuteRoute: CustomCommuteRoute?
    @Published var preferredCommutePattern: PreferredCommutePattern?
    @Published var enablePaceLearning: Bool = false
    @Published var enableLiveActivities: Bool = false
    @Published var lineVisibility: LineVisibilityPreferences = .default
    @Published var suggestedRoutes: [Route] = []
    @Published var isFetchingSuggestions: Bool = false

    @Published var arriveAtWorkBy: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? .now
    @Published var arriveHomeBy: Date = Calendar.current.date(from: DateComponents(hour: 18, minute: 30)) ?? .now
    @Published var workArrivalPreference: ArrivalPreference = .onTime
    @Published var homeArrivalPreference: ArrivalPreference = .onTime

    private let routeProvider: any RouteProviding

    init(routeProvider: (any RouteProviding)? = nil) {
        self.routeProvider = routeProvider ?? BestAvailableRouteProvider()
    }

    func resolvedAccent(appState: AppState) -> AccentStyle {
        if currentStep.rawValue < OnboardingStep.accentColour.rawValue {
            return AccentPalette.defaultStyle
        }
        return accentStyle
    }

    func restore(step: OnboardingStep) {
        currentStep = step
        hasLockedAccent = step.rawValue > OnboardingStep.accentColour.rawValue
    }

    func advance(appState: AppState) {
        if currentStep == .accentColour {
            hasLockedAccent = true
            appState.setAccent(accentStyle)
        }
        guard let next = currentStep.nextStep else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            currentStep = next
        }
        appState.persistOnboardingStep(next)
    }

    func back(appState: AppState) {
        guard let previous = currentStep.previousStep else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            currentStep = previous
        }
        appState.persistOnboardingStep(previous)
    }

    func skip(appState: AppState) {
        advance(appState: appState)
    }

    func previewAccent(_ style: AccentStyle, appState: AppState) {
        accentStyle = style
        if currentStep == .accentColour {
            appState.setAccent(style)
        }
    }

    func commitLocationEdits() {
        if !homeAddress.trimmingCharacters(in: .whitespaces).isEmpty {
            if homeLocation?.address != homeAddress {
                let existing = homeLocation
                let mock = SavedLocation.mock(label: .home, address: homeAddress)
                homeLocation = SavedLocation(
                    id: existing?.id ?? mock.id,
                    label: .home,
                    address: homeAddress,
                    coordinate: existing?.address == homeAddress ? (existing?.coordinate ?? mock.coordinate) : mock.coordinate,
                    schedule: existing?.schedule ?? PlaceSchedule.defaulted(for: .home)
                )
            }
        }
        if !workAddress.trimmingCharacters(in: .whitespaces).isEmpty {
            if workLocation?.address != workAddress {
                let existing = workLocation
                let mock = SavedLocation.mock(label: .work, customName: "Work", address: workAddress)
                workLocation = SavedLocation(
                    id: existing?.id ?? mock.id,
                    label: .work,
                    customName: "Work",
                    address: workAddress,
                    coordinate: existing?.address == workAddress ? (existing?.coordinate ?? mock.coordinate) : mock.coordinate,
                    schedule: existing?.schedule ?? PlaceSchedule.defaulted(for: .work)
                )
            }
        }
        if !otherAddress.trimmingCharacters(in: .whitespaces).isEmpty {
            if otherLocation?.address != otherAddress || otherLocation?.customName != resolvedOtherName {
                let existing = otherLocation
                let mock = SavedLocation.mock(
                    label: .other,
                    customName: resolvedOtherName,
                    address: otherAddress
                )
                otherLocation = SavedLocation(
                    id: existing?.id ?? mock.id,
                    label: .other,
                    customName: resolvedOtherName,
                    address: otherAddress,
                    coordinate: existing?.address == otherAddress ? (existing?.coordinate ?? mock.coordinate) : mock.coordinate,
                    schedule: existing?.schedule ?? .empty
                )
            }
        }
    }

    func selectLocation(_ result: ResolvedLocationSearchResult, label: SavedLocation.LocationLabel) {
        let customName: String?
        switch label {
        case .home:
            homeAddress = result.formattedAddress
            customName = nil
        case .work:
            workAddress = result.formattedAddress
            customName = "Work"
        case .other:
            otherAddress = result.formattedAddress
            customName = resolvedOtherName
        }

        let location = SavedLocation(
            id: existingLocation(for: label)?.id ?? UUID(),
            label: label,
            customName: customName,
            address: result.formattedAddress,
            coordinate: result.coordinate,
            naptanId: nil,
            routingCoordinate: nil,
            schedule: existingLocation(for: label)?.schedule ?? PlaceSchedule.defaulted(for: label)
        )

        setLocation(location)
    }

    func fetchRouteSuggestions() async {
        commitLocationEdits()
        guard let home = homeLocation, let work = workLocation else { return }
        isFetchingSuggestions = true
        defer { isFetchingSuggestions = false }
        do {
            let query = RouteQuery(date: nextMondayArrivalDate(), timeMode: .arriving, usesLightweightStrategies: false)
            let routes = try await routeProvider.fetchRoutes(from: home, to: work, query: query)
            suggestedRoutes = RouteScorer.rankedRoutes(routes, preference: preferredCommutePattern)
        } catch {
            suggestedRoutes = []
        }
    }

    private func setLocation(_ location: SavedLocation) {
        switch location.label {
        case .home:
            homeLocation = location
        case .work:
            workLocation = location
        case .other:
            otherLocation = location
        }
    }

    private func existingLocation(for label: SavedLocation.LocationLabel) -> SavedLocation? {
        switch label {
        case .home: homeLocation
        case .work: workLocation
        case .other: otherLocation
        }
    }

    private func nextMondayArrivalDate(calendar: Calendar = .current, now: Date = .now) -> Date {
        let nextMonday = calendar.nextDate(
            after: now,
            matching: DateComponents(weekday: Weekday.monday.rawValue),
            matchingPolicy: .nextTimePreservingSmallerComponents,
            direction: .forward
        ) ?? now

        let selectedTime = calendar.dateComponents([.hour, .minute], from: arriveAtWorkBy)
        var components = calendar.dateComponents([.year, .month, .day], from: nextMonday)
        components.hour = selectedTime.hour
        components.minute = selectedTime.minute
        components.second = 0
        return calendar.date(from: components) ?? nextMonday
    }

    func applyCustomRoute(_ configuration: CustomCommuteRoute) {
        customCommuteRoute = configuration
        let route = configuration.toRoute()
        selectedUsualRoute = route
        preferredCommutePattern = PreferredCommutePattern(route: route)
    }

    func selectSuggestedRoute(_ route: Route) {
        customCommuteRoute = nil
        selectedUsualRoute = route
        preferredCommutePattern = PreferredCommutePattern(route: route)
    }

    func buildProfile() -> UserProfile {
        commitLocationEdits()
        var locations: [SavedLocation] = []
        let calendar = Calendar.current
        let workArrive = calendar.dateComponents([.hour, .minute], from: arriveAtWorkBy)
        let homeArrive = calendar.dateComponents([.hour, .minute], from: arriveHomeBy)

        if var home = homeLocation {
            home.schedule = PlaceSchedule(
                periods: [.evening],
                weekdays: Weekday.weekdays,
                arriveBy: homeArrive
            )
            locations.append(home)
        }
        if var work = workLocation {
            work.schedule = PlaceSchedule(
                periods: [.morning],
                weekdays: Weekday.weekdays,
                arriveBy: workArrive
            )
            locations.append(work)
        }
        if let other = otherLocation { locations.append(other) }

        let journeyRoutes: [JourneyCommuteRoute]
        if let route = customCommuteRoute, let home = homeLocation, let work = workLocation {
            journeyRoutes = [JourneyCommuteRoute(routePair: RoutePair(fromID: home.id, toID: work.id), route: route)]
        } else {
            journeyRoutes = []
        }

        return UserProfile(
            firstName: firstName,
            useSerif: true,
            accentStyle: accentStyle,
            mapsProvider: mapsProvider,
            locations: locations,
            usualRoutes: [],
            commuteSchedule: CommuteSchedule(
                arriveAtWorkBy: workArrive,
                arriveHomeBy: homeArrive,
                typicalTravelMinutes: preferredCommutePattern?.totalMinutes ?? 45
            ),
            journeyRoutes: journeyRoutes,
            preferredCommutePattern: preferredCommutePattern,
            enablePaceLearning: enablePaceLearning,
            enableLiveActivities: enableLiveActivities,
            lineVisibility: lineVisibility
        )
    }

    func completeOnboarding(appState: AppState) {
        appState.setFont(serif: true)
        appState.setAccent(accentStyle)
        appState.updateProfile(buildProfile())
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            appState.completeOnboarding()
        }
    }

    private var resolvedOtherName: String {
        otherName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Other" : otherName
    }
}
