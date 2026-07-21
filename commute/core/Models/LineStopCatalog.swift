import Foundation

struct BusRoute: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let displayNumber: String

    static let londonRoutes: [BusRoute] = [
        BusRoute(id: "38", name: "Victoria ↔ Clapton Pond", displayNumber: "38"),
        BusRoute(id: "73", name: "Victoria ↔ Stoke Newington", displayNumber: "73"),
        BusRoute(id: "RV1", name: "Tower Gateway ↔ Covent Garden", displayNumber: "RV1"),
        BusRoute(id: "149", name: "London Bridge ↔ Edmonton Green", displayNumber: "149"),
        BusRoute(id: "390", name: "Victoria ↔ Notting Hill Gate", displayNumber: "390")
    ]
}

enum LineStopCatalog {
    static let commonPlaces: [String] = [
        "Home",
        "Work",
        "Holborn",
        "Tottenham Court Road",
        "King's Cross St Pancras",
        "Farringdon",
        "Paddington",
        "Bank",
        "London Bridge",
        "Victoria",
        "Waterloo"
    ]

    static func trainLines() -> [TfLLine] {
        [.central, .northern, .victoria, .elizabethLine, .circle, .district, .jubilee, .piccadilly, .overground, .bakerloo, .metropolitan]
    }

    static func stops(forTrain line: TfLLine) -> [String] {
        trainStops[line] ?? commonPlaces
    }

    static func stops(forBus routeID: String) -> [String] {
        busStops[routeID] ?? commonPlaces
    }

    static func places(for mode: CommuteStepMode) -> [String] {
        commonPlaces
    }

    static func stopCount(from: String, to: String, lineID: String?) -> Int {
        let stopList: [String]
        if let lineID, let line = TfLLine(rawValue: lineID) {
            stopList = stops(forTrain: line)
        } else if let lineID {
            stopList = stops(forBus: lineID)
        } else {
            return 2
        }
        guard let fromIndex = stopList.firstIndex(of: from),
              let toIndex = stopList.firstIndex(of: to) else { return 2 }
        return max(abs(toIndex - fromIndex), 1)
    }

    static func estimatedMinutes(mode: CommuteStepMode, from: String, to: String, lineID: String?) -> Int {
        switch mode {
        case .walk: return 8
        case .drive: return 12
        case .bus, .train:
            return max(stopCount(from: from, to: to, lineID: lineID) * 2, 4)
        }
    }

    private static let trainStops: [TfLLine: [String]] = [
        .central: ["Ealing Broadway", "Notting Hill Gate", "Holborn", "Tottenham Court Road", "Bank", "Liverpool Street", "Stratford"],
        .northern: ["Edgware", "Camden Town", "King's Cross St Pancras", "Bank", "London Bridge", "Morden"],
        .victoria: ["Walthamstow Central", "King's Cross St Pancras", "Green Park", "Victoria", "Brixton"],
        .elizabethLine: ["Reading", "Paddington", "Tottenham Court Road", "Farringdon", "Liverpool Street", "Canary Wharf"],
        .circle: ["Paddington", "King's Cross St Pancras", "Liverpool Street", "Embankment", "Victoria", "Notting Hill Gate"],
        .district: ["Richmond", "Earl's Court", "Victoria", "Westminster", "Tower Hill", "Upminster"],
        .jubilee: ["Stanmore", "Finchley Road", "Westminster", "London Bridge", "Canary Wharf", "Stratford"],
        .piccadilly: ["Heathrow Terminal 5", "Earl's Court", "King's Cross St Pancras", "Holborn", "Leicester Square", "Cockfosters"],
        .overground: ["Richmond", "Clapham Junction", "Highbury & Islington", "Stratford", "Crystal Palace"],
        .bakerloo: ["Harrow & Wealdstone", "Paddington", "Oxford Circus", "Waterloo", "Elephant & Castle"],
        .metropolitan: ["Amersham", "Wembley Park", "Finchley Road", "King's Cross St Pancras", "Liverpool Street", "Aldgate"]
    ]

    private static let busStops: [String: [String]] = [
        "38": ["Victoria", "Piccadilly Circus", "Holborn", "Angel", "Dalston Junction", "Clapton Pond"],
        "73": ["Victoria", "Waterloo", "Elephant & Castle", "Old Street", "Stoke Newington"],
        "RV1": ["Tower Gateway", "London Bridge", "Southwark", "Waterloo", "Covent Garden"],
        "149": ["London Bridge", "Bank", "Liverpool Street", "Shoreditch", "Edmonton Green"],
        "390": ["Victoria", "Hyde Park Corner", "Marble Arch", "Notting Hill Gate"]
    ]
}
