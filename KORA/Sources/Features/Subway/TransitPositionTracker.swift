import CoreLocation
import CoreMotion
import SwiftUI

// MARK: - Transit Position Tracker

/// Estimates the user's current station index using three layered sources:
///   1. GPS  — matches nearest station within 300 m (best accuracy; fails underground)
///   2. Accelerometer — counts station stops via sustained-low-vibration pattern
///   3. Time — elapsed ÷ avg-secs-per-stop (always available; least accurate)
///
/// The three sources are combined with GPS > motion ≥ time, and the index
/// never goes backwards (prevents jitter when GPS signal drops in/out).
@MainActor
final class TransitPositionTracker: NSObject, ObservableObject {

    enum PositionSource {
        case gps, motion, time

        var icon: String {
            switch self {
            case .gps:    return "location.fill"
            case .motion: return "waveform.path"
            case .time:   return "clock"
            }
        }
        var color: Color {
            switch self {
            case .gps:    return .green
            case .motion: return .blue
            case .time:   return Color(.tertiaryLabel)
            }
        }
    }

    @Published private(set) var stationIndex: Int = 0
    @Published private(set) var source: PositionSource = .time

    // Internal segment reference (held weakly via value copy)
    private var segStations: [String] = []

    // GPS
    private let locationManager = CLLocationManager()
    private var gpsConfirmedIdx: Int? = nil

    // Accelerometer
    private let motionManager = CMMotionManager()
    private var motionStops: Int = 0
    private var lowMotionSince: Date? = nil
    private var wasMoving: Bool = true

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 40
    }

    // MARK: - Lifecycle

    func start(seg: JourneySegment) {
        stop()
        segStations = seg.stations
        stationIndex = 0
        source = .time
        gpsConfirmedIdx = nil
        motionStops = 0
        lowMotionSince = nil
        wasMoving = true
        startGPS()
        startMotion()
    }

    func stop() {
        locationManager.stopUpdatingLocation()
        motionManager.stopDeviceMotionUpdates()
        segStations = []
    }

    /// Called by the time loop so the time component advances the index when
    /// GPS and motion haven't fired yet.
    func integrate(timeBasedIdx: Int) {
        let gps = gpsConfirmedIdx
        let motion = motionStops

        let best: Int
        let newSource: PositionSource
        if let g = gps, g >= motion, g >= timeBasedIdx {
            best = g;  newSource = .gps
        } else if motion >= timeBasedIdx {
            best = motion; newSource = .motion
        } else {
            best = timeBasedIdx; newSource = .time
        }

        let clamped = min(best, max(segStations.count - 1, 0))
        if clamped > stationIndex { stationIndex = clamped }
        source = newSource
    }

    /// Manual position correction — overrides all sensors.
    func forceIndex(_ idx: Int) {
        stationIndex = idx
        motionStops = idx
        gpsConfirmedIdx = nil
    }

    // MARK: - GPS

    private func startGPS() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }

    private func matchGPS(coord: CLLocationCoordinate2D) {
        guard !segStations.isEmpty else { return }
        guard let match = MetroLineData.nearestStation(
            latitude: coord.latitude,
            longitude: coord.longitude,
            maxMeters: 300
        ) else { return }  // underground or out of range

        if let idx = segStations.firstIndex(of: match.name), idx >= stationIndex {
            gpsConfirmedIdx = idx
        }
    }

    // MARK: - Accelerometer

    private func startMotion() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.2   // 5 Hz
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.processMotion(data)
        }
    }

    private func processMotion(_ data: CMDeviceMotion) {
        let a = data.userAcceleration
        let mag = sqrt(a.x*a.x + a.y*a.y + a.z*a.z)

        // Subway vibration when moving ≈ 0.05-0.2g; stopped < 0.04g.
        // minStopDuration guards against false positives when user stands still.
        let stopThreshold: Double = 0.04
        let moveThreshold: Double = 0.07
        let minStopDuration: TimeInterval = 20

        if mag < stopThreshold {
            if lowMotionSince == nil, wasMoving {
                lowMotionSince = Date()
            }
            if let since = lowMotionSince,
               Date().timeIntervalSince(since) >= minStopDuration {
                motionStops += 1
                lowMotionSince = nil
                wasMoving = false
            }
        } else if mag > moveThreshold {
            lowMotionSince = nil
            wasMoving = true
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension TransitPositionTracker: CLLocationManagerDelegate {
    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.last?.coordinate else { return }
        Task { @MainActor in self.matchGPS(coord: coord) }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {}

    nonisolated func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        Task { @MainActor in
            switch m.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                if !self.segStations.isEmpty { m.startUpdatingLocation() }
            default: break
            }
        }
    }
}
