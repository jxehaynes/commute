import CommuteKit
import Foundation

struct UsualRouteDisruption: Equatable {
    var line: TfLLine
    var severity: DisruptionLevel
    var message: String
}

enum UsualRouteDisruptionChecker {
    static func worstDisruption(
        for profile: UserProfile,
        leg: CommuteLeg,
        disruptions: [Disruption]
    ) -> UsualRouteDisruption? {
        let lines = usualLines(for: profile, leg: leg)
        guard !lines.isEmpty else { return nil }

        let matching = disruptions.filter { disruption in
            lines.contains(disruption.line)
                || (lines.contains(.nationalRail) && disruption.line.isNationalRailOperator)
        }

        return matching
            .sorted { severityRank($0.severity) > severityRank($1.severity) }
            .first
            .flatMap { disruption in
                guard disruption.severity != .goodService else { return nil }
                return UsualRouteDisruption(
                    line: disruption.line,
                    severity: mapSeverity(disruption.severity),
                    message: disruption.summarizedReason.isEmpty ? disruption.statusLabel : disruption.summarizedReason
                )
            }
    }

    static func usualLines(for profile: UserProfile, leg: CommuteLeg) -> Set<TfLLine> {
        if let customRoute = profile.journeyRoute(from: leg.origin, to: leg.destination), customRoute.isValid {
            return Set(customRoute.steps.compactMap { step -> TfLLine? in
                guard let raw = step.lineID else { return nil }
                return TfLLine(rawValue: raw)
            })
        }

        if let pattern = profile.preferredCommutePattern {
            let fromIDs = Set(pattern.lineIDs.compactMap(TfLLine.init(rawValue:)))
            if !fromIDs.isEmpty { return fromIDs }

            return Set(pattern.lineLabels.compactMap { label in
                TfLLine.allCases.first {
                    label.localizedCaseInsensitiveContains($0.displayName)
                        || $0.displayName.localizedCaseInsensitiveContains(label)
                }
            })
        }

        return []
    }

    private static func mapSeverity(_ severity: Route.LineStatus) -> DisruptionLevel {
        switch severity {
        case .goodService, .unknown:
            return .onTime
        case .minorDelays:
            return .minor
        case .severeDelays, .suspended:
            return .severe
        }
    }

    private static func severityRank(_ severity: Route.LineStatus) -> Int {
        switch severity {
        case .goodService, .unknown: 0
        case .minorDelays: 1
        case .severeDelays: 2
        case .suspended: 3
        }
    }
}
