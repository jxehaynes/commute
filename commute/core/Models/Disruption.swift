import Foundation

struct Disruption: Identifiable, Equatable, Hashable {
    let line: TfLLine
    let severity: Route.LineStatus
    let statusLabel: String
    let reason: String

    var id: TfLLine { line }

    var summarizedReason: String {
        Self.summarize(reason)
    }

    static func summarize(_ raw: String, maxLength: Int = 140) -> String {
        let cleaned = cleaned(raw)
        guard !cleaned.isEmpty else { return "" }

        let parts = cleaned
            .replacingOccurrences(of: "\n", with: " ")
            .components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var summary = parts.prefix(2).joined(separator: ". ")
        if parts.count > 1, !summary.hasSuffix(".") {
            summary += "."
        }

        if summary.count <= maxLength {
            return summary
        }

        let trimmed = String(summary.prefix(maxLength - 1))
        if let lastSpace = trimmed.lastIndex(of: " ") {
            return String(trimmed[..<lastSpace]) + "…"
        }
        return trimmed + "…"
    }

    private static func cleaned(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
