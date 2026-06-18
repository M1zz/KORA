import Foundation
import Speech
import AVFoundation

// MARK: - Station Announcement Listener
//
// The single most authoritative position signal underground is the train's own
// voice: Seoul Metro announces every stop as
//
//     "이번 역은 강남, 강남역입니다. 내리실 문은 오른쪽입니다."
//     "다음 역은 역삼, 역삼역입니다."
//
// This listener runs Korean **on-device** speech recognition on the microphone
// and extracts:
//   • the current station   ("이번 역은 ○○")  → confirm position (ground truth)
//   • the next station       ("다음 역은 ○○")  → pre-arm the upcoming arrival
//   • the door side          ("내리실 문은 오른쪽/왼쪽")
//
// On-device recognition means audio never leaves the phone. It only runs while
// riding and only after the rider grants mic + speech permission.
@MainActor
final class StationAnnouncementListener: NSObject, ObservableObject {

    enum DoorSide { case left, right }

    /// Last station name (bare Korean, e.g. "강남") confirmed via "이번 역은".
    @Published private(set) var lastHeardStation: String?
    /// Door side from the most recent "내리실 문은 …" announcement.
    @Published private(set) var doorSide: DoorSide?
    @Published private(set) var isListening = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ko_KR"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    /// Bare station names (no trailing "역") for the active segment.
    private var candidates: [String] = []
    /// (station, isCurrent) → forwarded to the tracker. isCurrent=false means
    /// the announcement referred to the *next* station ("다음 역은 …").
    private var onConfirm: ((String, Bool) -> Void)?
    private var lastConfirmed: (station: String, isCurrent: Bool)?

    // MARK: - Authorization

    /// Requests Speech + microphone permission. Returns true only if both granted.
    func requestAuthorization() async -> Bool {
        let speech: SFSpeechRecognizerAuthorizationStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard speech == .authorized else { return false }
        return await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { cont.resume(returning: $0) }
        }
    }

    // MARK: - Lifecycle

    func start(candidates: [String], onConfirm: @escaping (String, Bool) -> Void) {
        stop()
        self.candidates = candidates.map { $0.hasSuffix("역") ? String($0.dropLast()) : $0 }
        self.onConfirm = onConfirm
        self.lastConfirmed = nil
        guard recognizer?.isAvailable == true, recognizer?.supportsOnDeviceRecognition == true else { return }
        do {
            try configureSession()
            try startEngine()
            isListening = true
            beginRecognition()
        } catch {
            isListening = false
        }
    }

    /// Update the candidate list as the journey advances (e.g. on transfer).
    func updateCandidates(_ c: [String]) {
        candidates = c.map { $0.hasSuffix("역") ? String($0.dropLast()) : $0 }
    }

    func stop() {
        isListening = false
        task?.cancel(); task = nil
        request?.endAudio(); request = nil
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Audio

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        // .mixWithOthers so the rider's music/podcast keeps playing while we listen.
        try session.setCategory(.record, mode: .measurement, options: [.mixWithOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private func startEngine() throws {
        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
    }

    // MARK: - Recognition

    private func beginRecognition() {
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = true
        if #available(iOS 17.0, *) { req.addsPunctuation = false }
        request = req

        task = recognizer?.recognitionTask(with: req) { [weak self] result, error in
            // Cross the actor boundary with Sendable values only.
            let text = result?.bestTranscription.formattedString
            let isFinal = result?.isFinal ?? false
            let failed = error != nil
            Task { @MainActor [weak self] in
                if let text { self?.handle(text: text) }
                if isFinal || failed { self?.restartRecognition() }
            }
        }
    }

    /// On-device tasks still end on long silence / finalization. Keep the audio
    /// engine running and just spin up a fresh request so listening is continuous.
    private func restartRecognition() {
        task?.cancel(); task = nil
        request?.endAudio(); request = nil
        guard isListening else { return }
        beginRecognition()
    }

    // MARK: - Parsing

    private func handle(text: String) {
        let t = text.replacingOccurrences(of: " ", with: "")

        // Door side — both "내리실 문은 오른쪽" and the trailing "오른쪽입니다" form.
        if t.contains("오른쪽") { doorSide = .right }
        else if t.contains("왼쪽") { doorSide = .left }

        detectStation(in: t)
    }

    /// Find the station named right after the most recent "이번역"/"다음역" cue.
    private func detectStation(in t: String) {
        for (keyword, isCurrent) in [("이번역", true), ("다음역", false)] {
            guard let r = t.range(of: keyword, options: .backwards) else { continue }
            let window = String(t[r.upperBound...].prefix(8))   // "은강남역입니다…"
            // Prefer the longest candidate so "양재시민의숲" wins over "양재".
            if let station = candidates
                .filter({ window.contains($0) })
                .max(by: { $0.count < $1.count }) {
                confirm(station: station, isCurrent: isCurrent)
                return
            }
        }
    }

    private func confirm(station: String, isCurrent: Bool) {
        // Debounce: the same phrase streams in repeatedly as partial results.
        if let last = lastConfirmed, last.station == station, last.isCurrent == isCurrent { return }
        lastConfirmed = (station, isCurrent)
        if isCurrent { lastHeardStation = station }
        onConfirm?(station, isCurrent)
    }
}
