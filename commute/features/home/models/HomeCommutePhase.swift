import Foundation
import SwiftUI

enum HomeCommutePhase: Equatable {
    case preCommute(timeRemaining: TimeInterval)
    case duringDay(timeRemaining: TimeInterval)
    case afterCommute(otherLocationName: String?)
}

enum HomeGreetingBuilder {
    static func phase(
        schedule: CommuteSchedule,
        otherLocation: SavedLocation?,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> HomeCommutePhase {
        guard let leaveForWork = schedule.leaveForWork(on: now, calendar: calendar),
              let leaveForHome = schedule.leaveForHome(on: now, calendar: calendar) else {
            return .afterCommute(otherLocationName: otherLocation?.displayName)
        }

        if now < leaveForWork {
            return .preCommute(timeRemaining: leaveForWork.timeIntervalSince(now))
        }
        if now < leaveForHome {
            return .duringDay(timeRemaining: leaveForHome.timeIntervalSince(now))
        }
        return .afterCommute(otherLocationName: otherLocation?.displayName)
    }

    static func headlineParts(
        firstName: String,
        phase: HomeCommutePhase
    ) -> [OnboardingHeadline.HeadlinePart] {
        let name = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = name.isEmpty ? "there" : name
        switch phase {
        case .preCommute(let remaining):
            let duration = formatDuration(remaining)
            return [
                .plain("Morning, "),
                .serif(displayName),
                .plain("! Your train to work leaves in "),
                .serif(duration),
                .plain(".")
            ]
        case .duringDay(let remaining):
            let duration = formatDuration(remaining)
            return [
                .plain("Hey, "),
                .serif(displayName),
                .plain(". Don't worry, you only have "),
                .serif(duration),
                .plain(" until you can go home.")
            ]
        case .afterCommute(let otherName):
            if let otherName {
                return [
                    .plain("Evening, "),
                    .serif(displayName),
                    .plain(". Fancy a trip to "),
                    .serif(otherName),
                    .plain("?")
                ]
            }
            return [
                .plain("Evening, "),
                .serif(displayName),
                .plain(". You're off the clock — enjoy the rest of your night.")
            ]
        }
    }

    static func commuteButtonLabel(for phase: HomeCommutePhase) -> String {
        switch phase {
        case .preCommute:
            return "Head to Work"
        case .duringDay:
            return "Head Home"
        case .afterCommute:
            return "Plan journey"
        }
    }

    static func swipeToStartLabel(for phase: HomeCommutePhase) -> String {
        "Swipe to \(commuteButtonLabel(for: phase).lowercased())"
    }

    static func formatDuration(_ interval: TimeInterval) -> String {
        let totalMinutes = max(0, Int(interval.rounded(.down) / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        switch (hours, minutes) {
        case (0, 0):
            return "a moment"
        case (0, 1):
            return "1 minute"
        case (0, _):
            return "\(minutes) minutes"
        case (1, 0):
            return "1 hour"
        case (1, 1):
            return "1 hour, 1 minute"
        case (1, _):
            return "1 hour, \(minutes) minutes"
        case (_, 0):
            return "\(hours) hours"
        case (_, 1):
            return "\(hours) hours, 1 minute"
        default:
            return "\(hours) hours, \(minutes) minutes"
        }
    }
}
