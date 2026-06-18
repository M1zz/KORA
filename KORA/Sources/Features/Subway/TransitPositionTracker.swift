import CoreLocation
import CoreMotion
import SwiftUI

// MARK: - Transit Position Tracker

/// Estimates the current station index while riding, fusing four layered sources
/// in priority order so departure/stop events stay tightly in sync with reality:
///
///   1. Realtime — Seoul Open API arrival feed. Authoritative ground truth for
///                 when a train departs/arrives. Acts as a *gate* that bounds the
///                 other estimators so they can never drift far ahead of the
///                 actual train. Off automatically when no API key is configured.
///   2. GPS      — matches nearest station within 300 m (best above ground; fails
///                 underground; ignored once its fix goes stale).
///   3. Motion   — accelerometer state machine on horizontal RMS (works underground).
///   4. Time     — schedule-derived floor; always available.
///
/// The accelerometer path uses a two-state machine:
///   STATIONARY → (rms > moveThreshold, after ≥15 s dwell) → MOVING
///   MOVING     → (rms < stopThreshold, sustained ≥5 s)     → STATIONARY + stop++
///
/// Safety mechanisms layered on top of the fusion:
///   • Monotonic — the reported index never moves backward.
///   • Destination clamp — never advances past the last station of the segment.
///   • Motion plausibility cap — accelerometer count can lead the schedule by at
///     most `maxMotionLead` stops, so phantom jolts can't race the index ahead.
///   • GPS staleness — a fix older than `gpsStaleSeconds` stops being the active
///     source (but its last confirmed index is still honoured as a floor).
///   • Realtime gate — when realtime is fresh, the index is capped at
///     `realtimeConfirmedIdx + 1`, preventing time/motion from overshooting a
///     delayed train.
///   • Confidence — exposes how trustworthy the current estimate is so the UI can
///     ask the rider to confirm position when sources disagree.
@MainActor
final class TransitPositionTracker: NSObject, ObservableObject {

    enum PositionSource {
        case announcement, realtime, gps, motion, time

        var icon: String {
            switch self {
            case .announcement: return "waveform.and.mic"
            case .realtime:     return "dot.radiowaves.up.forward"
            case .gps:          return "location.fill"
            case .motion:       return "waveform.path"
            case .time:         return "clock"
            }
        }
        var color: Color {
            switch self {
            case .announcement: return .pink
            case .realtime:     return .purple
            case .gps:          return .green
            case .motion:       return .blue
            case .time:         return Color(.tertiaryLabel)
            }
        }
    }

    /// How much we trust the current index. Drives the "confirm your position" UI.
    enum Confidence {
        case high     // realtime active, or ≥2 independent sources agree
        case medium   // a single non-time source is driving
        case low      // only the time estimate, or sources disagree

        var isReliable: Bool { self != .low }
    }

    @Published private(set) var stationIndex: Int = 0
    @Published private(set) var source: PositionSource = .time
    @Published private(set) var confidence: Confidence = .medium
    /// Becomes true once the train is confirmed to have left the boarding station.
    @Published private(set) var hasDeparted: Bool = false
    /// True while realtime says our train is arriving/entering the next station.
    @Published private(set) var arrivingAtNext: Bool = false

    private var segStations: [String] = []
    private var lineNumber: Int = 0
    private var terminus: String = ""

    // GPS
    private let locationManager = CLLocationManager()
    private var gpsConfirmedIdx: Int? = nil
    private var lastGPSFix: Date? = nil

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

    // Realtime
    private var realtimeConfirmedIdx: Int = 0
    private var realtimeLastConfirm: Date? = nil
    private var lockedTrainNumber: String? = nil
    private var realtimeTask: Task<Void, Never>? = nil
    private var lastTimeIdx: Int = 0

    // Announcement (heard via the train's PA — highest authority)
    private var announcedConfirmedIdx: Int = 0

    // ── Tuning constants ──────────────────────────────────────────────────────
    private static let sampleInterval: TimeInterval = 0.04   // 25 Hz
    private static let bufferSize: Int = 38                   // ~1.5 s RMS window
    private static let moveRmsThreshold: Double = 0.055       // g → enter MOVING
    private static let stopRmsThreshold: Double = 0.028       // g → enter STATIONARY
    private static let dwellMinDuration: TimeInterval = 15    // min platform dwell
    private static let stoppedConfirmDuration: TimeInterval = 5

