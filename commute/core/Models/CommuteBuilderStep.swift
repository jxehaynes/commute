import Foundation

enum CommuteStepMode: String, Codable, CaseIterable, Identifiable {
    case walk
    case drive
    case bus
    case train

    var id: String { rawValue }

    var label: String {
        switch self {
        case .walk: "Walk"
        case .drive: "Drive"
        case .bus: "Bus"
        case .train: "Train"
        }
    }

    var systemImage: String {
        switch self {
        case .walk: "figure.walk"
        case .drive: "car.fill"
        case .bus: "bus.fill"
        case .train: "tram.fill"
        }
    }

    var requiresLine: Bool {
        self == .bus || self == .train
    }
}

struct CommuteBuilderStep: Identifiable, Codable, Equatable {
    let id: UUID
    var mode: CommuteStepMode
    var lineID: String?
    var lineName: String?
    var fromStop: String
    var toStop: String
    var estimatedMinutes: Int

    init(
        id: UUID = UUID(),
        mode: CommuteStepMode,
        lineID: String? = nil,
        lineName: String? = nil,
        fromStop: String,
        toStop: String,
        estimatedMinutes: Int
    ) {
        self.id = id
        self.mode = mode
        self.lineID = lineID
        self.lineName = lineName
        self.fromStop = fromStop
        self.toStop = toStop
        self.estimatedMinutes = estimatedMinutes
    }

    var summary: String {
        switch mode {
        case .walk:
            return "Walk · \(fromStop) → \(toStop)"
        case .drive:
            return "Drive · \(fromStop) → \(toStop)"
        case .bus, .train:
            let line = lineName ?? mode.label
            return "\(line) · \(fromStop) → \(toStop)"
        }
    }

    func toRouteLeg(stopCount: Int = 3) -> RouteLeg {
        switch mode {
        case .walk:
            return .walk(minutes: estimatedMinutes, distanceMiles: Double(estimatedMinutes) / 20.0)
        case .drive:
            return .walk(minutes: estimatedMinutes, distanceMiles: Double(estimatedMinutes) / 3.0)
        case .train:
            let line = TfLLine(rawValue: lineID ?? "") ?? .central
            return .transit(
                line: line,
                from: fromStop,
                to: toStop,
                departureTime: "08:45",
                platform: nil,
                stops: max(stopCount, 1),
                lineLabel: lineName
            )
        case .bus:
            return .transit(
                line: .bus,
                from: fromStop,
                to: toStop,
                departureTime: "08:45",
                platform: nil,
                stops: max(stopCount, 1),
                lineLabel: lineName
            )
        }
    }
}

struct CustomCommuteRoute: Codable, Equatable {
    var steps: [CommuteBuilderStep]
    var updatedAt: Date

    init(steps: [CommuteBuilderStep], updatedAt: Date = .now) {
        self.steps = steps
        self.updatedAt = updatedAt
    }

    var isValid: Bool {
        guard !steps.isEmpty else { return false }
        for index in 1..<steps.count {
            if steps[index].fromStop != steps[index - 1].toStop { return false }
        }
        return steps.allSatisfy { !$0.fromStop.isEmpty && !$0.toStop.isEmpty && $0.fromStop != $0.toStop }
    }

    func toRoute(summary: String? = nil) -> Route {
        let legs = steps.map { step in
            let stops = LineStopCatalog.stopCount(from: step.fromStop, to: step.toStop, lineID: step.lineID)
            return step.toRouteLeg(stopCount: stops)
        }
        let totalMinutes = steps.reduce(0) { $0 + $1.estimatedMinutes }
        let routeSummary = summary ?? CustomCommuteRoute.defaultSummary(for: steps)
        return Route(
            summary: routeSummary,
            totalMinutes: totalMinutes,
            legs: legs,
            status: .goodService
        )
    }

    static func defaultSummary(for steps: [CommuteBuilderStep]) -> String {
        if let transit = steps.first(where: { $0.mode == .train || $0.mode == .bus }) {
            if let name = transit.lineName {
                return "Via \(name)"
            }
        }
        return "Your custom route"
    }

    /// Flips the step order and each step's from/to stops, for prefilling the opposite-direction journey.
    func reversed() -> CustomCommuteRoute {
        let reversedSteps = steps.reversed().map { step in
            CommuteBuilderStep(
                mode: step.mode,
                lineID: step.lineID,
                lineName: step.lineName,
                fromStop: step.toStop,
                toStop: step.fromStop,
                estimatedMinutes: step.estimatedMinutes
            )
        }
        return CustomCommuteRoute(steps: reversedSteps, updatedAt: .now)
    }
}
