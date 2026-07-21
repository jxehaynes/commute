import Combine
import Foundation

enum AddStepPhase: Equatable {
    case mode
    case line
    case fromStop
    case toStop
}

enum BuilderPhase: Equatable {
    case chooseJourney
    case steps
}

@MainActor
final class CustomCommuteBuilderViewModel: ObservableObject {
    @Published var phase: BuilderPhase = .chooseJourney
    @Published var availableLocations: [SavedLocation] = []
    @Published var originLocation: SavedLocation?
    @Published var destinationLocation: SavedLocation?
    @Published private(set) var isJourneyLocked = false
    @Published var reverseSuggestion: CustomCommuteRoute?
    private var existingRoutes: [JourneyCommuteRoute] = []

    @Published var steps: [CommuteBuilderStep] = []
    @Published var addPhase: AddStepPhase = .mode
    @Published var draftMode: CommuteStepMode?
    @Published var draftTrainLine: TfLLine?
    @Published var draftBusRoute: BusRoute?
    @Published var draftFromStop: String = ""
    @Published var draftToStop: String = ""
    @Published var isAddingStep = false

    /// The first step always starts from the known origin address, and every later step
    /// picks up from the previous one — so the "where do you start?" question is never asked.
    var chainedFromStop: String? {
        steps.last?.toStop ?? originLocation?.displayName
    }

    var requiresFromPicker: Bool {
        chainedFromStop == nil
    }

    var canSaveDraft: Bool {
        guard let mode = draftMode else { return false }
        let from = chainedFromStop ?? draftFromStop
        guard !from.isEmpty, !draftToStop.isEmpty, from != draftToStop else { return false }
        if mode.requiresLine {
            return mode == .train ? draftTrainLine != nil : draftBusRoute != nil
        }
        return true
    }

    var canSaveRoute: Bool {
        canConfirmJourney && CustomCommuteRoute(steps: steps).isValid
    }

    var canConfirmJourney: Bool {
        guard let origin = originLocation, let destination = destinationLocation else { return false }
        return origin.id != destination.id
    }

    var resolvedPair: (from: SavedLocation, to: SavedLocation)? {
        guard let origin = originLocation, let destination = destinationLocation else { return nil }
        return (origin, destination)
    }

    /// Configures the builder for a fresh session. Pass `lockedOrigin`/`lockedDestination` when the
    /// journey is already known (editing an existing journey route, or onboarding's home/work step) —
    /// otherwise the builder always starts on `.chooseJourney` so the user confirms which addresses
    /// this route is for, rather than assuming home → work.
    func configure(
        availableLocations: [SavedLocation],
        lockedOrigin: SavedLocation? = nil,
        lockedDestination: SavedLocation? = nil,
        existingRoutes: [JourneyCommuteRoute] = [],
        existing: CustomCommuteRoute? = nil
    ) {
        self.availableLocations = availableLocations
        self.existingRoutes = existingRoutes
        steps = existing?.steps ?? []
        reverseSuggestion = nil

        if let lockedOrigin, let lockedDestination {
            originLocation = lockedOrigin
            destinationLocation = lockedDestination
            isJourneyLocked = true
            phase = .steps
        } else {
            originLocation = nil
            destinationLocation = nil
            isJourneyLocked = false
            phase = .chooseJourney
        }
    }

    func selectOrigin(_ location: SavedLocation) {
        originLocation = location
        updateReverseSuggestionIfNeeded()
    }

    func selectDestination(_ location: SavedLocation) {
        destinationLocation = location
        updateReverseSuggestionIfNeeded()
    }

    func swapJourneyDirection() {
        let origin = originLocation
        originLocation = destinationLocation
        destinationLocation = origin
        updateReverseSuggestionIfNeeded()
    }

    func confirmJourneySelection() {
        guard canConfirmJourney else { return }
        phase = .steps
    }

    func changeJourney() {
        guard !isJourneyLocked else { return }
        phase = .chooseJourney
    }

    func applyReverseSuggestion() {
        guard let reverseSuggestion else { return }
        steps = reverseSuggestion.reversed().steps
        self.reverseSuggestion = nil
    }

    private func updateReverseSuggestionIfNeeded() {
        guard steps.isEmpty,
              let origin = originLocation,
              let destination = destinationLocation,
              origin.id != destination.id else {
            reverseSuggestion = nil
            return
        }
        let reversePair = RoutePair(fromID: destination.id, toID: origin.id)
        reverseSuggestion = existingRoutes.first(where: { $0.routePair == reversePair })?.route
    }

    func startAddingStep() {
        resetDraft()
        isAddingStep = true
        addPhase = .mode
    }