    // Safety constants
    /// Accelerometer index may lead the schedule estimate by at most this many
    /// stops. Blocks runaway over-counting from repeated jolts/bumps.
    private static let maxMotionLead: Int = 2
    /// A GPS fix older than this is ignored as the active source (underground).
    private static let gpsStaleSeconds: TimeInterval = 90
    /// Realtime confirmations older than this are considered inactive — the gate
    /// lifts and we fall back to GPS/motion/time.
    private static let realtimeFreshSeconds: TimeInterval = 150
    /// Realtime polling cadence.
    private static let realtimePollSeconds: UInt64 = 20

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
        lineNumber = seg.line.number
        terminus = seg.terminus
        stationIndex = 0
        source = .time
        confidence = .medium
        hasDeparted = false
        arrivingAtNext = false
        gpsConfirmedIdx = nil
        lastGPSFix = nil
        motionStopCount = 0
        rmsBuffer = []
        motionState = .stationary
        // Pre-satisfy the dwell so the very first departure is detectable immediately.
        stateEnteredAt = Date(timeIntervalSinceNow: -Self.dwellMinDuration)
        lowRmsSince = nil
        realtimeConfirmedIdx = 0
        realtimeLastConfirm = nil
        lockedTrainNumber = nil
        lastTimeIdx = 0
        announcedConfirmedIdx = 0
        startGPS()
        startMotion()
        startRealtime()
    }

    func stop() {
        locationManager.stopUpdatingLocation()
        motionManager.stopDeviceMotionUpdates()
        realtimeTask?.cancel()
        realtimeTask = nil
        segStations = []
    }

    /// Called periodically by the time loop to feed the schedule-based floor.
    /// The actual index publish is event-driven (see `publishFusedIndex`), so a
    /// stop detected by motion/realtime/GPS surfaces immediately — not on the
    /// next loop tick.
    func integrate(timeBasedIdx: Int) {
        lastTimeIdx = max(lastTimeIdx, timeBasedIdx)
        publishFusedIndex()
    }

    /// Fuses all four sources and publishes `stationIndex`. Called both on the
    /// periodic time tick and the instant a sensor/realtime event fires.
    private func publishFusedIndex() {
        guard !segStations.isEmpty else { return }
        let lastIdx = max(segStations.count - 1, 0)
        let timeIdx = lastTimeIdx
        let realtimeActive = isRealtimeFresh
        let gpsFresh = isGPSFresh

        // Physical sensors (motion, GPS) are allowed to advance the index freely
        // the moment they detect a stop. Only the *schedule estimate* is gated by
        // realtime, so a delayed train can't be over-counted by the clock — yet a
        // real, sensed arrival is never held back (no freeze).
        let cappedMotion = min(motionStopCount, timeIdx + Self.maxMotionLead)
        let effectiveTime = realtimeActive ? min(timeIdx, realtimeConfirmedIdx + 1) : timeIdx

        // Priority: announcement ≥ realtime ≥ GPS ≥ motion ≥ time (ties go to the
        // higher-authority source). The PA announcement is the train's own voice,
        // so it outranks everything.
        var best = effectiveTime
        var chosen: PositionSource = .time
        if motionStopCount > 0, cappedMotion >= best { best = cappedMotion; chosen = .motion }
        if gpsFresh, let g = gpsConfirmedIdx, g >= best { best = g; chosen = .gps }
        if realtimeConfirmedIdx > 0, realtimeConfirmedIdx >= best { best = realtimeConfirmedIdx; chosen = .realtime }
        if announcedConfirmedIdx > 0, announcedConfirmedIdx >= best { best = announcedConfirmedIdx; chosen = .announcement }

        // ── Monotonic + destination clamp.
        let clamped = min(max(best, stationIndex), lastIdx)
        if clamped != stationIndex { stationIndex = clamped }
        source = chosen

        if stationIndex > 0 { hasDeparted = true }
        confidence = evaluateConfidence(timeIdx: timeIdx, cappedMotion: cappedMotion,
                                        gpsFresh: gpsFresh, realtimeActive: realtimeActive)
    }

    /// Manual position correction — overrides all sensors.
    func forceIndex(_ idx: Int) {
        let lastIdx = max(segStations.count - 1, 0)
        let clamped = min(max(idx, 0), lastIdx)
        stationIndex = clamped
        motionStopCount = clamped
        // Reset the time floor too, otherwise a backward correction would be
        // immediately overridden by the stale schedule estimate on the next tick.
        lastTimeIdx = clamped
        gpsConfirmedIdx = nil
        lastGPSFix = nil
        // Reset realtime/announcement baselines around the corrected index.
        realtimeConfirmedIdx = clamped
        announcedConfirmedIdx = clamped
        realtimeLastConfirm = nil
        lockedTrainNumber = nil
        arrivingAtNext = false
        if clamped > 0 { hasDeparted = true }
        confidence = .high   // the rider just told us — trust it for now.
    }

    /// Position confirmed by a heard PA announcement. `isCurrent` true =
    /// "이번 역은 ○○" (we are AT this station); false = "다음 역은 ○○" (next stop).
    func confirmAnnouncedStation(_ name: String, isCurrent: Bool) {
        guard !segStations.isEmpty,
              let idx = segStations.firstIndex(of: name) else { return }
        if isCurrent {
            // Accept only a plausible forward step (≤2 ahead) so a misheard far
            // station can't teleport the index.
            guard idx >= stationIndex, idx <= stationIndex + 2 else { return }
            if idx > announcedConfirmedIdx { announcedConfirmedIdx = idx }
            arrivingAtNext = false
            hasDeparted = idx > 0 || hasDeparted
            publishFusedIndex()
        } else {
            // "다음 역은 ○○" — arm the arrival of the immediately next station.
            if idx == stationIndex + 1 { arrivingAtNext = true }
        }
    }

    // MARK: - Confidence

    private var isGPSFresh: Bool {
        guard let f = lastGPSFix else { return false }
        return Date().timeIntervalSince(f) < Self.gpsStaleSeconds
    }

    private var isRealtimeFresh: Bool {
        guard let c = realtimeLastConfirm else { return false }
        return Date().timeIntervalSince(c) < Self.realtimeFreshSeconds
    }

    private func evaluateConfidence(timeIdx: Int, cappedMotion: Int,
                                    gpsFresh: Bool, realtimeActive: Bool) -> Confidence {
        // The train told us itself — nothing is more trustworthy.
        if announcedConfirmedIdx > 0, announcedConfirmedIdx == stationIndex { return .high }
        if realtimeActive { return .high }

        // Count independent non-time sources that agree (within 1 stop) with the
        // currently reported index.
        var agreeing = 0
        if gpsFresh, let g = gpsConfirmedIdx, abs(g - stationIndex) <= 1 { agreeing += 1 }
        if motionStopCount > 0, abs(cappedMotion - stationIndex) <= 1 { agreeing += 1 }

        if agreeing >= 2 { return .high }
        if agreeing == 1 { return .medium }
        // Only time is driving, or sources diverge → ask the rider to confirm.
        return source == .time ? .low : .medium
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
        lastGPSFix = Date()
        guard let match = MetroLineData.nearestStation(
            latitude: coord.latitude,
            longitude: coord.longitude,
            maxMeters: 300
        ) else { return }

        if let idx = segStations.firstIndex(of: match.name), idx >= stationIndex {
            gpsConfirmedIdx = idx
            publishFusedIndex()
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
            let dwelled = now.timeIntervalSince(stateEnteredAt) >= Self.dwellMinDuration
            if dwelled && rms > Self.moveRmsThreshold {
                motionState = .moving
                stateEnteredAt = now
                lowRmsSince = nil
                hasDeparted = true   // train started moving away from a platform
            }

        case .moving:
            if rms < Self.stopRmsThreshold {
                if lowRmsSince == nil { lowRmsSince = now }
                if let since = lowRmsSince,
                   now.timeIntervalSince(since) >= Self.stoppedConfirmDuration {
                    motionStopCount += 1
                    motionState = .stationary
                    stateEnteredAt = now
                    lowRmsSince = nil
                    // Surface the arrival immediately — don't wait for the loop tick.
                    publishFusedIndex()
                }
            } else if rms > Self.moveRmsThreshold {
                lowRmsSince = nil
            }
        }
    }

    // MARK: - Realtime (Seoul Open API)

    private func startRealtime() {
        guard SeoulTransitConfig.isRealtimeAvailable else { return }
        realtimeTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.pollRealtimeOnce()
                try? await Task.sleep(nanoseconds: Self.realtimePollSeconds * 1_000_000_000)
            }
        }
    }

    private func pollRealtimeOnce() async {
        guard !segStations.isEmpty else { return }
        let idx = stationIndex
        let nextIdx = idx + 1
        guard nextIdx < segStations.count else {
            // Already at/after the destination — nothing left to confirm.
            arrivingAtNext = false
            return
        }
        let nextStation = segStations[nextIdx]

        let confirmation = await RealtimeArrivalService.nextStopConfirmation(
            lineNumber: lineNumber,
            nextStation: nextStation,
            terminus: terminus
        )

        switch confirmation {
        case .arrivedAtNext(let trainNumber):
            // Honour the train lock so we don't latch onto a different train.
            if lockedTrainNumber == nil || trainNumber.isEmpty || lockedTrainNumber == trainNumber {
                if nextIdx > realtimeConfirmedIdx {
                    realtimeConfirmedIdx = nextIdx
                    publishFusedIndex()          // surface the confirmed arrival now
                }
                realtimeLastConfirm = Date()
                lockedTrainNumber = nil          // re-lock for the following hop
                arrivingAtNext = false
                hasDeparted = true
            }

        case .approachingNext(let trainNumber):
            if lockedTrainNumber == nil, !trainNumber.isEmpty { lockedTrainNumber = trainNumber }
            realtimeLastConfirm = Date()         // feed still alive → keep gate active
            arrivingAtNext = true

        case .none:
            arrivingAtNext = false
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
