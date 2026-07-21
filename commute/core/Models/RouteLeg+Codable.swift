import Foundation

extension RouteLeg: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case minutes
        case distanceMiles
        case line
        case from
        case to
        case departureTime
        case platform
        case stops
        case lineLabel
    }

    private enum LegType: String, Codable {
        case walk
        case transit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(LegType.self, forKey: .type)
        switch type {
        case .walk:
            self = .walk(
                minutes: try container.decode(Int.self, forKey: .minutes),
                distanceMiles: try container.decode(Double.self, forKey: .distanceMiles)
            )
        case .transit:
            self = .transit(
                line: try container.decode(TfLLine.self, forKey: .line),
                from: try container.decode(String.self, forKey: .from),
                to: try container.decode(String.self, forKey: .to),
                departureTime: try container.decode(String.self, forKey: .departureTime),
                platform: try container.decodeIfPresent(String.self, forKey: .platform),
                stops: try container.decode(Int.self, forKey: .stops),
                lineLabel: try container.decodeIfPresent(String.self, forKey: .lineLabel)
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .walk(let minutes, let distanceMiles):
            try container.encode(LegType.walk, forKey: .type)
            try container.encode(minutes, forKey: .minutes)
            try container.encode(distanceMiles, forKey: .distanceMiles)
        case .transit(let line, let from, let to, let departureTime, let platform, let stops, let lineLabel):
            try container.encode(LegType.transit, forKey: .type)
            try container.encode(line, forKey: .line)
            try container.encode(from, forKey: .from)
            try container.encode(to, forKey: .to)
            try container.encode(departureTime, forKey: .departureTime)
            try container.encodeIfPresent(platform, forKey: .platform)
            try container.encode(stops, forKey: .stops)
            try container.encodeIfPresent(lineLabel, forKey: .lineLabel)
        }
    }
}
