import SwiftUI

private struct ArrivalsRepositoryKey: EnvironmentKey {
    static let defaultValue = ArrivalsRepository()
}

extension EnvironmentValues {
    /// The shared `ArrivalsRepository` instance created in `commuteApp`, so
    /// every consumer (Directions view, previews, tests) polls through the
    /// same per-stop cache instead of each standing up its own.
    var arrivalsRepository: ArrivalsRepository {
        get { self[ArrivalsRepositoryKey.self] }
        set { self[ArrivalsRepositoryKey.self] = newValue }
    }
}
