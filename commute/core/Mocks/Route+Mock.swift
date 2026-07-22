import Foundation

extension Route {
    static func mockRoutes(from: SavedLocation, to: SavedLocation) -> [Route] {
        _ = (from, to)
        return [
            Route(
                summary: "Via the Elizabeth line",
                totalMinutes: 22,
                legs: [
                    .walk(minutes: 7, distanceMiles: 0.4),
                    .transit(
                        line: .elizabethLine,
                        from: "Tottenham Court Road",
                        to: "Paddington",
                        departureTime: mockTime(hour: 8, minute: 47),
                        platform: "P6",
                        stops: 3
                    ),
                    .walk(minutes: 4, distanceMiles: 0.2)
                ],
                status: .goodService
            ),
            Route(
                summary: "Via the Central line",
                totalMinutes: 28,
                legs: [
                    .walk(minutes: 5, distanceMiles: 0.3),
                    .transit(
                        line: .central,
                        from: "Holborn",
                        to: "Notting Hill Gate",
                        departureTime: mockTime(hour: 8, minute: 51),
                        platform: nil,
                        stops: 5
                    ),
                    .walk(minutes: 6, distanceMiles: 0.35)
                ],
                status: .minorDelays
            ),
            Route(
                summary: "Via the Circle line",
                totalMinutes: 34,
                legs: [
                    .walk(minutes: 9, distanceMiles: 0.5),
                    .transit(
                        line: .circle,
                        from: "Farringdon",
                        to: "Bayswater",
                        departureTime: mockTime(hour: 8, minute: 55),
                        platform: nil,
                        stops: 7
                    ),
                    .walk(minutes: 3, distanceMiles: 0.15)
                ],
                status: .goodService
            )
        ]
    }

    private static func mockTime(hour: Int, minute: Int) -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? .now
    }
}
