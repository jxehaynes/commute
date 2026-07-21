import Foundation

protocol DisruptionProviding: Sendable {
    func fetchDisruptions() async throws -> [Disruption]
}
