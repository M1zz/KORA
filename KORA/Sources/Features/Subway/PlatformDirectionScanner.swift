import SwiftUI
import AVFoundation
import Vision

// MARK: - Platform Direction Scanner
//
// At a station the rider faces two platforms/trains signed with different
// destinations — e.g. at 서울역 (Line 4): "진접·충무로" one way, "사당·오이도"
// the other. This view points the camera at a destination sign and tells the
// rider whether THAT sign is their direction, by reading it with on-device
// Vision OCR (Korean) and matching against the route's forward/backward markers.

// MARK: - Inline scanner (embedded live "window")
//
// A live camera pane embedded directly in the ride block — the rider just holds
// the phone up to the train's destination display and the pane borders GREEN
// (board) or RED (wrong train). No sheet to open.
struct InlineDirectionScanner: View {
    let forwardMarkers: Set<String>
    let backwardMarkers: Set<String>
    let displayLanguage: StationLanguage

    @StateObject private var cam = DirectionCameraModel()

    private var borderColor: Color {
        switch cam.verdict {
        case .correct: return .green
        case .wrong:   return .red
        default:       return .white.opacity(0.3)
        }
    }

    var body: some View {
        ZStack {
            CameraPreview(session: cam.session)
            Color.black.opacity(0.001)   // keep the layer alive even before frames

            // Full-pane verdict: the recognized destination (the *reason*) fills
            // the view huge, with the short verdict beneath it.
            switch cam.verdict {
            case .denied:
                fullVerdict(station: nil, verdict: NavLoc.scanNoCamera.resolved(displayLanguage), color: .orange, icon: "video.slash.fill")
            case .correct:
                fullVerdict(station: cam.matchedText, verdict: NavLoc.scanCorrect.resolved(displayLanguage), color: .green, icon: "checkmark.circle.fill")
            case .wrong:
                fullVerdict(station: cam.matchedText, verdict: NavLoc.scanWrong.resolved(displayLanguage), color: .red, icon: "xmark.octagon.fill")
            default:
                VStack {
                    Spacer()
                    Text(NavLoc.scanAimPrompt.resolved(displayLanguage))
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(.black.opacity(0.4), in: Capsule())
                        .padding(12)
                }
            }
        }
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(borderColor, lineWidth: 6)
                .animation(.easeOut(duration: 0.2), value: cam.verdict)
        )
        .task {
            cam.configure(forward: forwardMarkers, backward: backwardMarkers)
            await cam.start()
        }
        .onDisappear { cam.stop() }
    }

    private func fullVerdict(station: String?, verdict: String, color: Color, icon: String) -> some View {
        ZStack {
            color.opacity(0.4)
            VStack(spacing: 4) {
                if let station, !station.isEmpty {
                    Image(systemName: icon)
                        .font(.system(size: 30, weight: .black))
                    Text(station)                       // the reason — fills the pane
                        .font(.system(size: 72, weight: .black))
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)
                    Text(verdict)
                        .font(.headline).fontWeight(.bold)
                } else {
                    Image(systemName: icon).font(.system(size: 34, weight: .black))
                    Text(verdict).font(.title3).fontWeight(.heavy)
                        .multilineTextAlignment(.center)
                }
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.5), radius: 4, y: 1)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct PlatformDirectionScanner: View {
    let forwardMarkers: Set<String>     // station/terminus names in the rider's direction
    let backwardMarkers: Set<String>    // names in the opposite direction
    let towardLabel: String             // human label, e.g. "당고개 방면"
    let lineColor: Color
    let displayLanguage: StationLanguage

    @Environment(\.dismiss) private var dismiss
    @StateObject private var cam = DirectionCameraModel()

    var body: some View {
        ZStack {
            CameraPreview(session: cam.session)
                .ignoresSafeArea()

            // Dim for legibility of the overlay text.
            LinearGradient(colors: [.black.opacity(0.55), .clear, .black.opacity(0.7)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Full-screen verdict border — GREEN = right direction, RED = wrong.
            if let c = borderColor {
                Rectangle()
                    .strokeBorder(c, lineWidth: 16)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .shadow(color: c.opacity(0.7), radius: 12)
                    .transition(.opacity)
            }

            VStack(spacing: 0) {
                header
                Spacer()
                verdictCard
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
        }
        .animation(.easeOut(duration: 0.2), value: cam.verdict)
        .task {
            cam.configure(forward: forwardMarkers, backward: backwardMarkers)
            await cam.start()
        }
        .onDisappear { cam.stop() }
    }

    /// Border tint for the current verdict (nil = no border while searching).
    private var borderColor: Color? {
        switch cam.verdict {
        case .correct: return .green
        case .wrong:   return .red
        default:       return nil
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(NavLoc.scanAimPrompt.resolved(displayLanguage))
                    .font(.callout).fontWeight(.semibold)
                    .foregroundStyle(.white.opacity(0.9))
                Text(towardLabel)
                    .font(.title3).fontWeight(.black)
                    .foregroundStyle(.white)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.85))
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    @ViewBuilder private var verdictCard: some View {
        switch cam.verdict {
        case .correct:
            verdictBox(icon: "checkmark.circle.fill",
                       title: NavLoc.scanCorrect.resolved(displayLanguage),
                       detail: cam.matchedText,
                       color: .green)
        case .wrong:
            verdictBox(icon: "xmark.octagon.fill",
                       title: NavLoc.scanWrong.resolved(displayLanguage),
                       detail: cam.matchedText,
                       color: .red)
        case .searching, .ambiguous:
            verdictBox(icon: "viewfinder",
                       title: NavLoc.scanSearching.resolved(displayLanguage),
                       detail: nil,
                       color: .white.opacity(0.85))
        case .denied:
            verdictBox(icon: "video.slash.fill",
                       title: NavLoc.scanNoCamera.resolved(displayLanguage),
                       detail: nil,
                       color: .orange)
        }
    }

    private func verdictBox(icon: String, title: String, detail: String?, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 38, weight: .black))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title2).fontWeight(.black)
                    .foregroundStyle(.white)
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.callout).fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .background(color.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(color.opacity(0.6), lineWidth: 2))
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: cam.verdict)
    }
}

