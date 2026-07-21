import SwiftUI

enum JourneyHeadlineBuilder {
    static func parts(firstName: String, destination: SavedLocation) -> [OnboardingHeadline.HeadlinePart] {
        let name = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        var result: [OnboardingHeadline.HeadlinePart] = [
            .serif(name.isEmpty ? "You" : name),
            .plain(", here are your options for today's journey ")
        ]

        switch destination.label {
        case .home:
            result.append(.serif("home"))
        case .work, .other:
            result.append(contentsOf: [.plain("to "), .serif(destination.displayName)])
        }

        result.append(.plain("."))
        return result
    }
}
