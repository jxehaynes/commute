import SwiftUI

struct LineChipView: View {
    let line: TfLLine
    var compact: Bool = false

    var body: some View {
        Group {
            if compact {
                Text(line.compactLabel)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(line == .circle ? Color.black : Color.white)
                    .frame(width: 26, height: 26)
                    .background(line.brandColor)
                    .clipShape(Circle())
            } else {
                Text(line.displayName)
                    .font(Theme.Fonts.lineChip)
                    .foregroundStyle(line == .circle ? Color.black : Color.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(line.brandColor)
                    .clipShape(Capsule())
            }
        }
        .accessibilityLabel("\(line.displayName) line")
    }
}

struct TransitLineChipView: View {
    let line: TfLLine
    var lineLabel: String?
    var compact: Bool = false

    var body: some View {
        if Self.isBus(line: line, lineLabel: lineLabel) {
            busChip(number: Self.busNumber(lineLabel: lineLabel))
        } else if let genericLabel {
            genericChip(label: genericLabel)
        } else {
            LineChipView(line: line, compact: compact)
        }
    }

    private var genericLabel: String? { Self.genericLabel(line: line, lineLabel: lineLabel) }

    /// A leg counts as a bus either because it's structurally tagged `.bus`, or — as a fallback
    /// for anything upstream that hasn't been updated to do that — because its label says so.
    /// The structural check matters: TfL's journey API doesn't always return a route name, and
    /// text-sniffing alone left unlabelled bus legs falling through to a generic National Rail chip.
    static func isBus(line: TfLLine, lineLabel: String?) -> Bool {
        line == .bus || busNumber(lineLabel: lineLabel) != nil
    }

    static func busNumber(lineLabel: String?) -> String? {
        guard let lineLabel else { return nil }
        let cleaned = lineLabel
            .replacingOccurrences(of: "Bus route ", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Bus ", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if lineLabel.localizedCaseInsensitiveContains("bus"), !cleaned.isEmpty {
            return cleaned.components(separatedBy: .whitespacesAndNewlines).first
        }

        return nil
    }

    static func genericLabel(line: TfLLine, lineLabel: String?) -> String? {
        guard let lineLabel,
              !isBus(line: line, lineLabel: lineLabel),
              line == .nationalRail || line.isNationalRailOperator || lineLabel.localizedCaseInsensitiveContains("apple") else {
            return nil
        }

        let trimmed = lineLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed
    }

    /// A short badge label for this line, ignoring layout/color — used when combining several
    /// grouped lines into one chip (e.g. "225" to be joined as "225 / 141").
    static func shortLabel(line: TfLLine, lineLabel: String?) -> String {
        if isBus(line: line, lineLabel: lineLabel) {
            return busNumber(lineLabel: lineLabel) ?? line.displayName
        }
        return genericLabel(line: line, lineLabel: lineLabel) ?? line.displayName
    }

    static func accessibilityLabel(line: TfLLine, lineLabel: String?) -> String {
        if isBus(line: line, lineLabel: lineLabel) {
            if let busNumber = busNumber(lineLabel: lineLabel) {
                return "Bus \(busNumber)"
            }
            return "Bus"
        }
        if let genericLabel = genericLabel(line: line, lineLabel: lineLabel) {
            return genericLabel
        }
        return "\(line.displayName) line"
    }

    private func busChip(number: String?) -> some View {
        HStack(spacing: compact ? 0 : 5) {
            Image(systemName: "bus.fill")
                .font(.system(size: 11, weight: .bold))
            if let number {
                Text(number)
                    .font(Theme.Fonts.lineChip)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 5 : 6)
        .background(TfLLine.bus.brandColor)
        .clipShape(RoundedRectangle(cornerRadius: compact ? 8 : 10, style: .continuous))
        .accessibilityLabel(number.map { "Bus \($0)" } ?? "Bus")
    }

    private func genericChip(label: String) -> some View {
        HStack(spacing: compact ? 0 : 5) {
            if !compact {
                Image(systemName: "tram.fill")
                    .font(.system(size: 11, weight: .bold))
            }
            Text(label)
                .font(Theme.Fonts.lineChip)
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 5 : 6)
        .background(line.brandColor)
        .clipShape(Capsule())
        .accessibilityLabel(label)
    }
}

struct GroupedTransitLineChipView: View {
    let options: [TransitLineOption]
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                if index > 0 {
                    Text("/")
                        .font(Theme.Fonts.lineChip)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                badge(label: label)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var labels: [String] {
        options.map { option in
            TransitLineChipView.shortLabel(line: option.line, lineLabel: option.lineLabel)
        }
    }

    private var accessibilityLabel: String {
        options
            .map { option in TransitLineChipView.accessibilityLabel(line: option.line, lineLabel: option.lineLabel) }
            .joined(separator: " or ")
    }

    private func badge(label: String) -> some View {
        Text(label)
            .font(Theme.Fonts.lineChip)
            .lineLimit(1)
            .foregroundStyle(.white)
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 5 : 6)
            .background(options.first?.line.brandColor ?? TfLLine.bus.brandColor)
            .clipShape(RoundedRectangle(cornerRadius: compact ? 8 : 10, style: .continuous))
    }
}

private extension TfLLine {
    var compactLabel: String {
        switch self {
        case .elizabethLine: "E"
        case .hammersmithAndCity: "H"
        case .waterlooAndCity: "W"
        case .overground: "O"
        case .liberty: "LI"
        case .lioness: "LX"
        case .mildmay: "MM"
        case .suffragette: "SU"
        case .weaver: "WV"
        case .windrush: "WR"
        case .nationalRail: "R"
        case .bus: "BUS"
        case .thameslink: "T"
        case .southWesternRailway: "SW"
        case .greatWesternRailway: "GW"
        case .londonNorthEasternRailway: "LN"
        case .eastMidlandsRailway: "EM"
        case .gatwickExpress: "GX"
        case .heathrowExpress: "HX"
        case .chilternRailways: "CH"
        case .greaterAnglia: "GA"
        case .transpennineExpress: "TP"
        case .transportForWales: "TW"
        case .avantiWestCoast: "AW"
        case .westMidlandsTrains: "WM"
        default: String(displayName.prefix(1))
        }
    }
}
