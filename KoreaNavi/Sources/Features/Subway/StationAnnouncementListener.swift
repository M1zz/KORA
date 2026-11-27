import OSLog
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
    /// start · stop 마다 하나씩 는다. 세션을 켜는 동안 멈추거나 다시 시작했으면 늦게 끝난 켜기는 버린다.
    private var generation = 0

    /// 오디오 세션 켜고 끄기는 수백 ms 걸릴 수 있어 메인 밖에서, 차례대로 한다.
    nonisolated private static let sessionQueue = DispatchQueue(label: "kora.announcement.session")

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
        self.doorSide = nil   // 앞 열차의 내리실 문이 새 열차에 남지 않게
        guard KoreaNaviFlag.announcementListening.isEnabled else {
            KoreaNaviLog.announcement.notice("안내방송 인식이 원격으로 꺼져 있어 듣지 않습니다")
            return
        }
        guard recognizer?.isAvailable == true, recognizer?.supportsOnDeviceRecognition == true else { return }
        let started = generation
        Task {
            do {
                try await Self.activateSession()
                guard generation == started else { return }   // 켜는 사이 멈췄거나 다시 시작했다
                try startEngine()
                isListening = true
                beginRecognition()
            } catch {
                KoreaNaviLog.announcement.error("안내방송 듣기 시작 실패: \(error.localizedDescription, privacy: .public)")
                isListening = false
            }
        }
    }

    /// Update the candidate list as the journey advances (e.g. on transfer).
    func updateCandidates(_ c: [String]) {
        candidates = c.map { $0.hasSuffix("역") ? String($0.dropLast()) : $0 }
    }

    func stop() {
        generation += 1
        isListening = false
        task?.cancel(); task = nil
        request?.endAudio(); request = nil
        // 전화 · Siri · 이어폰 바꿈으로 엔진이 저절로 꺼졌어도 탭은 버스에 남는다.
        // 남은 탭 위에 다시 걸면 예외로 죽으므로, 엔진이 도는지와 상관없이 뗀다(없는 탭을 떼는 건 괜찮다).
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        Self.sessionQueue.async {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    // MARK: - Audio

    /// 세션 큐에서 켠다. 앞서 보낸 끄기가 먼저 끝난 뒤에 켜진다(같은 큐, 차례대로).
    nonisolated private static func activateSession() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            sessionQueue.async {
                do {
                    let session = AVAudioSession.sharedInstance()
                    // .mixWithOthers so the rider's music/podcast keeps playing while we listen.
                    try session.setCategory(.record, mode: .measurement, options: [.mixWithOthers])
                    // 녹음 세션은 기본으로 진동을 막는다. 풀지 않으면 듣는 동안 하차 진동이 울리지 않는다.
                    try session.setAllowHapticsAndSystemSoundsDuringRecording(true)
                    try session.setActive(true, options: .notifyOthersOnDeactivation)
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
        }
    }

    private func startEngine() throws {
        let input = audioEngine.inputNode
        // 세션을 막 바꾼 뒤의 outputFormat 은 하드웨어와 어긋날 수 있고, 그 형식으로 탭을 걸면
        // AVAudioEngine 이 ObjC 예외를 던져 앱이 죽는다(초견 1.0.6 에서 난 것과 같은 자리).
        // 하드웨어 형식만 확인하고, 탭 형식은 버스에 맡긴다(nil).
        let hardware = input.inputFormat(forBus: 0)
        guard hardware.sampleRate > 0, hardware.channelCount > 0 else { throw CocoaError(.featureUnsupported) }
        input.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, _ in
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

        detectStation(in: t)

        // Door side — both "내리실 문은 오른쪽" and the trailing "오른쪽입니다" form.
        // 인식 글은 여러 역의 방송이 이어 붙는다. 마지막 "이번역" 뒤에서, 더 뒤에 나온 쪽을 따른다.
        let scope = t.range(of: "이번역", options: .backwards).map { t[$0.upperBound...] } ?? t[...]
        let right = scope.range(of: "오른쪽", options: .backwards)?.lowerBound
        let left = scope.range(of: "왼쪽", options: .backwards)?.lowerBound
        switch (right, left) {
        case let (r?, l?): doorSide = r > l ? .right : .left
        case (_?, nil): doorSide = .right
        case (nil, _?): doorSide = .left
        case (nil, nil): break
        }
    }

    /// Find the station named right after the most recent "이번역"/"다음역" cue.
    private func detectStation(in t: String) {
        for (keyword, isCurrent) in [("이번역", true), ("다음역", false)] {
            guard let r = t.range(of: keyword, options: .backwards) else { continue }
            // "은강남역입니다…" 가장 긴 역 이름("동대문역사문화공원")까지 들어오는 길이로 본다.
            let longest = candidates.map(\.count).max() ?? 0
            let window = String(t[r.upperBound...].prefix(max(8, longest + 2)))
            // Prefer the longest candidate so "양재시민의숲" wins over "양재".
            if let station = candidates
                .filter({ window.contains($0) })
                .max(by: { $0.count < $1.count }),
               let found = window.range(of: station) {
                // 부분 결과는 "잠실"이 "잠실새내"보다 먼저 온다. 뒤 글자가 더 긴 이름과 갈릴 때까지 기다린다.
                let rest = window[found.upperBound...]
                let stillAmbiguous = candidates.contains {
                    $0.count > station.count && $0.hasPrefix(station) && $0.dropFirst(station.count).hasPrefix(rest)
                }
                if stillAmbiguous { return }
                confirm(station: station, isCurrent: isCurrent)
                return
            }
        }
    }

    private func confirm(station: String, isCurrent: Bool) {
        // Debounce: the same phrase streams in repeatedly as partial results.
        if let last = lastConfirmed, last.station == station, last.isCurrent == isCurrent { return }
        lastConfirmed = (station, isCurrent)
        if isCurrent {
            if lastHeardStation != station { doorSide = nil }   // 새 역이면 앞 역의 내리실 문을 지운다
            lastHeardStation = station
        }
        onConfirm?(station, isCurrent)
    }
}
