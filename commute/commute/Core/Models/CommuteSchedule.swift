import Foundation

/// The user's fixed commute deadlines, set during onboarding and edited in Settings.
struct CommuteSchedule: Codable, Hashable {
    var arriveAtWorkBy: DateComponents
    var arriveHomeBy: DateComponents

    static let `default` = CommuteSchedule(
        arriveAtWorkBy: DateComponents(hour: 9, minute: 0),
        arriveHomeBy: DateComponents(hour: 18, minute: 0)
    )
}
