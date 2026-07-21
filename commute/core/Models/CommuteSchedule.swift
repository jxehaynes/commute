import Foundation

struct CommuteSchedule: Codable, Equatable {
    var arriveAtWorkBy: DateComponents
    var arriveHomeBy: DateComponents
    var typicalTravelMinutes: Int

    static let `default` = CommuteSchedule(
        arriveAtWorkBy: DateComponents(hour: 9, minute: 0),
        arriveHomeBy: DateComponents(hour: 18, minute: 30),
        typicalTravelMinutes: 45
    )

    func leaveForWork(on date: Date, calendar: Calendar = .current) -> Date? {
        guard let arrival = calendar.date(bySetting: arriveAtWorkBy, of: date) else { return nil }
        return calendar.date(byAdding: .minute, value: -typicalTravelMinutes, to: arrival)
    }

    func leaveForHome(on date: Date, calendar: Calendar = .current) -> Date? {
        guard let arrival = calendar.date(bySetting: arriveHomeBy, of: date) else { return nil }
        return calendar.date(byAdding: .minute, value: -typicalTravelMinutes, to: arrival)
    }

    func arriveAtWork(on date: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(bySetting: arriveAtWorkBy, of: date)
    }

    func arriveHome(on date: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(bySetting: arriveHomeBy, of: date)
    }
}

extension Calendar {
    fileprivate func date(bySetting components: DateComponents, of date: Date) -> Date? {
        var merged = dateComponents([.year, .month, .day], from: date)
        merged.hour = components.hour
        merged.minute = components.minute
        merged.second = 0
        return self.date(from: merged)
    }
}
