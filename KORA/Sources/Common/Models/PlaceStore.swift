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
        migrateLowResPhotos()
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
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Place].self, from: data) {
            places = decoded
        }
    }

    /// One-time migration: clear `photoURLs` and `imageURL` for every saved
    /// place so the backfill (`SaveViewModel.backfillMissingImages`) re-runs
    /// on next launch and pulls full-resolution images instead of the small
    /// Naver thumbnails / Kakao `smallurl` we used to store. Runs at most
    /// once per device, gated by a UserDefaults flag.
    private func migrateLowResPhotos() {
        let key = "kora_did_clear_lowres_photos_v1"
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: key) else { return }

        var copy = places
        var changed = false
        for i in copy.indices {
            if copy[i].photoURLs != nil || copy[i].imageURL != nil {
                copy[i].photoURLs = nil
                copy[i].imageURL = nil
                changed = true
            }
        }
        if changed {
            places = copy   // batched: single didSet → single persist
        }
        defaults.set(true, forKey: key)
    }

    /// Reads places saved by the Share Extension from the App Group JSON queue,
    /// merges them into the store, and deletes the queue file.
    func drainExtensionQueue() {
        guard let dir = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.kora.leeo") else { return }
        let fileURL = dir.appendingPathComponent("pending_places.json")
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let queued = (try? JSONDecoder().decode([Place].self, from: data)) ?? []
        try? FileManager.default.removeItem(at: fileURL)
        guard !queued.isEmpty else { return }
        let existingIDs = Set(places.map(\.id))
        let toAdd = queued.filter { !existingIDs.contains($0.id) }
        guard !toAdd.isEmpty else { return }
        places.insert(contentsOf: toAdd, at: 0)
    }
}
