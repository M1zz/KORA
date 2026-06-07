import CoreLocation
import CoreMotion
import SwiftUI

// MARK: - Transit Position Tracker

/// Estimates current station index using two layered sources:
///   1. GPS     — matches nearest station within 300 m (best; fails underground)
///   2. Motion  — state machine on horizontal RMS acceleration (works underground)
///
/// The accelerometer path uses a proper two-state machine:
///   STATIONARY → (rms > moveThreshold, after ≥15 s dwell) → MOVING
///   MOVING     → (rms < stopThreshold, sustained ≥5 s)      → STATIONARY + increment stop count
///
/// This makes station counting event-driven (arrival events) rather than duration-
/// based, so the index advances exactly when the train doors open — not N seconds later.
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

    private var segStations: [String] = []

    // GPS
    private let locationManager = CLLocationManager()
    private var gpsConfirmedIdx: Int? = nil

    // Accelerometer state machine
    private let motionManager = CMMotionManager()

    private enum MotionState {
        case stationary   // at platform — waiting for departure
        case moving       // between stations — waiting for arrival
    }

    private var motionState: MotionState = .stationary
    private var stateEnteredAt: Date = Date(timeIntervalSinceNow: -dwellMinDuration)
    private var lowRmsSince: Date? = nil
    private var rmsBuffer: [Double] = []
    private var motionStopCount: Int = 0

    // ── Tuning constants ──────────────────────────────────────────────────────
    // 25 Hz — enough for smooth RMS without draining the battery too fast
    private static let sampleInterval: TimeInterval = 0.04

    // 1.5 s RMS window → ~38 samples. Smooths out brief bumps / door-close jolts
    // while still being responsive to the sustained ~3-second departure ramp.
    private static let bufferSize: Int = 38

    // Seoul subway moving vibration ≈ 0.05–0.25 g; stationary < 0.03 g.
    // Use asymmetric thresholds (hysteresis) to avoid chattering at the boundary.
    private static let moveRmsThreshold: Double = 0.055   // g  → enter MOVING
    private static let stopRmsThreshold: Double = 0.028   // g  → enter STATIONARY

    // Must be in STATIONARY for this long before a new departure is counted.
    // Seoul platform dwell ≈ 20–40 s; 15 s is a safe lower bound that still
    // blocks the door-close vibration spike (~1–2 s) from triggering departure.
    private static let dwellMinDuration: TimeInterval = 15

    // RMS must stay below stopRmsThreshold for this long before we count an arrival.
    // Filters smooth cruise sections where the train briefly vibrates less.
    private static let stoppedConfirmDuration: TimeInterval = 5

    // ─────────────────────────────────────────────────────────────────────────

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
        motionStopCount = 0
        rmsBuffer = []
        motionState = .stationary
        // Pre-satisfy the dwell so the very first departure is detectable immediately.
        stateEnteredAt = Date(timeIntervalSinceNow: -Self.dwellMinDuration)
        lowRmsSince = nil
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
        let motion = motionStopCount

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
        motionStopCount = idx
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
        ) else { return }

        if let idx = segStations.firstIndex(of: match.name), idx >= stationIndex {
            gpsConfirmedIdx = idx
        }
    }

    // MARK: - Accelerometer

    private func startMotion() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = Self.sampleInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.processMotion(data)
        }
    }

    private func processMotion(_ data: CMDeviceMotion) {
        // ── 1. Project userAcceleration onto the horizontal plane ─────────────
        // userAcceleration is already gravity-free. We further remove any
        // component along the gravity axis so that vertical jolts (bumps,
        // going up/down ramps) don't pollute the lateral/longitudinal signal
        // that actually reflects train motion — regardless of phone orientation.
        let g = data.gravity
        let a = data.userAcceleration

        let gMag = sqrt(g.x*g.x + g.y*g.y + g.z*g.z)
        guard gMag > 0.001 else { return }
        let gx = g.x / gMag, gy = g.y / gMag, gz = g.z / gMag

        let vertComp = a.x * gx + a.y * gy + a.z * gz
        let hx = a.x - vertComp * gx
        let hy = a.y - vertComp * gy
        let hz = a.z - vertComp * gz
        let horizMag = sqrt(hx*hx + hy*hy + hz*hz)

        // ── 2. Sliding RMS window ─────────────────────────────────────────────
        rmsBuffer.append(horizMag)
        if rmsBuffer.count > Self.bufferSize { rmsBuffer.removeFirst() }
        guard rmsBuffer.count >= 10 else { return }   // need ≥0.4 s of data

        let rms = sqrt(rmsBuffer.map { $0 * $0 }.reduce(0, +) / Double(rmsBuffer.count))
        let now = Date()

        // ── 3. State machine ──────────────────────────────────────────────────
        switch motionState {

        case .stationary:
            // Require the train to have dwelled for dwellMinDuration before
            // registering a departure. This blocks door-close vibration spikes.
            let dwelled = now.timeIntervalSince(stateEnteredAt) >= Self.dwellMinDuration
            if dwelled && rms > Self.moveRmsThreshold {
                motionState = .moving
                stateEnteredAt = now
                lowRmsSince = nil
            }

        case .moving:
            if rms < Self.stopRmsThreshold {
                if lowRmsSince == nil { lowRmsSince = now }

                // Confirm arrival only after sustained stillness
                if let since = lowRmsSince,
                   now.timeIntervalSince(since) >= Self.stoppedConfirmDuration {
                    motionStopCount += 1
                    motionState = .stationary
                    stateEnteredAt = now
                    lowRmsSince = nil
                }
            } else {
                // Any movement above the move threshold resets the stop timer.
                // This prevents a smooth cruise section from being misread as arrival.
                if rms > Self.moveRmsThreshold {
                    lowRmsSince = nil
                }
            }
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
