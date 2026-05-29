import SwiftUI
import CryptoKit

// MARK: - Disk cache

actor DiskImageCache {
    static let shared = DiskImageCache()

    private let dir: URL

    private init() {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        dir = base.appendingPathComponent("KORAImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    func image(for urlString: String) -> UIImage? {
        let file = dir.appendingPathComponent(key(for: urlString))
        guard let data = try? Data(contentsOf: file) else { return nil }
        return UIImage(data: data)
    }

    func store(_ data: Data, for urlString: String) {
        let file = dir.appendingPathComponent(key(for: urlString))
        try? data.write(to: file, options: .atomic)
    }

    func load(urlString: String) async throws -> UIImage {
        if let cached = image(for: urlString) { return cached }
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let img = UIImage(data: data) else { throw URLError(.cannotDecodeContentData) }
        store(data, for: urlString)
        return img
    }

    private func key(for urlString: String) -> String {
        let hash = SHA256.hash(data: Data(urlString.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - CachedAsyncImage

enum CachedImagePhase {
    case loading
    case success(Image)
    case failure
}

struct CachedAsyncImage<Content: View>: View {
    let urlString: String
    @ViewBuilder let content: (CachedImagePhase) -> Content

    @State private var phase: CachedImagePhase = .loading

    var body: some View {
        content(phase)
            .task(id: urlString) { await fetch() }
    }

    private func fetch() async {
        phase = .loading
        do {
            let img = try await DiskImageCache.shared.load(urlString: urlString)
            phase = .success(Image(uiImage: img))
        } catch {
            phase = .failure
        }
    }
}
