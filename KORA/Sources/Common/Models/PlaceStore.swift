import Foundation
import Observation

@MainActor
@Observable
final class PlaceStore {
    static let shared = PlaceStore()

    private(set) var places: [Place] = [] {
        didSet { persist() }
    }

    private let storageKey = "kora_saved_places"

    private init() {
        load()
    }

    func add(_ place: Place) {
        places.insert(place, at: 0)
    }

    func update(_ place: Place) {
        guard let idx = places.firstIndex(where: { $0.id == place.id }) else { return }
        places[idx] = place
    }

    func delete(_ place: Place) {
        places.removeAll { $0.id == place.id }
    }

    func delete(at offsets: IndexSet) {
        places.remove(atOffsets: offsets)
    }

    func filtered(by category: PlaceCategory?) -> [Place] {
        guard let category else { return places }
        return places.filter { $0.category == category }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(places) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Place].self, from: data)
        else { return }
        places = decoded
    }
}
