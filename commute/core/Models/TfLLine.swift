import SwiftUI

enum TfLLine: String, Codable, CaseIterable, Hashable {
    case bakerloo, central, circle, district, elizabethLine, hammersmithAndCity
    case jubilee, metropolitan, northern, piccadilly, victoria, waterlooAndCity
    case overground, dlr, elizabethExpress, tflRail, liberty, lioness, mildmay
    case suffragette, weaver, windrush
    case nationalRail
    case bus
    case thameslink, southeastern, southern, southWesternRailway, greatWesternRailway
    case chilternRailways, greatNorthern, greaterAnglia, c2c
    case gatwickExpress, heathrowExpress, eastMidlandsRailway
    case londonNorthEasternRailway, crosscountry, avantiWestCoast
    case westMidlandsTrains, grandCentral, hullTrains, lumo
    case transpennineExpress, transportForWales, northernRail
    case merseyrail, scotrail, islandLine

    var displayName: String {
        switch self {
        case .central: "Central"
        case .circle: "Circle"
        case .elizabethLine: "Elizabeth"
        case .hammersmithAndCity: "H&C"
        case .waterlooAndCity: "W&C"
        case .overground: "Overground"
        case .dlr: "DLR"
        case .nationalRail: "National Rail"
        case .bus: "Bus"
        case .southWesternRailway: "South Western"
        case .greatWesternRailway: "GWR"
        case .chilternRailways: "Chiltern"
        case .greatNorthern: "Great Northern"
        case .greaterAnglia: "Greater Anglia"
        case .gatwickExpress: "Gatwick Express"
        case .heathrowExpress: "Heathrow Express"
        case .eastMidlandsRailway: "East Midlands"
        case .londonNorthEasternRailway: "LNER"
        case .avantiWestCoast: "Avanti"
        case .westMidlandsTrains: "West Midlands"
        case .grandCentral: "Grand Central"
        case .hullTrains: "Hull Trains"
        case .transpennineExpress: "TransPennine"
        case .transportForWales: "TfW"
        case .northernRail: "Northern"
        case .islandLine: "Island Line"
        default:
            String(rawValue.prefix(1).uppercased() + rawValue.dropFirst())
        }
    }

    var brandColor: Color {
        switch self {
        case .bakerloo: Color(hex: "B36305")
        case .central: Color(hex: "E32017")
        case .circle: Color(hex: "FFD300")
        case .district: Color(hex: "00782A")
        case .elizabethLine: Color(hex: "6950A1")
        case .hammersmithAndCity: Color(hex: "F3A9BB")
        case .jubilee: Color(hex: "A0A5A9")
        case .metropolitan: Color(hex: "9B0056")
        case .northern: Color(hex: "000000")
        case .piccadilly: Color(hex: "003688")
        case .victoria: Color(hex: "0098D4")
        case .waterlooAndCity: Color(hex: "95CDBA")
        case .overground: Color(hex: "EE7C0E")
        case .liberty: Color(hex: "606667")
        case .lioness: Color(hex: "EF9600")
        case .mildmay: Color(hex: "2774AE")
        case .suffragette: Color(hex: "5BA763")
        case .weaver: Color(hex: "893B67")
        case .windrush: Color(hex: "D22730")
        case .dlr: Color(hex: "00A4A7")
        case .bus: Color(hex: "DC241F")
        case .thameslink: Color(hex: "D282B9")
        case .nationalRail, .southeastern, .southern, .southWesternRailway,
             .greatWesternRailway, .chilternRailways, .greatNorthern, .greaterAnglia,
             .c2c, .gatwickExpress, .heathrowExpress, .eastMidlandsRailway,
             .londonNorthEasternRailway, .crosscountry, .avantiWestCoast,
             .westMidlandsTrains, .grandCentral, .hullTrains, .lumo,
             .transpennineExpress, .transportForWales, .northernRail,
             .merseyrail, .scotrail, .islandLine:
            Color(hex: "6E7278")
        default: Color(hex: "414141")
        }
    }

    var isNationalRailOperator: Bool {
        switch self {
        case .nationalRail, .thameslink, .southeastern, .southern, .southWesternRailway,
             .greatWesternRailway, .chilternRailways, .greatNorthern, .greaterAnglia,
             .c2c, .gatwickExpress, .heathrowExpress, .eastMidlandsRailway,
             .londonNorthEasternRailway, .crosscountry, .avantiWestCoast,
             .westMidlandsTrains, .grandCentral, .hullTrains, .lumo,
             .transpennineExpress, .transportForWales, .northernRail,
             .merseyrail, .scotrail, .islandLine:
            true
        default:
            false
        }
    }

    /// National Rail operators that actually serve Greater London / the commuter
    /// belt. TfL's national-rail status feed covers every operator in Britain
    /// (ScotRail, Transport for Wales, Northern, TransPennine, Hull Trains, ...);
    /// this narrows it to the ones relevant to a London commute.
    var isLondonAreaRailOperator: Bool {
        switch self {
        case .thameslink, .southeastern, .southern, .southWesternRailway,
             .greatWesternRailway, .chilternRailways, .greatNorthern, .greaterAnglia,
             .c2c, .gatwickExpress, .heathrowExpress:
            true
        case .nationalRail, .bus, .eastMidlandsRailway, .londonNorthEasternRailway,
             .crosscountry, .avantiWestCoast, .westMidlandsTrains, .grandCentral,
             .hullTrains, .lumo, .transpennineExpress, .transportForWales,
             .northernRail, .merseyrail, .scotrail, .islandLine:
            false
        default:
            true
        }
    }

    /// The broad category a line belongs to, used to drive the user's
    /// line-visibility preferences (onboarding + settings).
    var category: TransitLineCategory {
        switch self {
        case .bakerloo, .central, .circle, .district, .hammersmithAndCity,
             .jubilee, .metropolitan, .northern, .piccadilly, .victoria, .waterlooAndCity:
            .tube
        case .overground, .liberty, .lioness, .mildmay, .suffragette, .weaver, .windrush:
            .overground
        case .dlr:
            .dlr
        case .elizabethLine, .elizabethExpress, .tflRail:
            .elizabethLine
        case .thameslink:
            .thameslink
        case .bus:
            .bus
        case .nationalRail, .southeastern, .southern, .southWesternRailway,
             .greatWesternRailway, .chilternRailways, .greatNorthern, .greaterAnglia,
             .c2c, .gatwickExpress, .heathrowExpress, .eastMidlandsRailway,
             .londonNorthEasternRailway, .crosscountry, .avantiWestCoast,
             .westMidlandsTrains, .grandCentral, .hullTrains, .lumo,
             .transpennineExpress, .transportForWales, .northernRail,
             .merseyrail, .scotrail, .islandLine:
            .nationalRail
        }
    }
}
