import CoreLocation
import Observation

/// Lightweight one-shot location helper.
///
/// Usage:
///     let loc = LocationService()
///     let coord = try await loc.requestOnce()
@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {

    enum LocationError: LocalizedError {
        case denied
        case unavailable
        case timeout

        var errorDescription: String? {
            switch self {
            case .denied:
                return "位置情報の権限が許可されていません（設定 → KORA → 位置情報）"
            case .unavailable:
                #if targetEnvironment(simulator)
                return "シミュレータの位置が未設定です（Features → Location → Custom Location）"
                #else
                return "現在地を取得できませんでした。手動で出発駅を選んでください"
                #endif
            case .timeout:
                return "位置情報の取得がタイムアウトしました"
            }
        }
    }

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    private var timeoutTask: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        // Hundred-meter accuracy is plenty for nearest-station matching and gets
        // a fix far faster than a navigation-grade fix.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// One-shot location.
    /// - `maxAge`: if the OS already has a cached fix newer than this, return it
    ///   immediately (no waiting for a fresh fix) — this is what makes repeat
    ///   lookups feel instant.
    /// - `timeout`: never hang; after this, fall back to any cached fix or fail.
    func requestOnce(maxAge: TimeInterval = 60, timeout: TimeInterval = 4) async throws -> CLLocationCoordinate2D {
        // Fast path: a recent cached fix.
        if let cached = cachedCoordinate(maxAge: maxAge) { return cached }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<CLLocationCoordinate2D, Error>) in
                self.continuation = cont
                self.timeoutTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(timeout))
                    guard !Task.isCancelled else { return }
                    // Timed out — settle for any cached fix, else surface timeout.
                    if let cached = self.cachedCoordinate(maxAge: .infinity) {
                        self.finish(.success(cached))
                    } else {
                        self.finish(.failure(LocationError.timeout))
                    }
                }
                switch manager.authorizationStatus {
                case .notDetermined:
                    manager.requestWhenInUseAuthorization()
                case .authorizedWhenInUse, .authorizedAlways:
                    manager.requestLocation()
                default:
                    self.finish(.failure(LocationError.denied))
                }
            }
        } onCancel: {
            Task { @MainActor in self.finish(.failure(CancellationError())) }
        }
    }

    /// The OS's last-known fix, if present and not older than `maxAge`.
    private func cachedCoordinate(maxAge: TimeInterval) -> CLLocationCoordinate2D? {
        guard let loc = manager.location, loc.horizontalAccuracy >= 0 else { return nil }
        if maxAge.isFinite, abs(loc.timestamp.timeIntervalSinceNow) > maxAge { return nil }
        return loc.coordinate
    }

    nonisolated func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        Task { @MainActor in
            switch m.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                m.requestLocation()
            case .denied, .restricted:
                self.finish(.failure(LocationError.denied))
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.last?.coordinate else { return }
        Task { @MainActor in self.finish(.success(coord)) }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.finish(.failure(LocationError.unavailable)) }
    }

    private func finish(_ result: Result<CLLocationCoordinate2D, Error>) {
        timeoutTask?.cancel()
        timeoutTask = nil
        guard let cont = continuation else { return }
        continuation = nil
        switch result {
        case .success(let c): cont.resume(returning: c)
        case .failure(let e): cont.resume(throwing: e)
        }
    }
}
