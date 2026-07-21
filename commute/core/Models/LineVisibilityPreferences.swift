import Foundation

/// The set of transit lines a user wants surfaced across the app (network
/// status, disruptions, etc). Set during onboarding, editable in Settings.
struct LineVisibilityPreferences: Codable, Equatable {
    var enabledCategories: Set<TransitLineCategory>
    var enabledNationalRailOperators: Set<TfLLine>

    static let `default` = LineVisibilityPreferences(
        enabledCategories: [.tube, .overground, .dlr, .elizabethLine, .thameslink],
        enabledNationalRailOperators: []
    )

    init(
        enabledCategories: Set<TransitLineCategory> = LineVisibilityPreferences.default.enabledCategories,
        enabledNationalRailOperators: Set<TfLLine> = []
    ) {
        self.enabledCategories = enabledCategories
        self.enabledNationalRailOperators = enabledNationalRailOperators
    }

    func isVisible(_ line: TfLLine) -> Bool {
        let category = line.category
        guard enabledCategories.contains(category) else { return false }
        guard category == .nationalRail, line != .nationalRail else { return true }
        return enabledNationalRailOperators.contains(line)
    }

    func isEnabled(_ category: TransitLineCategory) -> Bool {
        enabledCategories.contains(category)
    }

    mutating func setEnabled(_ isEnabled: Bool, for category: TransitLineCategory) {
        if isEnabled {
            enabledCategories.insert(category)
        } else {
            enabledCategories.remove(category)
            if category == .nationalRail {
                enabledNationalRailOperators.removeAll()
            }
        }
    }

    mutating func toggleNationalRailOperator(_ line: TfLLine) {
        if enabledNationalRailOperators.contains(line) {
            enabledNationalRailOperators.remove(line)
        } else {
            enabledNationalRailOperators.insert(line)
        }
    }
}
