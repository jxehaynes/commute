import Combine
import Foundation
import SwiftUI

@MainActor
final class SavedLocationsEditorViewModel: ObservableObject {
    @Published var locations: [SavedLocation] = []
    @Published var editingLocationID: UUID?

    /// Frozen copies for editor bindings while a sheet is tearing down after delete.
    private var staleEditingLocations: [UUID: SavedLocation] = [:]

    func load(from saved: [SavedLocation]) {
        staleEditingLocations.removeAll()
        editingLocationID = nil

        var home = saved.first(where: { $0.label == .home })
        var work = saved.first(where: { $0.label == .work })
        let extras = saved.filter { $0.label == .other }

        if home == nil {
            home = SavedLocation.mock(label: .home, address: "")
        }
        if work == nil {
            work = SavedLocation.mock(label: .work, customName: "Work", address: "")
        }

        locations = [home, work].compactMap { $0 } + extras
    }

    func binding(for id: UUID) -> Binding<SavedLocation>? {
        guard locations.contains(where: { $0.id == id })
            || staleEditingLocations[id] != nil else { return nil }

        return Binding(
            get: {
                if let index = self.locations.firstIndex(where: { $0.id == id }) {
                    return self.locations[index]
                }
                return self.staleEditingLocations[id]
                    ?? SavedLocation.mock(label: .other, customName: "Place", address: "")
            },
            set: { newValue in
                guard let index = self.locations.firstIndex(where: { $0.id == id }) else { return }
                self.locations[index] = newValue
            }
        )
    }

    func clearStaleEditingLocations() {
        staleEditingLocations.removeAll()
    }

    func addExtra() {
        let place = SavedLocation(
            label: .other,
            customName: "New place",
            address: "",
            coordinate: SavedLocation.mock(label: .other).coordinate
        )
        locations.append(place)
        editingLocationID = place.id
    }

    func deleteExtra(id: UUID) {
        if let location = locations.first(where: { $0.id == id }) {
            staleEditingLocations[id] = location
        }
        if editingLocationID == id {
            editingLocationID = nil
        }
        locations.removeAll { $0.id == id && $0.label == .other }
    }

    func canDelete(_ location: SavedLocation) -> Bool {
        location.label == .other
    }

    func buildLocations() -> [SavedLocation] {
        locations.filter { !$0.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var homeBinding: Binding<SavedLocation>? {
        guard let home = locations.first(where: { $0.label == .home }) else { return nil }
        return binding(for: home.id)
    }

    var workBinding: Binding<SavedLocation>? {
        guard let work = locations.first(where: { $0.label == .work }) else { return nil }
        return binding(for: work.id)
    }

    var extraLocations: [SavedLocation] {
        locations.filter { $0.label == .other }
    }
}
