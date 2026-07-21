import SwiftUI

/// Broad groupings of `TfLLine` used for the user's line-visibility
/// preferences, set during onboarding and editable later in Settings.
///
/// `bus` exists only so `TfLLine.category` has somewhere to point a bus leg —
/// TfL doesn't publish line-level bus status, so buses never appear in the
/// disruption feed this preference filters, and there's deliberately no
/// toggle for it. `allCases` is overridden below to keep it out of the picker.
enum TransitLineCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case tube, overground, dlr, elizabethLine, thameslink, nationalRail, bus

    static var allCases: [TransitLineCategory] {
        [.tube, .overground, .dlr, .elizabethLine, .thameslink, .nationalRail]
    }

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tube: "Tube"
        case .overground: "Overground"
        case .dlr: "DLR"
        case .elizabethLine: "Elizabeth line"
        case .thameslink: "Thameslink"
        case .nationalRail: "National Rail"
        case .bus: "Bus"
        }
    }

    var summary: String {
        switch self {
        case .tube: "All eleven London Underground lines."
        case .overground: "Liberty, Lioness, Mildmay, Suffragette, Weaver and Windrush."
        case .dlr: "Docklands Light Railway."
        case .elizabethLine: "The Elizabeth line, end to end."
        case .thameslink: "Thameslink services through central London."
        case .nationalRail: "Other National Rail operators serving London — pick which ones."
        case .bus: "London bus routes."
        }
    }

    var systemImage: String {
        switch self {
        case .tube: "circle.grid.2x2.fill"
        case .overground, .elizabethLine, .thameslink: "tram.fill"
        case .dlr: "tram.tunnel.fill"
        case .nationalRail: "train.side.front.car"
        case .bus: "bus.fill"
        }
    }

    /// Representative brand colors shown as a small swatch cluster next to
    /// the category toggle, so the color scheme is visible before the user
    /// even opts in.
    var representativeColors: [Color] {
        switch self {
        case .tube:
            [TfLLine.central, .piccadilly, .victoria, .district].map(\.brandColor)
        case .overground:
            [TfLLine.liberty, .lioness, .mildmay, .suffragette, .weaver, .windrush].map(\.brandColor)
        case .dlr:
            [TfLLine.dlr.brandColor]
        case .elizabethLine:
            [TfLLine.elizabethLine.brandColor]
        case .thameslink:
            [TfLLine.thameslink.brandColor]
        case .nationalRail:
            [TfLLine.nationalRail.brandColor]
        case .bus:
            [TfLLine.bus.brandColor]
        }
    }

    /// London-area National Rail operators a user can individually opt into
    /// once the National Rail category is enabled.
    static let londonAreaNationalRailOperators: [TfLLine] = [
        .southeastern, .southern, .southWesternRailway, .greatWesternRailway,
        .chilternRailways, .greatNorthern, .greaterAnglia, .c2c,
        .gatwickExpress, .heathrowExpress
    ]
}
