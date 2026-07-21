import CoreLocation
import Foundation

struct SavedLocation: Codable, Identifiable, Equatable {
    let id: UUID
    var label: LocationLabel
    var customName: String?
    var address: String
    var coordinate: CLLocationCoordinate2D
    var naptanId: String? = nil
    var routingCoordinate: CLLocationCoordinate2D? = nil
    var schedule: PlaceSchedule

    init(
        id: UUID = UUID(),
        label: LocationLabel,
        customName: String? = nil,
        address: String,
        coordinate: CLLocationCoordinate2D,
        naptanId: String? = nil,
        routingCoordinate: CLLocationCoordinate2D? = nil,
        schedule: PlaceSchedule = .empty
    ) {
        self.id = id
        self.label = label
        self.customName = customName
        self.address = address
        self.coordinate = coordinate
        self.naptanId = naptanId
        self.routingCoordinate = routingCoordinate
        self.schedule = schedule
    }

    var displayName: String {
        switch label {
        case .home: "Home"
        case .work: customName ?? "Work"
        case .other: customName ?? "Somewhere else"
        }
    }

    /// Headline fragment: "home" or "to Work" — avoids "journey to Home".
    var journeyHeadlinePhrase: String {
        switch label {
        case .home: "home"
        case .work, .other: "to \(displayName)"
        }
    }

    enum LocationLabel: String, Codable, Equatable {
        case home, work, other
    }

    enum CodingKeys: String, CodingKey {
        case id, label, customName, address, coordinate, naptanId, routingCoordinate, schedule
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        label = try container.decode(LocationLabel.self, forKey: .label)
        customName = try container.decodeIfPresent(String.self, forKey: .customName)
        address = try container.decode(String.self, forKey: .address)
        coordinate = try container.decode(CLLocationCoordinate2D.self, forKey: .coordinate)
        naptanId = try container.decodeIfPresent(String.self, forKey: .naptanId)
        routingCoordinate = try container.decodeIfPresent(CLLocationCoordinate2D.self, forKey: .routingCoordinate)
        schedule = try container.decodeIfPresent(PlaceSchedule.self, forKey: .schedule) ?? .empty
    }
}

extension CLLocationCoordinate2D: @retroactive Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension CLLocationCoordinate2D: @retroactive Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let lat = try container.decode(Double.self)
        let lng = try container.decode(Double.self)
        self.init(latitude: lat, longitude: lng)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(latitude)
        try container.encode(longitude)
    }
}
