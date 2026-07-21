import Foundation

struct MockDisruptionProvider: DisruptionProviding {
    var simulateDisruption: Bool = true

    func fetchDisruptions() async throws -> [Disruption] {
        guard simulateDisruption else { return [] }
        return [
            Disruption(
                line: .central,
                severity: .minorDelays,
                statusLabel: "Minor Delays",
                reason: "Minor delays between Marble Arch and Liverpool Street due to an earlier signal failure. Valid on until further notice."
            )
        ]
    }
}
