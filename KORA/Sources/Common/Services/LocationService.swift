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

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestOnce() async throws -> CLLocationCoordinate2D {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<CLLocationCoordinate2D, Error>) in
                self.continuation = cont
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
        guard let cont = continuation else { return }
        continuation = nil
        switch result {
        case .success(let c): cont.resume(returning: c)
        case .failure(let e): cont.resume(throwing: e)
        }
    }
}
