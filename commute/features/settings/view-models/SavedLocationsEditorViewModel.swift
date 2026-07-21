import Combine
import Foundation
import SwiftUI

@MainActor
final class SavedLocationsEditorViewModel: ObservableObject {
    @Published var homeAddress = ""
    @Published var workAddress = ""
    @Published var otherName = ""
    @Published var otherAddress = ""

    private var homeLocation: SavedLocation?
    private var workLocation: SavedLocation?
    private var otherLocation: SavedLocation?

    func load(from locations: [SavedLocation]) {
        homeAddress = ""
        workAddress = ""
        otherName = ""
        otherAddress = ""
        homeLocation = nil
        workLocation = nil
        otherLocation = nil

        for location in locations {
            switch location.label {
            case .home:
                homeLocation = location
                homeAddress = location.address
            case .work:
                workLocation = location
                workAddress = location.address
            case .other:
                otherLocation = location
                otherAddress = location.address
                otherName = location.customName ?? ""
            }
        }
    }

    func buildLocations() -> [SavedLocation] {
        commitLocationEdits()
        var locations: [SavedLocation] = []
        if !homeAddress.trimmingCharacters(in: .whitespaces).isEmpty, let home = homeLocation {
            locations.append(home)
        }
        if !workAddress.trimmingCharacters(in: .whitespaces).isEmpty, let work = workLocation {
            locations.append(work)
        }
        if !otherAddress.trimmingCharacters(in: .whitespaces).isEmpty, let other = otherLocation {
            locations.append(other)
        }
        return locations
    }

    func selectLocation(_ result: ResolvedLocationSearchResult, label: SavedLocation.LocationLabel) {
        let customName: String?
        switch label {
        case .home:
            homeAddress = result.formattedAddress
            customName = nil
        case .work:
            workAddress = result.formattedAddress
            customName = "Work"
        case .other:
            otherAddress = result.formattedAddress
            customName = resolvedOtherName
        }

        let location = SavedLocation(
            id: existingID(for: label) ?? UUID(),
            label: label,
            customName: customName,
            address: result.formattedAddress,
            coordinate: result.coordinate,
            naptanId: nil,
            routingCoordinate: nil
        )

        setLocation(location)
    }

    private func commitLocationEdits() {
        if !homeAddress.trimmingCharacters(in: .whitespaces).isEmpty {
            if homeLocation?.address != homeAddress {
                homeLocation = savedLocation(
                    label: .home,
                    address: homeAddress,
                    existing: homeLocation
                )
            }
        }
        if !workAddress.trimmingCharacters(in: .whitespaces).isEmpty {
            if workLocation?.address != workAddress {
                workLocation = savedLocation(
                    label: .work,
                    customName: "Work",
                    address: workAddress,
                    existing: workLocation
                )
            }
        }
        if !otherAddress.trimmingCharacters(in: .whitespaces).isEmpty {
            if otherLocation?.address != otherAddress || otherLocation?.customName != resolvedOtherName {
                otherLocation = savedLocation(
                    label: .other,
                    customName: resolvedOtherName,
                    address: otherAddress,
                    existing: otherLocation
                )
            }
        }
    }

    private func savedLocation(
        label: SavedLocation.LocationLabel,
        customName: String? = nil,
        address: String,
        existing: SavedLocation?
    ) -> SavedLocation {
        let mock = SavedLocation.mock(label: label, customName: customName, address: address)
        return SavedLocation(
            id: existing?.id ?? UUID(),
            label: label,
            customName: customName,
            address: address,
            coordinate: existing?.address == address ? (existing?.coordinate ?? mock.coordinate) : mock.coordinate,
            naptanId: existing?.address == address ? existing?.naptanId : nil,
            routingCoordinate: existing?.address == address ? existing?.routingCoordinate : nil
        )
    }

    private func existingID(for label: SavedLocation.LocationLabel) -> UUID? {
        switch label {
        case .home: homeLocation?.id
        case .work: workLocation?.id
        case .other: otherLocation?.id
        }
    }

    private func setLocation(_ location: SavedLocation) {
        switch location.label {
        case .home:
            homeLocation = location
        case .work:
            workLocation = location
        case .other:
            otherLocation = location
        }
    }

    private var resolvedOtherName: String {
        otherName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Other" : otherName
    }
}