    func cancelAddingStep() {
        isAddingStep = false
        resetDraft()
    }

    func selectMode(_ mode: CommuteStepMode) {
        draftMode = mode
        if mode.requiresLine {
            addPhase = .line
        } else if chainedFromStop != nil {
            draftFromStop = chainedFromStop ?? ""
            addPhase = .toStop
        } else {
            addPhase = .fromStop
        }
    }

    func selectTrainLine(_ line: TfLLine) {
        draftTrainLine = line
        draftBusRoute = nil
        draftFromStop = chainedFromStop ?? draftFromStop
        addPhase = chainedFromStop == nil ? .fromStop : .toStop
    }

    func selectBusRoute(_ route: BusRoute) {
        draftBusRoute = route
        draftTrainLine = nil
        draftFromStop = chainedFromStop ?? draftFromStop
        addPhase = chainedFromStop == nil ? .fromStop : .toStop
    }

    func selectFromStop(_ stop: String) {
        draftFromStop = stop
        addPhase = .toStop
    }

    func confirmDraftStep() {
        guard let mode = draftMode, canSaveDraft else { return }
        let from = chainedFromStop ?? draftFromStop
        let lineID: String?
        let lineName: String?
        switch mode {
        case .train:
            lineID = draftTrainLine?.rawValue
            lineName = draftTrainLine.map { "\($0.displayName) line" }
        case .bus:
            lineID = draftBusRoute?.id
            lineName = draftBusRoute.map { "Bus \( $0.displayNumber)" }
        default:
            lineID = nil
            lineName = nil
        }
        let minutes = LineStopCatalog.estimatedMinutes(
            mode: mode,
            from: from,
            to: draftToStop,
            lineID: lineID
        )
        steps.append(
            CommuteBuilderStep(
                mode: mode,
                lineID: lineID,
                lineName: lineName,
                fromStop: from,
                toStop: draftToStop,
                estimatedMinutes: minutes
            )
        )
        cancelAddingStep()
    }

    func removeStep(_ step: CommuteBuilderStep) {
        steps.removeAll { $0.id == step.id }
    }

    func buildConfiguration() -> CustomCommuteRoute {
        CustomCommuteRoute(steps: finalizedSteps(), updatedAt: .now)
    }

    /// The destination is already known, so if the last manual step doesn't already end there,
    /// the route will automatically finish with a closing leg to it — this describes that leg
    /// so the UI can show it without the user having to add it themselves.
    var pendingAutoFinishLabel: String? {
        guard let destination = destinationLocation, let lastStop = steps.last?.toStop else { return nil }
        guard lastStop.caseInsensitiveCompare(destination.displayName) != .orderedSame else { return nil }
        return destination.displayName
    }

    /// Appends an automatic closing leg to the destination address if the last step the user
    /// added doesn't already end there — the destination is already known from the journey
    /// selection, so we never need to ask where the route finishes.
    private func finalizedSteps() -> [CommuteBuilderStep] {
        guard let destination = destinationLocation, let lastStop = steps.last?.toStop else { return steps }
        guard lastStop.caseInsensitiveCompare(destination.displayName) != .orderedSame else { return steps }
        let closingStep = CommuteBuilderStep(
            mode: .walk,
            fromStop: lastStop,
            toStop: destination.displayName,
            estimatedMinutes: LineStopCatalog.estimatedMinutes(mode: .walk, from: lastStop, to: destination.displayName, lineID: nil)
        )
        return steps + [closingStep]
    }

    private func resetDraft() {
        draftMode = nil
        draftTrainLine = nil
        draftBusRoute = nil
        draftFromStop = ""
        draftToStop = ""
        addPhase = .mode
    }

    func stopOptionsForDraft() -> [String] {
        guard let mode = draftMode else { return LineStopCatalog.commonPlaces }
        switch mode {
        case .train:
            guard let line = draftTrainLine else { return [] }
            return LineStopCatalog.stops(forTrain: line)
        case .bus:
            guard let route = draftBusRoute else { return [] }
            return LineStopCatalog.stops(forBus: route.id)
        case .walk, .drive:
            return LineStopCatalog.places(for: mode)
        }
    }

    func toStopOptions() -> [String] {
        let options = stopOptionsForDraft()
        let from = chainedFromStop ?? draftFromStop
        guard modeIsTransit else { return options.filter { $0 != from } }
        guard let fromIndex = options.firstIndex(of: from) else {
            return options.filter { $0 != from }
        }
        return Array(options.suffix(from: options.count - fromIndex - 1))
    }

    private var modeIsTransit: Bool {
        draftMode == .bus || draftMode == .train
    }
}