// MARK: - Camera + OCR model

// @unchecked Sendable: @Published state is only mutated on the main thread; the
// capture session/output are confined to `videoQueue`. We manage that manually.
final class DirectionCameraModel: ObservableObject, @unchecked Sendable {

    enum Verdict { case searching, correct, wrong, ambiguous, denied }

    @Published private(set) var verdict: Verdict = .searching
    @Published private(set) var matchedText: String?

    let session = AVCaptureSession()
    private let videoQueue = DispatchQueue(label: "kora.direction.scanner")
    private let output = AVCaptureVideoDataOutput()
    private let delegate = SampleHandler()

    private var forward: Set<String> = []
    private var backward: Set<String> = []
    private var missStreak = 0   // consecutive frames with no matching destination

    func configure(forward: Set<String>, backward: Set<String>) {
        self.forward = Set(forward.map(Self.normalize))
        self.backward = Set(backward.map(Self.normalize))
        delegate.onText = { [weak self] lines in
            self?.evaluate(lines)
        }
    }

    @MainActor
    func start() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        guard granted else { verdict = .denied; return }
        videoQueue.async { [weak self] in
            self?.setupSession()
        }
    }

    func stop() {
        videoQueue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    /// Runs on `videoQueue`.
    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(delegate, queue: videoQueue)
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        session.startRunning()
    }

    /// Called on `videoQueue` from the OCR delegate; publishes on the main thread.
    private func evaluate(_ lines: [String]) {
        let norm = Self.normalize(lines.joined(separator: " "))
        // The actual station name (from our marker sets) that was read — this is
        // what drove the verdict, shown to the rider so green/red isn't a mystery.
        let fwdHit = forward.first { !$0.isEmpty && norm.contains($0) }
        let bwdHit = backward.first { !$0.isEmpty && norm.contains($0) }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            // A valid destination wins: if any forward terminus/station is on the
            // display, it's the right train → GREEN (even if other text is present).
            // Only when there's NO valid destination but a "don't board" one is → RED.
            if let f = fwdHit {
                self.missStreak = 0
                self.verdict = .correct; self.matchedText = f
            } else if let b = bwdHit {
                self.missStreak = 0
                self.verdict = .wrong; self.matchedText = b
            } else {
                // No destination read. Hold briefly to avoid flicker, then go neutral
                // so a stale verdict can't linger when nothing is in frame.
                self.missStreak += 1
                if self.missStreak >= 3 {
                    self.verdict = .searching
                    self.matchedText = nil
                }
            }
        }
    }

    static func normalize(_ s: String) -> String {
        var t = s.replacingOccurrences(of: " ", with: "")
        for suffix in ["방면", "방향", "행", "역", "방", "·", "・", ",", "/"] {
            t = t.replacingOccurrences(of: suffix, with: "")
        }
        return t
    }
}

// MARK: - Sample buffer → Vision OCR

private final class SampleHandler: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onText: (([String]) -> Void)?
    private var lastRun = Date.distantPast
    private let minInterval: TimeInterval = 0.5   // ~2 fps OCR

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        let now = Date()
        guard now.timeIntervalSince(lastRun) >= minInterval else { return }
        lastRun = now
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNRecognizeTextRequest { [weak self] req, _ in
            let results = req.results as? [VNRecognizedTextObservation] ?? []
            let lines = results.compactMap { $0.topCandidates(1).first?.string }
            // Always report (even empty) so a stale verdict resets when nothing is read.
            self?.onText?(lines)
        }
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.recognitionLanguages = ["ko-KR", "en-US"]

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        try? handler.perform([request])
    }
}

// MARK: - Camera preview

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let v = PreviewView()
        v.videoPreviewLayer.session = session
        v.videoPreviewLayer.videoGravity = .resizeAspectFill
        return v
    }
    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
