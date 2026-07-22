import Foundation

/// Identifiers for the home-screen widgets, shared so the app can target
/// `WidgetCenter.reloadTimelines(ofKind:)` without depending on the widget
/// extension target.
public enum CommuteWidgetKind {
    public static let nextCommute = "NextCommuteWidget"
}

/// A cheap, precomputed snapshot of the user's next commute, written by the
/// app whenever it recalculates the Live Activity schedule and read back by
/// the home-screen widget's timeline provider. Kept intentionally small so it
/// can be stored as a single JSON blob in the shared app group container.
public struct CommuteWidgetSnapshot: Codable, Hashable, Sendable {
    public var destinationLabel: String
    public var destinationIcon: String
    public var accent: LiveActivityAccent
    public var leaveByDate: Date
    public var arriveByDate: Date
    public var etaMinutes: Int
    public var routeSteps: [RouteStepSummary]
    public var updatedAt: Date

    public init(
        destinationLabel: String,
        destinationIcon: String,
        accent: LiveActivityAccent,
        leaveByDate: Date,
        arriveByDate: Date,
        etaMinutes: Int,
        routeSteps: [RouteStepSummary] = [],
        updatedAt: Date = .now
    ) {
        self.destinationLabel = destinationLabel
        self.destinationIcon = destinationIcon
        self.accent = accent
        self.leaveByDate = leaveByDate
        self.arriveByDate = arriveByDate
        self.etaMinutes = etaMinutes
        self.routeSteps = routeSteps
        self.updatedAt = updatedAt
    }
}

/// Reads and writes `CommuteWidgetSnapshot` to the app-group container shared
/// between the main app and the `CommuteWidgets` extension.
public enum CommuteWidgetStore {
    public static let appGroupIdentifier = "group.dev.jh.commute"
    private static let snapshotKey = "widget.nextCommute.snapshot"

    public static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    public static func save(_ snapshot: CommuteWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        sharedDefaults?.set(data, forKey: snapshotKey)
    }

    public static func clear() {
        sharedDefaults?.removeObject(forKey: snapshotKey)
    }

    public static func load() -> CommuteWidgetSnapshot? {
        guard let data = sharedDefaults?.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(CommuteWidgetSnapshot.self, from: data)
    }
}
