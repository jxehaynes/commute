import Foundation

enum DayPeriod: String, Codable, CaseIterable, Hashable {
    case morning, afternoon, evening

    var displayLabel: String {
        switch self {
        case .morning: "Morning"
        case .afternoon: "Afternoon"
        case .evening: "Evening"
        }
    }

    static func current(at date: Date = .now, calendar: Calendar = .current) -> DayPeriod {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        default: return .evening
        }
    }
}

struct PlaceSchedule: Codable, Equatable {
    var periods: Set<DayPeriod>
    var weekdays: Set<Weekday>
    var arriveBy: DateComponents

    static let empty = PlaceSchedule(
        periods: [],
        weekdays: [],
        arriveBy: DateComponents(hour: 9, minute: 0)
    )

    static func defaulted(
        for label: SavedLocation.LocationLabel,
        commuteSchedule: CommuteSchedule = .default
    ) -> PlaceSchedule {
        switch label {
        case .work:
            return PlaceSchedule(
                periods: [.morning],
                weekdays: Weekday.weekdays,
                arriveBy: commuteSchedule.arriveAtWorkBy
            )
        case .home:
            return PlaceSchedule(
                periods: [.evening],
                weekdays: Weekday.weekdays,
                arriveBy: commuteSchedule.arriveHomeBy
            )
        case .other:
            return .empty
        }
    }

    var summaryText: String {
        var parts: [String] = []
        if !weekdays.isEmpty {
            parts.append(Weekday.summary(for: weekdays))
        } else if !periods.isEmpty {
            parts.append("Every day")
        }
        if !periods.isEmpty {
            parts.append(
                periods
                    .sorted { $0.displayLabel < $1.displayLabel }
                    .map(\.displayLabel)
                    .joined(separator: ", ")
            )
        }
        if parts.isEmpty {
            return "No schedule set"
        }
        return parts.joined(separator: " · ")
    }

    func matches(now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard !periods.isEmpty else { return false }
        let period = DayPeriod.current(at: now, calendar: calendar)
        guard periods.contains(period) else { return false }
        if weekdays.isEmpty { return true }
        guard let weekday = Weekday(calendarWeekday: calendar.component(.weekday, from: now)) else {
            return false
        }
        return weekdays.contains(weekday)
    }
}

extension Weekday {
    static let weekdays: Set<Weekday> = [
        .monday, .tuesday, .wednesday, .thursday, .friday
    ]

    init?(calendarWeekday: Int) {
        self.init(rawValue: calendarWeekday)
    }

    static func summary(for weekdays: Set<Weekday>) -> String {
        let ordered = Weekday.allCases.filter { weekdays.contains($0) }
        guard !ordered.isEmpty else { return "Every day" }
        if ordered == Weekday.allCases {
            return "Every day"
        }
        if Set(ordered) == Weekday.weekdays {
            return "Mon–Fri"
        }
        if ordered.count == 1, let day = ordered.first {
            return day.shortLabel
        }
        return ordered.map(\.shortLabel).joined(separator: ", ")
    }
}

extension UserProfile {
    mutating func syncCommuteScheduleFromLocations() {
        if let work = locations.first(where: { $0.label == .work }) {
            commuteSchedule.arriveAtWorkBy = work.schedule.arriveBy
        }
        if let home = locations.first(where: { $0.label == .home }) {
            commuteSchedule.arriveHomeBy = home.schedule.arriveBy
        }
    }

    mutating func migrateLocationSchedulesIfNeeded() {
        for index in locations.indices where locations[index].schedule == .empty && locations[index].label != .other {
            locations[index].schedule = PlaceSchedule.defaulted(
                for: locations[index].label,
                commuteSchedule: commuteSchedule
            )
        }
    }
}
