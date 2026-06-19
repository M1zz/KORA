import SwiftUI
import CoreLocation
import TipKit

// MARK: - Tips

/// Onboarding tip: tells the user they can long-press the station name
/// (or welcome title) to change the display language. Shown until the user
/// performs a long-press for the first time.
struct LanguageLongPressTip: Tip {
    static let didLongPress = Event(id: "language-long-press-discovered")

    let lang: StationLanguage

    var title: Text {
        Text(NavLoc.tipTitle.resolved(lang))
    }

    var message: Text? {
        Text(NavLoc.tipMessage.resolved(lang))
    }

    var image: Image? {
        Image(systemName: "hand.tap.fill")
    }

    var rules: [Rule] {
        [#Rule(Self.didLongPress) { $0.donations.count == 0 }]
    }
}

/// One-time teaching tip explaining what to do with the next-stop card —
/// match the Hangul against the in-train LED display, and reverse direction
/// if it doesn't match.
struct NextStopVerifyTip: Tip {
    static let didBoardOnce = Event(id: "next-stop-verify-taught")

    let lang: StationLanguage

    var title: Text {
        Text(NavLoc.verifyTipTitle.resolved(lang))
    }

    var message: Text? {
        Text(NavLoc.verifyTipMessage.resolved(lang))
    }

    var image: Image? {
        Image(systemName: "tram.fill")
    }

    var rules: [Rule] {
        [#Rule(Self.didBoardOnce) { $0.donations.count == 0 }]
    }
}

// MARK: - Navigator View

struct SubwayNavigatorView: View {
    @AppStorage("kora.current_station") private var persistedFromStation: String = ""
    @AppStorage("kora.destination_station") private var persistedToStation: String = ""
    @State private var fromStation: String? = nil
    @State private var toStation: String? = nil
    @State private var showFromPicker = false
    @State private var showToPicker = false
    @State private var showLanguagePicker = false
    @State private var showDirectionScanner = false
    @State private var selectedJourneyIdx = 0
    /// "" = auto-detect from system locale; otherwise StationLanguage.rawValue
    @AppStorage("kora.display_language") private var languagePref: String = ""
    /// Index of the current "ride block" (= one subway segment). Increments by 1
    /// every time the user confirms they've alighted from a train. When equal to
    /// `journey.segments.count`, the journey is finished.
    @State private var currentBlockIdx: Int = 0

    /// When the user tapped "boarded" for the current segment. While non-nil,
    /// the ride block shows an in-transit view (estimated current station,
    /// stops remaining, ETA). Tapping the action bar again advances to the
    /// next segment.
    @State private var boardedAt: Date? = nil

    /// True while the user is correcting the current-train-position estimate
    /// from the in-transit view.
    @State private var showPositionCorrection = false

    private var displayLanguage: StationLanguage {
        guard !languagePref.isEmpty,
              let explicit = StationLanguage(rawValue: languagePref)
        else { return StationLanguage.resolveFromSystemLocale() }
        return explicit
    }

    // Location detection
    @State private var isLocating = false
    @State private var locationError: String? = nil
    @State private var didAutoLocate = false
    private let locationService = LocationService()

    // Transit position tracker (announcement + realtime + GPS + accelerometer + time)
    @StateObject private var positionTracker = TransitPositionTracker()
    // Listens to the train's PA announcements ("이번 역은 …") for ground-truth position.
    @StateObject private var announcer = StationAnnouncementListener()

    // Cross-tab navigation intent
    @State private var coordinator = NavigationCoordinator.shared
    @State private var placeStore = PlaceStore.shared

    // Offline nearest-exit lookup (bundled SubwayExits.json)
    private let exitService = SubwayExitService.shared
    @State private var destinationCoordinate: Coordinate? = nil
    @State private var destinationPlaceName: String? = nil
    /// Place id of the routing target — used to honour a user-confirmed
    /// `place.exitNo` override that takes priority over the auto lookup.
    @State private var destinationPlaceID: UUID? = nil
    @State private var exitInfo: NearestExit? = nil
    @State private var journeyConfirmed = false
    @State private var inTransitTramY: CGFloat = 0
    @State private var alightShakeCount: Int = 0
    @State private var maxCompletedIdx: Int = -1
    @State private var showRevisitAlert = false
    @State private var revisitFromIdx: Int? = nil
    @State private var terminiOverride: [Int: String] = [:]
    @State private var boardDragOffset: CGFloat = 0
    @State private var boardHapticPhase: Int = 0
    @State private var transferDragOffset: CGFloat = 0
    @State private var transferHapticPhase: Int = 0
    @State private var alightDragOffset: CGFloat = 0
    @State private var alightHapticPhase: Int = 0
    /// Which segment index is currently "boarded" (-1 = none). Separate from
    /// boardedAt so that the old page keeps showing in-transit content while
    /// the new page slides in during the transfer animation.
    @State private var boardedSegmentIdx: Int = -1
    /// Direction of the last page change: true = forward (trailing→leading), false = backward.
    @State private var pageTransitionForward: Bool = true

    private var journeys: [TransferJourney] {
        guard let f = fromStation, let t = toStation else { return [] }
        return MetroLineData.findAnyJourneys(from: f, to: t)
    }
    private var journey: TransferJourney? {
        journeys.indices.contains(selectedJourneyIdx) ? journeys[selectedJourneyIdx] : nil
    }

    var body: some View {
        navigatorBody
        .sheet(isPresented: $showFromPicker) {
            StationSearchSheet(
                title: NavLoc.currentStationTitle.resolved(displayLanguage),
                excluding: toStation,
                displayLanguage: displayLanguage,
                showNearby: true
            ) {
                fromStation = $0
                selectedJourneyIdx = 0
            }
        }
        .sheet(isPresented: $showToPicker) {
            StationSearchSheet(
                title: NavLoc.destinationTitle.resolved(displayLanguage),
                excluding: fromStation,
                displayLanguage: displayLanguage
            ) {
                toStation = $0
                selectedJourneyIdx = 0
            }
        }
        .sheet(isPresented: $showDirectionScanner) {
            if let j = journey, j.segments.indices.contains(currentBlockIdx) {
                let seg = j.segments[currentBlockIdx]
                let markers = directionMarkers(for: seg)
                PlatformDirectionScanner(
                    forwardMarkers: markers.forward,
                    backwardMarkers: markers.backward,
                    towardLabel: towardDirectionLabel(seg.stations.last ?? seg.terminus),
                    lineColor: seg.line.color,
                    displayLanguage: displayLanguage
                )
            }
        }
        .sheet(isPresented: $showLanguagePicker) {
            LanguagePickerSheet(languagePref: $languagePref)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showPositionCorrection) {
            if let j = journey, j.segments.indices.contains(currentBlockIdx) {
                PositionCorrectionSheet(
                    seg: j.segments[currentBlockIdx],
                    displayLanguage: displayLanguage,
                    estimatedStation: estimatedCurrentKo(in: j.segments[currentBlockIdx])
                ) { chosenKo in
                    applyPositionCorrection(to: chosenKo, in: j.segments[currentBlockIdx])
                }
                .presentationDetents([.medium, .large])
            }
        }
        .onAppear {
            consumePendingDestination()
            autoLocateIfNeeded()
        }
        .onChange(of: fromStation) { _, new in
            persistedFromStation = new ?? ""
            // Retry exit lookup once we know the journey is real. The offline
            // service doesn't actually need `fromStation`, but kicking the
            // fetch here is a no-op when nothing's changed and surfaces a
            // result faster on the picker → first journey path.
            if new != nil { fetchExitInfoIfNeeded() }
        }
        .onChange(of: toStation) { _, new in
            persistedToStation = new ?? ""
            exitInfo = nil
            journeyConfirmed = false
            maxCompletedIdx = -1
            revisitFromIdx = nil
            terminiOverride = [:]
            if new != nil { fetchExitInfoIfNeeded() }
        }
        .onChange(of: coordinator.routeRequestNonce) { _, _ in consumePendingDestination() }
        .onChange(of: journey?.id) { _, _ in
            currentBlockIdx = 0
            boardedAt = nil
            boardedSegmentIdx = -1
            journeyConfirmed = false
            maxCompletedIdx = -1
            revisitFromIdx = nil
            terminiOverride = [:]
        }
    }

    private var navigatorBody: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if let j = journey {
                    if journeyConfirmed {
                        activeStepHost(for: j)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        journeyConfirmView(for: j)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal:   .move(edge: .bottom).combined(with: .opacity)
                            ))
                    }
                } else if fromStation != nil && toStation != nil {
                    VStack(spacing: 0) {
                        currentStationHeader
                        noRouteView
                    }
                    .transition(.opacity)
                } else {
                    destinationFocusBody
                        .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: journey == nil)
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: journeyConfirmed)

        }
    }

    // MARK: - Single-block UI (one block per subway ride)

    /// Shows ONLY the current ride block. Past blocks have folded away.
    /// After the last ride is boarded, the arrived block is shown.
    @ViewBuilder
    private func activeStepHost(for j: TransferJourney) -> some View {
        let pageCount = j.segments.count + 1
        let pageFwd = pageTransitionForward
        let pageTransition: AnyTransition = pageFwd
            ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
            : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))

        ZStack(alignment: .top) {
            if currentBlockIdx < j.segments.count {
                rideBlock(seg: j.segments[currentBlockIdx],
                          segIdx: currentBlockIdx,
                          isLast: currentBlockIdx == j.segments.count - 1,
                          j: j)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .id(currentBlockIdx)
                    .transition(pageTransition)
            } else {
                finishedBlock(j: j)
                    .padding(.horizontal, 16)
                    .padding(.top, 22)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .id("finished")
                    .transition(pageTransition)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.9), value: currentBlockIdx)
        .clipped()
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { v in
                    guard abs(v.translation.width) > abs(v.translation.height),
                          v.translation.width > 80 else { return }
                    let prev = currentBlockIdx - 1
                    guard prev >= 0, prev <= maxCompletedIdx else { return }
                    revisitFromIdx = prev
                    showRevisitAlert = true
                }
        )
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                let segIdx = currentBlockIdx
                let isValidSeg = j.segments.indices.contains(segIdx)
                let isLastSeg = segIdx == j.segments.count - 1
                let segBoarded = boardedSegmentIdx == segIdx
                if isValidSeg {
                    if !segBoarded {
                        boardSlider(seg: j.segments[segIdx], j: j)
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .padding(.bottom, 4)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity))
                    } else if !isLastSeg {
                        transferSlider(seg: j.segments[segIdx], j: j)
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .padding(.bottom, 4)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity))
                    } else {
                        alightSlider(seg: j.segments[segIdx], finishedIdx: j.segments.count)
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .padding(.bottom, 4)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity))
                    }
                }
                pageDotsIndicator(count: pageCount, current: currentBlockIdx, journey: j)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .background(.ultraThinMaterial)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: boardedAt != nil)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentBlockIdx)
        }
        .alert(revisitAlertTitle, isPresented: $showRevisitAlert) {
            Button(revisitStayLabel) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if let back = revisitFromIdx {
                    pageTransitionForward = false
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        currentBlockIdx = back
                    }
                }
                revisitFromIdx = nil
            }
            Button(revisitConfirmLabel, role: .cancel) {
                revisitFromIdx = nil
            }
        } message: {
            Text(revisitAlertMessage)
        }
    }

    private func pageDotsIndicator(count: Int, current: Int, journey: TransferJourney) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                let segIdx = min(i, journey.segments.count - 1)
                let segColor = journey.segments[segIdx].line.color
                let isActive = i == current
                // Gradient when entering a new line segment (transfer boundary)
                let isTransfer = isActive && i > 0 && i < journey.segments.count &&
                    journey.segments[i - 1].line.number != journey.segments[i].line.number
                let prevColor = i > 0
                    ? journey.segments[min(i - 1, journey.segments.count - 1)].line.color
                    : segColor

                Capsule()
                    .fill(isTransfer
                        ? AnyShapeStyle(LinearGradient(
                            colors: [prevColor, segColor],
                            startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(isActive
                            ? segColor
                            : (i <= maxCompletedIdx
                                ? segColor.opacity(0.55)
                                : Color.gray.opacity(0.3)))
                    )
                    .frame(width: isActive ? 20 : 8, height: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: current)
            }
        }
    }

    @ViewBuilder
    private func boardSlider(seg: JourneySegment, j: TransferJourney) -> some View {
        let thumbW: CGFloat = 60
        GeometryReader { geo in
            let maxX = max(geo.size.width - thumbW - 8, 1)
            let progress = min(boardDragOffset / maxX, 1.0)
            ZStack(alignment: .leading) {
                Capsule().fill(seg.line.color.opacity(0.13 + 0.12 * progress))
                Text(boardingSwipeHintLabel)
                    .font(.callout).fontWeight(.bold)
                    .foregroundStyle(seg.line.color.opacity(max(0, 1.0 - progress * 2.5)))
                    .frame(maxWidth: .infinity, alignment: .center)
                Capsule()
                    .fill(seg.line.color)
                    .frame(width: thumbW, height: geo.size.height - 10)
                    .overlay(
                        Image(systemName: "chevron.right.2")
                            .font(.callout).fontWeight(.black)
                            .foregroundStyle(.white)
                    )
                    .shadow(color: seg.line.color.opacity(0.4), radius: 6, y: 2)
                    .offset(x: 4 + boardDragOffset)
                    .gesture(
                        DragGesture(minimumDistance: 4)
                            .onChanged { v in
                                let clamped = min(max(0, v.translation.width), maxX)
                                boardDragOffset = clamped
                                let newPhase = Int(clamped / maxX * 4)
                                if newPhase != boardHapticPhase {
                                    boardHapticPhase = newPhase
                                    if newPhase > 0 {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                            }
                            .onEnded { v in
                                boardHapticPhase = 0
                                if boardDragOffset >= maxX * 0.72 {
                                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                    boardCurrentTrain(seg: seg, in: j)
                                    withAnimation(.spring(response: 0.35)) { boardDragOffset = 0 }
                                } else {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        boardDragOffset = 0
                                    }
                                }
                            }
                    )
            }
        }
        .frame(height: 50)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(seg.line.color.opacity(0.35), lineWidth: 1.5))
    }

    @ViewBuilder
    private func transferSlider(seg: JourneySegment, j: TransferJourney) -> some View {
        let thumbW: CGFloat = 60
        GeometryReader { geo in
            let maxX = max(geo.size.width - thumbW - 8, 1)
            let progress = min(transferDragOffset / maxX, 1.0)
            ZStack(alignment: .leading) {
                Capsule().fill(seg.line.color.opacity(0.13 + 0.12 * progress))
                Text(transferSwipeHintLabel)
                    .font(.callout).fontWeight(.bold)
                    .foregroundStyle(seg.line.color.opacity(max(0, 1.0 - progress * 2.5)))
                    .frame(maxWidth: .infinity, alignment: .center)
                Capsule()
                    .fill(seg.line.color)
                    .frame(width: thumbW, height: geo.size.height - 10)
                    .overlay(
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.callout).fontWeight(.black)
                            .foregroundStyle(.white)
                    )
                    .shadow(color: seg.line.color.opacity(0.4), radius: 6, y: 2)
                    .offset(x: 4 + transferDragOffset)
                    .gesture(
                        DragGesture(minimumDistance: 4)
                            .onChanged { v in
                                let clamped = min(max(0, v.translation.width), maxX)
                                transferDragOffset = clamped
                                let newPhase = Int(clamped / maxX * 4)
                                if newPhase != transferHapticPhase {
                                    transferHapticPhase = newPhase
                                    if newPhase > 0 {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                            }
                            .onEnded { _ in
                                transferHapticPhase = 0
                                if transferDragOffset >= maxX * 0.72 {
                                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                    let nextIdx = currentBlockIdx + 1
                                    maxCompletedIdx = max(maxCompletedIdx, currentBlockIdx)
                                    transferDragOffset = 0
                                    boardDragOffset = 0
                                    pageTransitionForward = true
                                    withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                                        currentBlockIdx = nextIdx
                                    }
                                    Task {
                                        try? await Task.sleep(for: .seconds(0.5))
                                        boardedAt = nil
                                        boardedSegmentIdx = -1
                                        if #available(iOS 16.1, *) {
                                            await KORALiveActivityManager.shared.end()
                                        }
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        transferDragOffset = 0
                                    }
                                }
                            }
                    )
            }
        }
        .frame(height: 50)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(seg.line.color.opacity(0.35), lineWidth: 1.5))
    }

    @ViewBuilder
    private func alightSlider(seg: JourneySegment, finishedIdx: Int) -> some View {
        let thumbW: CGFloat = 60
        GeometryReader { geo in
            let maxX = max(geo.size.width - thumbW - 8, 1)
            let progress = min(alightDragOffset / maxX, 1.0)
            ZStack(alignment: .leading) {
                Capsule().fill(seg.line.color.opacity(0.13 + 0.12 * progress))
                Text(alightSliderLabel)
                    .font(.callout).fontWeight(.bold)
                    .foregroundStyle(seg.line.color.opacity(max(0, 1.0 - progress * 2.5)))
                    .frame(maxWidth: .infinity, alignment: .center)
                Capsule()
                    .fill(seg.line.color)
                    .frame(width: thumbW, height: geo.size.height - 10)
                    .overlay(
                        Image(systemName: "door.left.hand.open")
                            .font(.callout).fontWeight(.black)
                            .foregroundStyle(.white)
                    )
                    .shadow(color: seg.line.color.opacity(0.4), radius: 6, y: 2)
                    .offset(x: 4 + alightDragOffset)
                    .gesture(
                        DragGesture(minimumDistance: 4)
                            .onChanged { v in
                                let clamped = min(max(0, v.translation.width), maxX)
                                alightDragOffset = clamped
                                let newPhase = Int(clamped / maxX * 4)
                                if newPhase != alightHapticPhase {
                                    alightHapticPhase = newPhase
                                    if newPhase > 0 {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                            }
                            .onEnded { _ in
                                alightHapticPhase = 0
                                if alightDragOffset >= maxX * 0.72 {
                                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                    maxCompletedIdx = max(maxCompletedIdx, currentBlockIdx)
                                    alightDragOffset = 0
                                    pageTransitionForward = true
                                    withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                                        currentBlockIdx = finishedIdx
                                    }
                                    Task {
                                        try? await Task.sleep(for: .seconds(0.5))
                                        boardedAt = nil
                                        boardedSegmentIdx = -1
                                        if #available(iOS 16.1, *) {
                                            await KORALiveActivityManager.shared.end()
                                        }
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        alightDragOffset = 0
                                    }
                                }
                            }
                    )
            }
        }
        .frame(height: 50)
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(seg.line.color.opacity(0.35), lineWidth: 1.5))
    }

    private func boardCurrentTrain(seg: JourneySegment, in j: TransferJourney) {
        guard boardedAt == nil else { return }
        boardedAt = Date()
        boardedSegmentIdx = currentBlockIdx
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task { await NextStopVerifyTip.didBoardOnce.donate() }
        guard #available(iOS 16.1, *) else { return }
        let dest = j.segments.last?.stations.last ?? ""
        let currentKo = seg.stations.first ?? ""
        let nextKo = seg.stations.count > 1 ? seg.stations[1] : currentKo
        let stopsLeft = max(seg.stations.count - 1, 0)
        Task {
            await KORALiveActivityManager.shared.start(
                destination: dest, current: currentKo, next: nextKo,
                stopsRemaining: stopsLeft, lineColor: seg.line.color, lineName: seg.line.name
            )
        }
    }

    // MARK: One ride block

    /// Self-contained block for ONE subway ride: direction + next station +
    /// where to get off (with transfer hint or destination indicator).
    private func rideBlock(seg: JourneySegment, segIdx: Int, isLast: Bool, j: TransferJourney) -> some View {
        let nextKo: String? = seg.stations.count > 1 ? seg.stations[1] : nil
        let nextDisplay = nextKo.map { MetroLineData.displayName(for: $0, language: displayLanguage) } ?? ""
        let timing = SubwayScheduleService.timing(for: seg, at: Date())
        let displayedTerminus = terminiOverride[segIdx] ?? seg.terminus
        let segDestKo = seg.stations.last ?? displayedTerminus

        let isBoarded = boardedSegmentIdx == segIdx

        return ZStack(alignment: .top) {
            if isBoarded, let bt = boardedAt {
                VStack(spacing: 18) {
                    inTransitSection(seg: seg, boardedAt: bt)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                VStack(spacing: 18) {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.callout).fontWeight(.semibold)
                            .foregroundStyle(seg.line.color)
                        Text(preBoardingStatusLabel)
                            .font(.callout).fontWeight(.bold)
                            .foregroundStyle(seg.line.color)
                        Spacer()
                    }
                    .padding(.horizontal, 14).padding(.vertical, 9)
                    .background(seg.line.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .frame(maxWidth: .infinity)

                    HStack(spacing: 14) {
                        Text(seg.line.badgeText)
                            .font(.largeTitle).fontWeight(.black)
                            .foregroundStyle(.white)
                            .frame(minWidth: 44, idealWidth: 64, maxWidth: 64,
                                   minHeight: 44, idealHeight: 64, maxHeight: 64)
                            .background(seg.line.color)
                            .clipShape(Circle())
                            .layoutPriority(0)
                        VStack(alignment: .leading, spacing: 4) {
                            let isCircularLabel = displayedTerminus == "내선순환" || displayedTerminus == "외선순환"
                            if isCircularLabel {
                                let landmarks = MetroLineData.aheadLandmarks(
                                    from: seg.stations.first ?? "",
                                    toward: displayedTerminus,
                                    lineNumber: seg.line.number
                                )
                                if !landmarks.isEmpty {
                                    platformDirectionHint(landmarks: landmarks, lineColor: seg.line.color)
                                } else {
                                    Text(directionLabel(terminus: displayedTerminus))
                                        .font(.title3).fontWeight(.heavy)
                                        .foregroundStyle(seg.line.color)
                                }
                            } else {
                                // No single "○○행": many termini are valid, and some
                                // same-direction trains (e.g. 사당행) terminate before the
                                // destination. So we orient by the rider's destination and
                                // let the camera confirm the actual train's sign.
                                Text(towardDirectionLabel(segDestKo))
                                    .font(.title3).fontWeight(.heavy)
                                    .foregroundStyle(seg.line.color)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(NavLoc.confirmTrainWithCamera.resolved(displayLanguage))
                                    .font(.caption).fontWeight(.medium)
                                    .foregroundStyle(KORATheme.labelSecondary)
                            }
                        }
                        .layoutPriority(1)
                        Spacer(minLength: 0)
                    }

                    Divider()

                    if let nk = nextKo {
                        verifyNextStopCard(currentKo: seg.stations.first ?? "", nextKo: nk,
                                           nextDisplay: nextDisplay, lineColor: seg.line.color)
                        directionScannerButton(lineColor: seg.line.color)
                        Divider()
                    }

                    trainApproachVisual(seg: seg, timing: timing)
                }
                .frame(maxWidth: .infinity, alignment: .top)
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
        }
        .clipped()
        .padding(16)
        .background(seg.line.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(seg.line.color.opacity(0.25), lineWidth: 1.2))
        .animation(.spring(response: 0.38, dampingFraction: 0.88), value: isBoarded)
    }

    /// Two-line station label (display name + Korean Hangul). Single-line +
    /// minimum-scale to preserve layout proportions on long station names.
    @ViewBuilder
    private func stationCol(primary: String, secondary: String, tint: Color?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(primary)
                .font(.title2).fontWeight(.bold)
                .foregroundStyle(tint ?? KORATheme.labelPrimary)
                .multilineTextAlignment(.leading)
            Text(secondary)
                .font(.body)
                .foregroundStyle(KORATheme.labelSecondary)
                .multilineTextAlignment(.leading)
        }
    }

    // MARK: Pre-boarding verification (wrong-direction defense)

    /// "Point your camera at the sign" — opens the live OCR direction checker.
    private func directionScannerButton(lineColor: Color) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showDirectionScanner = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                    .font(.body).fontWeight(.bold)
                Text(NavLoc.scanDirectionButton.resolved(displayLanguage))
                    .font(.callout).fontWeight(.bold)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote).fontWeight(.bold)
                    .foregroundStyle(lineColor.opacity(0.5))
            }
            .foregroundStyle(lineColor)
            .padding(.horizontal, 14).padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(lineColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    /// ---●──────────────────────────●──▶  horizontal track card.
    private func verifyNextStopCard(currentKo: String, nextKo: String, nextDisplay: String, lineColor: Color) -> some View {
        return VStack(spacing: 10) {
            // ● —tram→→→— ○  track row
            HStack(alignment: .center, spacing: 8) {
                Circle().fill(lineColor).frame(width: 14, height: 14)
                VerifyTrainTrack(lineColor: lineColor)
                Circle().strokeBorder(lineColor, lineWidth: 2.5).frame(width: 14, height: 14)
            }

            // Just an arrow → the next station name. No labels or romaji clutter.
            HStack(spacing: 12) {
                Image(systemName: "arrow.right")
                    .font(.title2).fontWeight(.black)
                    .foregroundStyle(lineColor.opacity(0.7))
                Text(nextKo)
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(lineColor)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(lineColor.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(lineColor.opacity(0.45), lineWidth: 2))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(currentKo)역 출발, 다음 정거장 \(nextKo)역")
        .popoverTip(NextStopVerifyTip(lang: displayLanguage), arrowEdge: .top)
    }

    // MARK: In-transit section (post-boarding)

    /// Animated track row: slow chevron wave + tram icon that travels left→right over 7 s.
    private struct VerifyTrainTrack: View {
        let lineColor: Color
        var body: some View {
            TimelineView(.animation(minimumInterval: 0.04)) { ctx in
                let t = ctx.date.timeIntervalSinceReferenceDate
                VerifyTrainCanvas(
                    phase: t * 0.35,
                    trainProgress: CGFloat(t.truncatingRemainder(dividingBy: 7.0) / 7.0),
                    lineColor: lineColor
                )
            }
            .frame(height: 20)
        }
    }

    private struct VerifyTrainCanvas: View {
        let phase: Double
        let trainProgress: CGFloat
        let lineColor: Color
        var body: some View {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    VerifyChevronRow(phase: phase, lineColor: lineColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Image(systemName: "tram.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(lineColor)
                        .frame(maxHeight: .infinity, alignment: .center)
                        .offset(x: trainProgress * max(0, geo.size.width - 14))
                }
            }
        }
    }

    private struct VerifyChevronRow: View {
        let phase: Double
        let lineColor: Color
        var body: some View {
            HStack(spacing: 0) {
                ForEach(0..<6, id: \.self) { i in
                    Spacer(minLength: 0)
                    let angle: Double = phase * .pi * 2 - Double(i) * .pi * 2.0 / 6.0
                    let opacity: Double = 0.12 + 0.5 * max(0.0, sin(angle))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(lineColor.opacity(opacity))
                }
                Spacer(minLength: 0)
            }
        }
    }

    /// Estimates current train position from `boardedAt` and shows: current
    /// station, stops to alight, and minutes remaining. Refreshes every 5s
    /// via TimelineView so the labels stay live.
    @ViewBuilder
    private func inTransitSection(seg: JourneySegment, boardedAt: Date) -> some View {
        TimelineView(.periodic(from: boardedAt, by: 5)) { context in
            let now = context.date
            let totalStops = max(seg.stopCount, 1)
            let secsPerStop = secondsPerStop(for: seg)
            let elapsed = max(Int(now.timeIntervalSince(boardedAt)), 0)
            // Trust the fused tracker index (realtime > GPS > accelerometer > time,
            // monotonic, gated against overshoot). It already incorporates the
            // time-based floor fed in via the loop below, so no extra max() here —
            // that would re-introduce schedule overshoot on a delayed train.
            let stopsTraveled = min(positionTracker.stationIndex, totalStops)
            let stopsRemaining = max(totalStops - stopsTraveled, 0)
            let currentStationIdx = min(stopsTraveled, seg.stations.count - 1)
            let currentKo = seg.stations[currentStationIdx]
            let alightKo = seg.stations.last ?? ""
            let alightDisplay = MetroLineData.displayName(for: alightKo, language: displayLanguage)
            let secsRemaining = max((totalStops - stopsTraveled) * secsPerStop - (elapsed % secsPerStop), 0)
            let minsRemaining = (secsRemaining + 30) / 60

            VStack(alignment: .leading, spacing: 10) {
                // Station-sign card — tap to correct position estimate.
                let nextStIdx = currentStationIdx + 1
                let nextStKo = nextStIdx < seg.stations.count ? seg.stations[nextStIdx] : nil
                let nextStDisplay = nextStKo.map { MetroLineData.displayName(for: $0, language: displayLanguage) } ?? ""
                let showNextTrans = nextStKo != nil && displayLanguage != .korean && nextStDisplay != (nextStKo ?? "")
                inTransitStationCard(
                    seg: seg,
                    currentKo: currentKo,
                    nextStKo: nextStKo,
                    nextStDisplay: nextStDisplay,
                    showNextTrans: showNextTrans
                )

                // "Confirmed by announcement" badge — pink, the strongest signal.
                if positionTracker.source == .announcement {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform.and.mic")
                            .font(.footnote).fontWeight(.bold)
                        Text(NavLoc.heardFromAnnouncement.resolved(displayLanguage))
                            .font(.footnote).fontWeight(.bold)
                    }
                    .foregroundStyle(.pink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Door side from the PA announcement ("내리실 문은 …").
                if let side = announcer.doorSide {
                    let isRight = side == .right
                    HStack(spacing: 8) {
                        Image(systemName: isRight ? "arrow.right.to.line" : "arrow.left.to.line")
                            .font(.callout).fontWeight(.black)
                        Text((isRight ? NavLoc.doorOpensRight : NavLoc.doorOpensLeft).resolved(displayLanguage))
                            .font(.callout).fontWeight(.bold)
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(seg.line.color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity.combined(with: .scale))
                }

                // Realtime "approaching next" badge — purple, authoritative.
                if positionTracker.arrivingAtNext {
                    HStack(spacing: 6) {
                        Image(systemName: "dot.radiowaves.up.forward")
                            .font(.footnote).fontWeight(.bold)
                        Text(NavLoc.approachingNext.resolved(displayLanguage))
                            .font(.footnote).fontWeight(.bold)
                    }
                    .foregroundStyle(.purple)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Low-confidence safety prompt — nudge the rider to confirm position.
                if positionTracker.confidence == .low {
                    Button { showPositionCorrection = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption).fontWeight(.bold)
                            Text(NavLoc.positionUncertain.resolved(displayLanguage))
                                .font(.caption).fontWeight(.semibold)
                        }
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }

                // Stops remaining + ETA — compact single row
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(NavLoc.stopsToAlight.resolved(displayLanguage))
                            .font(.callout)
                            .foregroundStyle(KORATheme.labelSecondary)
                        Text(NavLoc.stopsRemaining(stopsRemaining, displayLanguage))
                            .font(.title2).fontWeight(.black)
                            .foregroundStyle(KORATheme.labelPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(NavLoc.etaLabel.resolved(displayLanguage))
                            .font(.callout)
                            .foregroundStyle(KORATheme.labelSecondary)
                        Text(minsRemaining == 0
                             ? NavLoc.arrivingSoon.resolved(displayLanguage)
                             : NavLoc.aboutMinutes(minsRemaining, displayLanguage))
                            .font(.title3).fontWeight(.bold)
                            .foregroundStyle(seg.line.color)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(alightKo)역까지 \(stopsRemaining)정거장, 약 \(minsRemaining)분 남음")

                inTransitProgressVisual(seg: seg, currentKo: currentKo, alightKo: alightKo)

                // Alight target card — escalates as we approach. `positionConfirmed`
                // gates the strongest cues: an over-counted estimate must NOT issue a
                // definitive "get off now" that could drop the rider a stop early.
                let positionConfirmed = positionTracker.isCurrentStationConfirmed
                alightTargetCard(
                    alightKo: alightKo,
                    alightDisplay: alightDisplay,
                    stopsRemaining: stopsRemaining,
                    lineColor: seg.line.color,
                    positionConfirmed: positionConfirmed
                )
                .modifier(ShakeEffect(animatableData: CGFloat(alightShakeCount)))
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentKo)
            .onChange(of: stopsRemaining) { old, new in
                if old != 1 && new == 1 {
                    // Only fire the urgent warning haptic + shake when the position is
                    // confirmed by an authoritative source. Unconfirmed estimates get a
                    // gentle nudge so a premature flip can't startle the rider off early.
                    if positionTracker.isCurrentStationConfirmed {
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        withAnimation(.linear(duration: 0.5)) { alightShakeCount += 1 }
                    } else {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            }
        }
        .task(id: boardedAt) {
            // Start GPS + accelerometer tracking for this segment
            positionTracker.start(seg: seg)

            // Listen to PA announcements for ground-truth station confirmation.
            if await announcer.requestAuthorization() {
                announcer.start(candidates: seg.stations) { station, isCurrent in
                    positionTracker.confirmAnnouncedStation(station, isCurrent: isCurrent)
                }
            }

            guard #available(iOS 16.1, *) else { return }
            var lastLiveIdx = -1
            while !Task.isCancelled {
                // Feed the schedule-based floor every few seconds. Sensor/realtime
                // arrivals publish on their own (event-driven), so the index stays
                // in sync without waiting on this tick.
                let elapsed = max(Int(Date().timeIntervalSince(boardedAt)), 0)
                let timeIdx = min(elapsed / secondsPerStop(for: seg), seg.stopCount)
                positionTracker.integrate(timeBasedIdx: timeIdx)

                // Push the Live Activity only when the station actually changes.
                let idx = positionTracker.stationIndex
                if idx != lastLiveIdx {
                    lastLiveIdx = idx
                    let currentKo = seg.stations[min(idx, seg.stations.count - 1)]
                    let nextKo = idx + 1 < seg.stations.count ? seg.stations[idx + 1] : seg.stations.last ?? ""
                    let stopsLeft = max(seg.stations.count - 1 - idx, 0)
                    await KORALiveActivityManager.shared.update(
                        current: currentKo,
                        next: nextKo,
                        stopsRemaining: stopsLeft
                    )
                }
                try? await Task.sleep(for: .seconds(5))
            }
            // Task cancelled (segment changed / left the screen) — release the mic.
            announcer.stop()
        }
        .task(id: boardedAt) {
            // Drive inTransitTramY: jump to current interval progress, then animate smoothly
            let sps = Double(secondsPerStop(for: seg))
            let elapsedSecs = max(Date().timeIntervalSince(boardedAt), 0)
            let posInInterval = (elapsedSecs.truncatingRemainder(dividingBy: sps)) / sps
            let remainingInInterval = sps * (1.0 - posInInterval)

            inTransitTramY = CGFloat(posInInterval)
            withAnimation(.linear(duration: remainingInInterval)) {
                inTransitTramY = 1.0
            }
            try? await Task.sleep(for: .seconds(remainingInInterval))

            while !Task.isCancelled {
                inTransitTramY = 0.0
                withAnimation(.linear(duration: sps)) { inTransitTramY = 1.0 }
                try? await Task.sleep(for: .seconds(sps))
            }
        }
    }

    /// Station-sign card shown while in-transit: tram + circles + next-station name.
    @ViewBuilder
    private func inTransitStationCard(
        seg: JourneySegment,
        currentKo: String,
        nextStKo: String?,
        nextStDisplay: String,
        showNextTrans: Bool
    ) -> some View {
        let trackW: CGFloat = 22
        let tramW: CGFloat = 28
        let connectorH: CGFloat = 28
        let totalH: CGFloat = trackW * 2 + connectorH

        Button { showPositionCorrection = true } label: {
            HStack(alignment: .top, spacing: 8) {
                ZStack(alignment: .top) {
                    Color.clear.frame(width: tramW, height: totalH)
                    Image(systemName: "tram.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(seg.line.color)
                        .frame(width: tramW)
                        .offset(y: inTransitTramY * (connectorH + trackW))
                }
                VStack(alignment: .center, spacing: 0) {
                    Circle().fill(seg.line.color).frame(width: trackW, height: trackW)
                    inTransitWaveConnector(lineColor: seg.line.color, width: trackW, height: connectorH)
                    Circle().strokeBorder(seg.line.color, lineWidth: 2.5)
                        .frame(width: 13, height: 13).frame(width: trackW, height: trackW)
                }
                .frame(width: trackW)
                VStack(alignment: .leading, spacing: 0) {
                    // Current-station name removed — the filled dot is "you are here".
                    Color.clear.frame(height: trackW)
                    Color.clear.frame(height: connectorH)
                    if let nk = nextStKo {
                        Text(nk)
                            .font(.system(size: 26, weight: .black))
                            .foregroundStyle(seg.line.color)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(height: trackW, alignment: .center)
                            .id(nk)
                            .transition(.asymmetric(insertion: .push(from: .bottom), removal: .push(from: .top)))
                    }
                }
                .clipped()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(seg.line.color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(seg.line.color.opacity(0.45), lineWidth: 2))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("현재 \(currentKo)역 근처, 다음 \(nextStKo ?? "")역")
        .accessibilityHint(NavLoc.correctPosition.resolved(displayLanguage))
        .accessibilityAddTraits(.isButton)
    }

    /// Downward-flowing wave chevron connector used between station circles.
    @ViewBuilder
    private func inTransitWaveConnector(lineColor: Color, width: CGFloat, height: CGFloat) -> some View {
        TimelineView(.animation(minimumInterval: 0.05)) { ctx in
            let phase = ctx.date.timeIntervalSinceReferenceDate * 1.2
            VStack(spacing: 3) {
                ForEach(0..<4, id: \.self) { i in
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(lineColor.opacity(
                            0.15 + 0.8 * max(0.0, sin(
                                phase * .pi * 2 - Double(i) * .pi * 2.0 / 4.0
                            ))
                        ))
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(width: width, height: height)
    }

    /// Visual representation of how urgent it is to get off. Color/size/copy
    /// escalate from calm → prepare → imminent → now as `stopsRemaining` drops.
    @ViewBuilder
    private func alightTargetCard(alightKo: String, alightDisplay: String, stopsRemaining: Int, lineColor: Color, positionConfirmed: Bool) -> some View {
        let level = AlightWarningLevel.from(stopsRemaining: stopsRemaining)
        // In the critical last-stop states, always anchor the rider to the station
        // NAME and surface whether the position is confirmed, so an over-counted
        // estimate can't make them step off a station early.
        let showVerify = (level == .imminent || level == .now)

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: level.icon)
                    .font(.title3).fontWeight(.bold)
                    .foregroundStyle(level.accent)
                Text(level.headline(lang: displayLanguage))
                    .font(.body).fontWeight(.bold)
                    .foregroundStyle(level.accent)
            }

            Text(alightKo)
                .font(.system(size: level.koSize, weight: .black))
                .foregroundStyle(KORATheme.labelPrimary)
            if displayLanguage != .korean && alightDisplay != alightKo {
                Text(alightDisplay)
                    .font(.title3).fontWeight(.semibold)
                    .foregroundStyle(KORATheme.labelSecondary)
            }

            if showVerify {
                if positionConfirmed {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.subheadline).fontWeight(.bold)
                        Text(NavLoc.alightPositionConfirmed.resolved(displayLanguage))
                            .font(.subheadline).fontWeight(.semibold)
                    }
                    .foregroundStyle(.green)
                } else {
                    // Unconfirmed estimate near the destination — do NOT command;
                    // tell the rider to match the station name / announcement.
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.subheadline).fontWeight(.bold)
                            Text(NavLoc.verifyStationNameAlight.resolved(displayLanguage))
                                .font(.subheadline).fontWeight(.bold)
                        }
                        .foregroundStyle(.orange)
                        Text(NavLoc.alightPositionUnconfirmed.resolved(displayLanguage))
                            .font(.caption2).fontWeight(.medium)
                            .foregroundStyle(KORATheme.labelSecondary)
                    }
                }
            }

            if let info = exitInfo {
                HStack(spacing: 8) {
                    Text(info.no)
                        .font(.footnote).fontWeight(.black)
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(lineColor)
                        .clipShape(Circle())
                    Text(exitLabel(no: info.no))
                        .font(.callout).fontWeight(.semibold)
                        .foregroundStyle(KORATheme.labelPrimary)
                }
            }
        }
        .padding(level.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(level.bgColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(level.accent.opacity(level.borderOpacity), lineWidth: level.borderWidth)
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: stopsRemaining)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(alightKo)역까지 \(stopsRemaining)정거장 남음. \(level.headline(lang: .korean))")
    }

    /// Average seconds-per-stop for a segment — derived from `SegmentTiming`
    /// if a schedule lookup succeeds, otherwise a 2-minute fallback.
    private func secondsPerStop(for seg: JourneySegment) -> Int {
        let stops = max(seg.stopCount, 1)
        if let timing = SubwayScheduleService.timing(for: seg, at: Date()) {
            let total = max(timing.travelMinutes * 60, stops)
            return max(total / stops, 60)
        }
        return 120
    }

    /// Current estimated Korean station name for the given segment, derived
    /// from `boardedAt` + `secondsPerStop`. Falls back to the boarding station
    /// if not yet boarded.
    private func estimatedCurrentKo(in seg: JourneySegment) -> String {
        guard let bt = boardedAt else { return seg.stations.first ?? "" }
        let secsPerStop = secondsPerStop(for: seg)
        let elapsed = max(Int(Date().timeIntervalSince(bt)), 0)
        let totalStops = max(seg.stopCount, 1)
        let stopsTraveled = min(elapsed / secsPerStop, totalStops)
        let idx = min(stopsTraveled, seg.stations.count - 1)
        return seg.stations[idx]
    }

    /// Back-calculates `boardedAt` so the time-based estimator now reports
    /// `chosenKo` as the current station. Effectively a one-tap correction.
    private func applyPositionCorrection(to chosenKo: String, in seg: JourneySegment) {
        guard let idx = seg.stations.firstIndex(of: chosenKo) else { return }
        let secsPerStop = secondsPerStop(for: seg)
        let elapsedSecs = idx * secsPerStop + secsPerStop / 2
        boardedAt = Date(timeIntervalSinceNow: -Double(elapsedSecs))
        // Sync all sensor baselines to the manually chosen index
        positionTracker.forceIndex(idx)
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
    }

    // MARK: Finished block

    private func finishedBlock(j: TransferJourney) -> some View {
        let destKo = j.segments.last?.stations.last ?? ""
        // Bilingual on the arrival hero — Hangul is the platform sign anchor.
        let destDisplay = MetroLineData.displayBilingual(for: destKo, language: displayLanguage)
        let color = j.segments.last?.line.color ?? .green

        return VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.largeTitle)
                .foregroundStyle(color)
                .padding(.top, 30)

            Text(NavLoc.arrived.resolved(displayLanguage))
                .font(.largeTitle).fontWeight(.black)
                .foregroundStyle(color)
            Text(destDisplay)
                .font(.title2).fontWeight(.bold)
            Text(destKo)
                .font(.body)
                .foregroundStyle(KORATheme.labelSecondary)

            exitInfoBanner(color: color)

            Button {
                withAnimation(.easeInOut(duration: 0.3)) { resetJourney() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise").font(.body)
                    Text(NavLoc.startOver.resolved(displayLanguage)).font(.body).fontWeight(.semibold)
                }
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(color.opacity(0.25), lineWidth: 1.2))
    }

    @ViewBuilder
    private func exitInfoBanner(color: Color) -> some View {
        if let info = exitInfo, !info.no.isEmpty {
            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    Text(info.no)
                        .font(.title2).fontWeight(.black)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(color)
                        .clipShape(Circle())
                    Text(exitLabel(no: info.no))
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(KORATheme.labelPrimary)
                }
                if info.walkMinutes > 0 {
                    let walk = info.walkMinutes
                    Text(walkLabel(minutes: walk))
                        .font(.callout)
                        .foregroundStyle(KORATheme.labelSecondary)
                }
            }
            .padding(.vertical, 12).padding(.horizontal, 20)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func exitLabel(no: String) -> String {
        switch displayLanguage {
        case .korean:   return "\(no)번 출구로 나가세요"
        case .japanese: return "\(no)番出口から出てください"
        case .english:  return "Use Exit \(no)"
        case .chinese:  return "请走\(no)号出口"
        }
    }

    private func walkLabel(minutes: Int) -> String {
        switch displayLanguage {
        case .korean:   return "출구에서 도보 약 \(minutes)분"
        case .japanese: return "出口から徒歩約\(minutes)分"
        case .english:  return "~\(minutes) min walk from exit"
        case .chinese:  return "出口步行约\(minutes)分钟"
        }
    }

    private var exitLoadingLabel: String {
        switch displayLanguage {
        case .korean:   return "출구 정보 가져오는 중..."
        case .japanese: return "出口情報を取得中..."
        case .english:  return "Getting exit info..."
        case .chinese:  return "获取出口信息..."
        }
    }

    // MARK: Arrival badge

    /// Compute the 3 previous stations a train passes through before
    /// reaching the boarding station, in arrival order (earliest → latest).
    /// For circular routes (e.g. Line 2), wraps around the array.
    private func previousStations(for seg: JourneySegment, count: Int = 3) -> [String] {
        let boarding = seg.stations.first ?? ""
        // Prefer a route that contains both boarding station AND terminus so the
        // direction is unambiguous. Fall back to any route with the boarding
        // station — necessary for branching lines where terminus lives on a
        // different branch (e.g. Sinbundang, Line 9 express).
        let route = seg.line.routes.first(where: {
                        $0.stations.contains(boarding) && $0.stations.contains(seg.terminus)
                    }) ?? seg.line.routes.first(where: { $0.stations.contains(boarding) })
        guard let route, let boardingIdx = route.stations.firstIndex(of: boarding) else { return [] }

        // Direction: train approaches from the side OPPOSITE to its terminus.
        // When terminus is absent from the fallback route, use the second journey
        // station (first stop after boarding) to infer which way the train moves.
        let step: Int
        if let tIdx = route.stations.firstIndex(of: seg.terminus) {
            step = tIdx < boardingIdx ? 1 : -1
        } else if seg.stations.count > 1,
                  let nextIdx = route.stations.firstIndex(of: seg.stations[1]) {
            step = nextIdx < boardingIdx ? 1 : -1
        } else {
            return []
        }

        let n = route.stations.count
        var result: [String] = []
        for i in 1...count {
            var idx = boardingIdx + step * i
            if route.isCircular {
                idx = ((idx % n) + n) % n
            } else if idx < 0 || idx >= n {
                break
            }
            result.append(route.stations[idx])
        }
        return result.reversed()
    }

    /// Visualization showing the 3 prev stations + boarding station with the
    /// approaching train icon over its current position (offline schedule
    /// driven). Replaces the bare "N分後" arrival badge with a spatial map.
    private func trainApproachVisual(seg: JourneySegment, timing: SegmentTiming?) -> some View {
        let prev = previousStations(for: seg, count: 3)
        let boarding = seg.stations.first ?? ""
        let allStops = prev + [boarding]
        let trainAt = timing?.currentTrainStation
        let trainIdx = trainAt.flatMap { allStops.firstIndex(of: $0) }
        let isTerminus = prev.isEmpty

        return VStack(alignment: .leading, spacing: 12) {
            Text(NavLoc.trainCurrentLocation.resolved(displayLanguage))
                .font(.body).fontWeight(.semibold)
                .foregroundStyle(KORATheme.labelSecondary)

            if isTerminus {
                // No stations before boarding — this IS the origin terminus.
                // Draw a buffer-stop block → short rail → boarding station,
                // matching the visual language of the station dot row.
                HStack(alignment: .center, spacing: 0) {
                    // Origin/terminus label badge
                    let originLabel: String = {
                        switch displayLanguage {
                        case .korean:   return "출발점"
                        case .japanese: return "始発駅"
                        case .english:  return "Origin"
                        case .chinese:  return "始发站"
                        }
                    }()
                    VStack(spacing: 4) {
                        Color.clear.frame(height: 22)
                        Text(originLabel)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(seg.line.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(seg.line.color.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Color.clear.frame(height: 18)
                    }
                    Rectangle()
                        .fill(seg.line.color.opacity(0.4))
                        .frame(width: 12, height: 3)
                    visualStationDot(
                        station: boarding,
                        isBoarding: true,
                        isTrainHere: false,
                        lineColor: seg.line.color,
                        showLabel: false
                    )
                }
            } else {
                HStack(alignment: .center, spacing: 0) {
                    ForEach(Array(allStops.enumerated()), id: \.offset) { idx, st in
                        visualStationDot(
                            station: st,
                            isBoarding: idx == allStops.count - 1,
                            isTrainHere: trainIdx == idx,
                            lineColor: seg.line.color,
                            showLabel: false
                        )
                        if idx < allStops.count - 1 {
                            Rectangle()
                                .fill(seg.line.color.opacity(0.4))
                                .frame(height: 3)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel(approachAccessibility(seg: seg, trainAt: trainAt))
    }

    private func visualStationDot(station: String, isBoarding: Bool, isTrainHere: Bool, lineColor: Color, showLabel: Bool = true) -> some View {
        VStack(spacing: 4) {
            // Top slot: train icon if it's here, otherwise spacer for alignment
            if isTrainHere {
                Image(systemName: "tram.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .symbolEffect(.pulse)
            } else {
                Color.clear.frame(height: 22)
            }

            Circle()
                .fill(isBoarding ? lineColor : (isTrainHere ? Color.orange : Color.gray.opacity(0.5)))
                .frame(width: isBoarding ? 18 : 12,
                       height: isBoarding ? 18 : 12)
                .overlay(
                    Circle()
                        .stroke(.white, lineWidth: isBoarding ? 2 : 0)
                )

            if showLabel {
                Text(MetroLineData.displayName(for: station, language: displayLanguage))
                    .font(.system(size: 11)).fontWeight(isBoarding ? .bold : .regular)
                    .foregroundStyle(isBoarding ? KORATheme.labelPrimary : KORATheme.labelSecondary)
                    .multilineTextAlignment(.center)
                    .autoFitLine(minScale: 0.7)
            } else {
                Color.clear.frame(height: 14)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func approachAccessibility(seg: JourneySegment, trainAt: String?) -> String {
        guard let at = trainAt else { return "전철이 멀리 떨어져 있습니다" }
        return "전철이 현재 \(at)에 있습니다"
    }

    /// Shows where the user currently is relative to the destination.
    /// Displays the last 3 stations before the destination + destination,
    /// with the current station marked by a pulsing train icon.
    private func inTransitProgressVisual(seg: JourneySegment, currentKo: String, alightKo: String) -> some View {
        let destIdx = seg.stations.count - 1

        let windowCount = 3
        let windowStart = max(destIdx - windowCount, 0)
        let windowStations = Array(seg.stations[windowStart...destIdx])

        let alightDisplay = MetroLineData.displayName(for: alightKo, language: displayLanguage)
        let towardLabel: String = {
            switch displayLanguage {
            case .korean:   return "\(alightDisplay)까지"
            case .japanese: return "\(alightDisplay)まで"
            case .english:  return "To \(alightDisplay)"
            case .chinese:  return "前往\(alightDisplay)"
            }
        }()

        return VStack(alignment: .leading, spacing: 8) {
            Text(towardLabel)
                .font(.callout).fontWeight(.semibold)
                .foregroundStyle(KORATheme.labelSecondary)

            HStack(alignment: .center, spacing: 0) {
                ForEach(Array(windowStations.enumerated()), id: \.offset) { idx, st in
                    visualStationDot(
                        station: st,
                        isBoarding: st == alightKo,
                        isTrainHere: st == currentKo,
                        lineColor: seg.line.color,
                        showLabel: false
                    )
                    if idx < windowStations.count - 1 {
                        Rectangle()
                            .fill(seg.line.color.opacity(0.4))
                            .frame(height: 3)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// Compact chip row showing alternative valid "행" signs — tap to switch displayed terminus.
    private func alternativeTerminiRow(alts: [String], segIdx: Int, lineColor: Color) -> some View {
        let orLabel: String = {
            switch displayLanguage {
            case .korean:   return "어느 방향이든 가능"
            case .japanese: return "どちら方面でも可"
            case .english:  return "Any of these work"
            case .chinese:  return "以下方向均可"
            }
        }()
        // Show at most 2 alternatives; collapse the rest behind a "+N" chip
        let visible = Array(alts.prefix(2))
        let hiddenCount = max(0, alts.count - 2)
        return VStack(alignment: .leading, spacing: 4) {
            Text(orLabel)
                .font(.caption2).fontWeight(.medium)
                .foregroundStyle(KORATheme.labelTertiary)
            HStack(spacing: 6) {
                ForEach(visible, id: \.self) { terminus in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        terminiOverride[segIdx] = terminus
                    } label: {
                        Text(self.terminusSign(terminus))
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(lineColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(lineColor.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(lineColor.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                if hiddenCount > 0 {
                    Text("+\(hiddenCount)")
                        .font(.caption).fontWeight(.medium)
                        .foregroundStyle(KORATheme.labelTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func terminusSign(_ ko: String) -> String {
        switch displayLanguage {
        case .korean:   return "\(ko)행"
        case .japanese: return "\(MetroLineData.displayName(for: ko, language: .japanese))行き"
        case .english:  return "To \(MetroLineData.displayName(for: ko, language: .english))"
        case .chinese:  return "开往\(MetroLineData.displayName(for: ko, language: .chinese))"
        }
    }

    /// Shows landmark stations ahead in the direction of travel so the user can
    /// match the text to the actual physical platform direction signs.
    /// e.g. "시청 · 왕십리 방향" at 홍대입구 내선순환.
    private func platformDirectionHint(landmarks: [String], lineColor: Color) -> some View {
        let suffix: String
        switch displayLanguage {
        case .korean:   suffix = " 방향"
        case .japanese: suffix = " 方面"
        case .english:  suffix = " direction"
        case .chinese:  suffix = " 方向"
        }
        let names = landmarks.map { MetroLineData.displayName(for: $0, language: displayLanguage) }
        return Text(names.joined(separator: " · ") + suffix)
            .font(.largeTitle).fontWeight(.black)
            .foregroundStyle(lineColor)
            .lineLimit(2)
            .minimumScaleFactor(0.65)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Direction label translated for current display language.
    /// Destination-oriented direction label, e.g. "경마공원 방면" — used instead of a
    /// single "○○행" terminus, which can mislead (some same-direction trains stop
    /// short of the destination).
    private func towardDirectionLabel(_ destKo: String) -> String {
        let name = MetroLineData.displayName(for: destKo, language: displayLanguage)
        switch displayLanguage {
        case .korean:   return "\(name) 방면"
        case .japanese: return "\(name)方面"
        case .english:  return "Toward \(name)"
        case .chinese:  return "开往\(name)方向"
        }
    }

    private func directionLabel(terminus: String) -> String {
        // Circular direction labels are already descriptive — translate directly.
        if terminus == "내선순환" {
            switch displayLanguage {
            case .korean:   return "내선순환"
            case .japanese: return "内回り"
            case .english:  return "Inner Loop"
            case .chinese:  return "内环方向"
            }
        }
        if terminus == "외선순환" {
            switch displayLanguage {
            case .korean:   return "외선순환"
            case .japanese: return "外回り"
            case .english:  return "Outer Loop"
            case .chinese:  return "外环方向"
            }
        }
        let display = MetroLineData.displayName(for: terminus, language: displayLanguage)
        switch displayLanguage {
        case .korean:   return "\(display)행"
        case .japanese: return "\(display)行き"
        case .english:  return "Toward \(display)"
        case .chinese:  return "开往\(display)"
        }
    }

    /// Terminus names that make a train VALID (green) vs the ones to avoid (red),
    /// for the camera scanner reading a train's destination display.
    ///
    /// A train is valid only if its terminus is at the destination or BEYOND it.
    /// Crucially, a same-direction train that terminates *before* the destination
    /// (e.g. a 사당행 when you're heading to 경마공원) is invalid — so "green" is
    /// "destination and beyond", and "red" is "everything before the destination"
    /// (which includes both short-turn termini and the opposite direction).
    private func directionMarkers(for seg: JourneySegment) -> (forward: Set<String>, backward: Set<String>) {
        let boarding = seg.stations.first ?? ""
        let dest = seg.stations.last ?? ""
        guard let route = seg.line.routes.first(where: { $0.stations.contains(boarding) && $0.stations.contains(dest) }),
              let bi = route.stations.firstIndex(of: boarding),
              let di = route.stations.firstIndex(of: dest), bi != di else {
            // Circular / unknown route: green = the actual path this train takes.
            return (Set(seg.stations), [])
        }
        let stations = route.stations
        var green = Set<String>()
        var red = Set<String>()
        if di > bi {
            green.formUnion(stations[di...])     // destination and beyond
            red.formUnion(stations[..<di])       // before destination (incl. opposite dir)
        } else {
            green.formUnion(stations[...di])
            red.formUnion(stations[(di + 1)...])
        }
        red.subtract(green)
        return (forward: green, backward: red)
    }

    private func resetJourney() {
        withAnimation(.easeInOut(duration: 0.3)) {
            toStation = nil
            currentBlockIdx = 0
            selectedJourneyIdx = 0
            boardedAt = nil
            boardedSegmentIdx = -1
            maxCompletedIdx = -1
            revisitFromIdx = nil
        }
    }

    // MARK: Current-station header (top of screen, line-colored)

    /// Top-of-screen current station card. Modeled after the iconic Seoul
    /// subway station sign — thick colored border on a white capsule with the
    /// line number badge on the left, station name centered, and a tap
    /// affordance on the right.
    private var currentStationHeader: some View {
        let ko = fromStation ?? ""
        // Bilingual on the prominent current-station header.
        let display = MetroLineData.displayBilingual(for: ko, language: displayLanguage)
        let lines = MetroLineData.linesContaining(ko)
        let primaryColor = lines.first.map { MetroLineData.lineColor($0) } ?? KORATheme.accent

        let lineNames = lines.map { MetroLineData.lineBadgeText($0) }.joined(separator: ", ")
        let headerLabel = lines.isEmpty
            ? "\(ko)역. 현재역 변경하려면 탭하세요."
            : "\(ko)역, \(lineNames). 현재역 변경하려면 탭하세요."

        return Button {
            showFromPicker = true
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(spacing: 4) {
                    ForEach(lines, id: \.self) { num in
                        let compact = lines.count >= 3
                        Text(MetroLineData.lineBadgeText(num))
                            .font(compact ? .subheadline : .body).fontWeight(.black)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .frame(minWidth: compact ? 30 : 36, minHeight: compact ? 30 : 36)
                            .background(MetroLineData.lineColor(num))
                            .clipShape(Capsule())
                            .accessibilityLabel(MetroLineData.lineBadgeText(num))
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    // Prefer one line (scale down slightly if needed).
                    // Only wrap to two lines when the name is genuinely too
                    // long to fit on one — avoids a single-character orphan.
                    ViewThatFits {
                        Text(display)
                            .font(.title).fontWeight(.black)
                            .foregroundStyle(KORATheme.labelPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                        Text(display)
                            .font(.title).fontWeight(.black)
                            .foregroundStyle(KORATheme.labelPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if displayLanguage != .korean {
                        Text(ko)
                            .font(.body).fontWeight(.medium)
                            .foregroundStyle(KORATheme.labelSecondary)
                            .autoFitLine()
                    }
                }

                Spacer()

                Text("출발역 변경")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundStyle(primaryColor)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(primaryColor.opacity(0.12), in: Capsule())
            }
            .padding(.vertical, 12)
            .padding(.leading, 10)
            .padding(.trailing, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(primaryColor, lineWidth: 4)
            )
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .accessibilityLabel(headerLabel)
        .accessibilityHint("길게 누르면 언어를 바꿀 수 있어요")
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                let haptic = UIImpactFeedbackGenerator(style: .medium)
                haptic.impactOccurred()
                showLanguagePicker = true
                Task { await LanguageLongPressTip.didLongPress.donate() }
            }
        )
        .accessibilityAction(named: "언어 변경") { showLanguagePicker = true }
        .popoverTip(LanguageLongPressTip(lang: displayLanguage), arrowEdge: .top)
    }

    // MARK: Destination-focused body (no journey yet)

    /// From + To capsules centered vertically with a directional arrow connector.
    private var destinationFocusBody: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            VStack(spacing: 0) {
                fromInputCard

                // Vertical arrow connector between departure and destination
                VStack(spacing: 2) {
                    Rectangle()
                        .fill(KORATheme.accent.opacity(0.6))
                        .frame(width: 3, height: 16)
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title)
                        .foregroundStyle(KORATheme.accent)
                    Rectangle()
                        .fill(KORATheme.accent.opacity(0.6))
                        .frame(width: 3, height: 16)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 4)

                destinationCTA
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Departure input card — shows selected station or a placeholder when nil.
    @ViewBuilder
    private var fromInputCard: some View {
        let ko = fromStation
        let lines = ko.map { MetroLineData.linesContaining($0) } ?? []
        let primaryColor = lines.first.map { MetroLineData.lineColor($0) } ?? KORATheme.accent

        Button {
            showFromPicker = true
        } label: {
            HStack(alignment: .center, spacing: 12) {
                if let ko = ko {
                    VStack(spacing: 4) {
                        ForEach(lines, id: \.self) { num in
                            let compact = lines.count >= 3
                            Text(MetroLineData.lineBadgeText(num))
                                .font(compact ? .subheadline : .body).fontWeight(.black)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .frame(minWidth: compact ? 30 : 36, minHeight: compact ? 30 : 36)
                                .background(MetroLineData.lineColor(num))
                                .clipShape(Capsule())
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        let display = MetroLineData.displayBilingual(for: ko, language: displayLanguage)
                        ViewThatFits {
                            Text(display)
                                .font(.title).fontWeight(.black)
                                .foregroundStyle(KORATheme.labelPrimary)
                                .lineLimit(1).minimumScaleFactor(0.72)
                            Text(display)
                                .font(.title).fontWeight(.black)
                                .foregroundStyle(KORATheme.labelPrimary)
                                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                        }
                        if displayLanguage != .korean {
                            Text(ko)
                                .font(.body).fontWeight(.medium)
                                .foregroundStyle(KORATheme.labelSecondary)
                                .autoFitLine()
                        }
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(KORATheme.accent.opacity(0.12))
                            .frame(width: 36, height: 36)
                        if isLocating {
                            ProgressView().tint(KORATheme.accent).scaleEffect(0.8)
                        } else {
                            Image(systemName: "location.fill")
                                .font(.body).fontWeight(.black)
                                .foregroundStyle(KORATheme.accent)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(departurePlaceholderLabel)
                            .font(.title).fontWeight(.black)
                            .foregroundStyle(isLocating ? KORATheme.labelSecondary : KORATheme.labelPrimary)
                        if isLocating {
                            Text(locatingLabel)
                                .font(.body)
                                .foregroundStyle(KORATheme.labelSecondary)
                        } else {
                            Text(departureHintLabel)
                                .font(.subheadline)
                                .foregroundStyle(KORATheme.accent.opacity(0.75))
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.body).fontWeight(.bold)
                    .foregroundStyle(primaryColor.opacity(0.6))
            }
            .padding(.vertical, 12)
            .padding(.leading, 10)
            .padding(.trailing, 20)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(ko != nil ? primaryColor : KORATheme.accent,
                                  lineWidth: 4)
            )
            .shadow(color: (ko != nil ? primaryColor : KORATheme.accent).opacity(0.18), radius: 10, x: 0, y: 4)
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(PressScaleButtonStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                let haptic = UIImpactFeedbackGenerator(style: .medium)
                haptic.impactOccurred()
                showLanguagePicker = true
                Task { await LanguageLongPressTip.didLongPress.donate() }
            }
        )
        .accessibilityAction(named: "언어 변경") { showLanguagePicker = true }
        .popoverTip(LanguageLongPressTip(lang: displayLanguage), arrowEdge: .top)
    }

    private var departurePlaceholderLabel: String {
        switch displayLanguage {
        case .korean:   return "어디서 출발하시나요?"
        case .japanese: return "どこから出発しますか？"
        case .english:  return "Where are you departing from?"
        case .chinese:  return "从哪里出发？"
        }
    }

    private var departureHintLabel: String {
        switch displayLanguage {
        case .korean:   return "탭 해서 출발지를 정해주세요"
        case .japanese: return "タップして出発地を選んでください"
        case .english:  return "Tap to set your departure"
        case .chinese:  return "点击设定出发地"
        }
    }

    private var locatingLabel: String {
        switch displayLanguage {
        case .korean:   return "현재 위치 확인 중..."
        case .japanese: return "現在地を確認中..."
        case .english:  return "Detecting location..."
        case .chinese:  return "正在定位..."
        }
    }

    private var preBoardingStatusLabel: String {
        switch displayLanguage {
        case .korean:   return "탑승 전"
        case .japanese: return "乗車前"
        case .english:  return "Before boarding"
        case .chinese:  return "乘车前"
        }
    }

    private var boardingSwipeHintLabel: String {
        switch displayLanguage {
        case .korean:   return "밀어서 탑승하기"
        case .japanese: return "スワイプで乗車"
        case .english:  return "Slide to board"
        case .chinese:  return "滑动上车"
        }
    }

    private var transferSwipeHintLabel: String {
        switch displayLanguage {
        case .korean:   return "밀어서 환승하기"
        case .japanese: return "スワイプで乗換"
        case .english:  return "Slide to transfer"
        case .chinese:  return "滑动换乘"
        }
    }

    private var alightSliderLabel: String {
        switch displayLanguage {
        case .korean:   return "밀어서 내리기"
        case .japanese: return "スワイプで下車"
        case .english:  return "Slide to alight"
        case .chinese:  return "滑动下车"
        }
    }

    private var revisitAlertTitle: String {
        switch displayLanguage {
        case .korean:   return "이미 지나간 단계예요"
        case .japanese: return "完了済みのステップです"
        case .english:  return "Already completed"
        case .chinese:  return "已完成的步骤"
        }
    }

    private var revisitAlertMessage: String {
        switch displayLanguage {
        case .korean:   return "이미 완료한 단계입니다. 다시 보시겠습니까?"
        case .japanese: return "完了済みのステップです。戻りますか？"
        case .english:  return "This step is already done. Do you want to go back to review it?"
        case .chinese:  return "此步骤已完成，要返回查看吗？"
        }
    }

    private var revisitConfirmLabel: String {
        switch displayLanguage {
        case .korean:   return "계속 진행"
        case .japanese: return "続ける"
        case .english:  return "Continue"
        case .chinese:  return "继续"
        }
    }

    private var revisitStayLabel: String {
        switch displayLanguage {
        case .korean:   return "돌아가서 보기"
        case .japanese: return "戻って確認"
        case .english:  return "Go back"
        case .chinese:  return "返回查看"
        }
    }

    private var destinationCTA: some View {
        let ko = toStation
        let lines = ko.map { MetroLineData.linesContaining($0) } ?? []
        let primaryColor = lines.first.map { MetroLineData.lineColor($0) } ?? KORATheme.accent

        return Button {
            showToPicker = true
        } label: {
            HStack(alignment: .center, spacing: 12) {
                if let ko = ko {
                    VStack(spacing: 4) {
                        ForEach(lines, id: \.self) { num in
                            let compact = lines.count >= 3
                            Text(MetroLineData.lineBadgeText(num))
                                .font(compact ? .subheadline : .body).fontWeight(.black)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                                .frame(minWidth: compact ? 30 : 36, minHeight: compact ? 30 : 36)
                                .background(MetroLineData.lineColor(num))
                                .clipShape(Capsule())
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        let display = MetroLineData.displayBilingual(for: ko, language: displayLanguage)
                        ViewThatFits {
                            Text(display)
                                .font(.title).fontWeight(.black)
                                .foregroundStyle(KORATheme.labelPrimary)
                                .lineLimit(1).minimumScaleFactor(0.72)
                            Text(display)
                                .font(.title).fontWeight(.black)
                                .foregroundStyle(KORATheme.labelPrimary)
                                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                        }
                        if displayLanguage != .korean {
                            Text(ko)
                                .font(.body).fontWeight(.medium)
                                .foregroundStyle(KORATheme.labelSecondary)
                                .autoFitLine()
                        }
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(KORATheme.accent.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "magnifyingglass")
                            .font(.body).fontWeight(.black)
                            .foregroundStyle(KORATheme.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NavLoc.whereToGo.resolved(displayLanguage))
                            .font(.title).fontWeight(.black)
                            .foregroundStyle(KORATheme.labelPrimary)
                        Text(NavLoc.tapStationForRoute.resolved(displayLanguage))
                            .font(.body).fontWeight(.medium)
                            .foregroundStyle(KORATheme.labelSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.body).fontWeight(.bold)
                    .foregroundStyle(primaryColor.opacity(0.6))
            }
            .padding(.vertical, 12)
            .padding(.leading, 10)
            .padding(.trailing, 20)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(ko != nil ? primaryColor : KORATheme.accent, lineWidth: 4)
            )
            .shadow(color: (ko != nil ? primaryColor : KORATheme.accent).opacity(0.18), radius: 10, x: 0, y: 4)
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(PressScaleButtonStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .accessibilityLabel(NavLoc.whereToGo.resolved(displayLanguage))
        .accessibilityHint(NavLoc.tapStationForRoute.resolved(displayLanguage))
        .highPriorityGesture(
            LongPressGesture(minimumDuration: 0.6).onEnded { _ in
                let haptic = UIImpactFeedbackGenerator(style: .medium)
                haptic.impactOccurred()
                showLanguagePicker = true
                Task { await LanguageLongPressTip.didLongPress.donate() }
            }
        )
        .accessibilityAction(named: "언어 변경") { showLanguagePicker = true }
    }

    private func autoLocateIfNeeded() {
        guard !didAutoLocate, !isLocating, fromStation == nil else { return }
        didAutoLocate = true
        Task { await detectCurrentStation() }
    }

    // MARK: Alight warning escalation

    /// Visual urgency state for the alight-target card during in-transit.
    /// Each case packages headline, accent color, sizing, and borders so the
    /// card escalates smoothly: calm → prepare → imminent → now.
    private enum AlightWarningLevel {
        case calm, prepare, imminent, now

        static func from(stopsRemaining: Int) -> AlightWarningLevel {
            switch stopsRemaining {
            case 0:    return .now
            case 1:    return .imminent
            case 2, 3: return .prepare
            default:   return .calm
            }
        }

        var icon: String {
            switch self {
            case .calm:     return "flag.checkered"
            case .prepare:  return "exclamationmark.triangle.fill"
            case .imminent: return "exclamationmark.circle.fill"
            case .now:      return "figure.walk.departure"
            }
        }

        var accent: Color {
            switch self {
            case .calm:     return KORATheme.labelSecondary
            case .prepare:  return .orange
            case .imminent: return .red
            case .now:      return .green
            }
        }

        var bgColor: Color {
            switch self {
            case .calm:     return Color.clear
            case .prepare:  return Color.orange.opacity(0.12)
            case .imminent: return Color.red.opacity(0.14)
            case .now:      return Color.green.opacity(0.18)
            }
        }

        var borderOpacity: Double {
            switch self {
            case .calm:     return 0.0
            case .prepare:  return 0.55
            case .imminent: return 0.75
            case .now:      return 0.85
            }
        }

        var borderWidth: CGFloat {
            switch self {
            case .calm:     return 0
            case .prepare:  return 2
            case .imminent: return 3
            case .now:      return 4
            }
        }

        var padding: CGFloat {
            switch self {
            case .calm:     return 12
            case .prepare:  return 13
            case .imminent: return 14
            case .now:      return 16
            }
        }

        var koSize: CGFloat {
            switch self {
            case .calm:     return 24
            case .prepare:  return 30
            case .imminent: return 36
            case .now:      return 42
            }
        }

        func headline(lang: StationLanguage) -> String {
            switch self {
            case .calm:     return NavLoc.alightCalm.resolved(lang)
            case .prepare:  return NavLoc.prepareToGetOff.resolved(lang)
            case .imminent: return NavLoc.nextStopGetOff.resolved(lang)
            case .now:      return NavLoc.getOffNow.resolved(lang)
            }
        }
    }

    private func consumePendingDestination() {
        guard let dest = coordinator.pendingDestination, !dest.isEmpty else { return }
        // Order matters: write the destination coords *before* `toStation`
        // so the toStation onChange handler reads the fresh values when it
        // triggers `fetchExitInfoIfNeeded`.
        exitInfo = nil
        destinationCoordinate = coordinator.destinationCoordinate
        destinationPlaceName = coordinator.destinationPlaceName
        destinationPlaceID = coordinator.destinationPlaceID
        toStation = dest
        selectedJourneyIdx = 0
        let needsAutoFrom = coordinator.autoFromCurrentLocation
        coordinator.clearPending()
        // If user saved a custom exit for this place, use it immediately
        // and skip the auto lookup.
        if let pid = destinationPlaceID,
           let saved = placeStore.places.first(where: { $0.id == pid })?.exitNo,
           !saved.isEmpty {
            exitInfo = NearestExit(no: saved, distanceMeters: 0, walkMinutes: 0)
            return
        }
        if needsAutoFrom {
            // detectCurrentStation will set fromStation → fromStation
            // onChange → fetchExitInfoIfNeeded.
            Task { await detectCurrentStation() }
        } else {
            // User picked "출발역 직접 선택" — drop the persisted from-station
            // and open the picker. When they pick, fromStation onChange runs
            // the fetch.
            fromStation = nil
            showFromPicker = true
        }
    }

    private func fetchExitInfoIfNeeded() {
        // User-confirmed override takes priority over auto lookup. We
        // re-check here (not just in consumePendingDestination) so the
        // value also surfaces when toStation changes through onChange
        // without going through the cross-tab consume path.
        if let pid = destinationPlaceID,
           let saved = placeStore.places.first(where: { $0.id == pid })?.exitNo,
           !saved.isEmpty {
            exitInfo = NearestExit(no: saved, distanceMeters: 0, walkMinutes: 0)
            return
        }
        guard let toKo = toStation else {
            debugLog("[ExitFetch] skip — toStation nil")
            return
        }
        guard let destCoord = destinationCoordinate else {
            debugLog("[ExitFetch] skip — destinationCoordinate nil (place has no GPS)")
            exitInfo = nil
            return
        }
        debugLog("[ExitFetch] toStation='\(toKo)', dest=(\(destCoord.latitude),\(destCoord.longitude))")
        exitInfo = exitService.nearestExit(station: toKo, to: destCoord)
    }

    // MARK: Setup bar

    private func detectCurrentStation() async {
        isLocating = true
        locationError = nil
        defer { isLocating = false }
        do {
            let coord = try await withThrowingTaskGroup(of: CLLocationCoordinate2D.self) { group in
                group.addTask { try await self.locationService.requestOnce() }
                group.addTask {
                    try await Task.sleep(for: .seconds(8))
                    throw LocationService.LocationError.timeout
                }
                defer { group.cancelAll() }
                return try await group.next()!
            }

            if let local = MetroLineData.nearestStation(
                latitude: coord.latitude,
                longitude: coord.longitude
            ) {
                fromStation = local.name
                selectedJourneyIdx = 0
                return
            }

            locationError = NavLoc.locationErrorNoStation.resolved(displayLanguage)
        } catch let e as LocationService.LocationError {
            locationError = e.errorDescription
        } catch {
            locationError = NavLoc.locationErrorFetchFailed.resolved(displayLanguage)
        }
    }

    // MARK: - Journey confirmation

    private func journeyConfirmView(for j: TransferJourney) -> some View {
        let fromKo = fromStation ?? ""
        let toKo   = toStation   ?? ""
        let fromDisplay = MetroLineData.displayBilingual(for: fromKo, language: displayLanguage)
        let toDisplay   = MetroLineData.displayBilingual(for: toKo,   language: displayLanguage)
        let fromRelevantLines = j.segments.isEmpty ? [] : [j.segments[0].line.number]
        let toRelevantLines   = j.segments.isEmpty ? [] : [j.segments.last!.line.number]

        return ScrollView {
            VStack(spacing: 20) {

                // ── Route summary card ────────────────────────────────
                VStack(spacing: 0) {
                    // Departure
                    routeStationRow(ko: fromKo, display: fromDisplay, lines: fromRelevantLines)

                    // Per-segment: connector rail then transfer station (except last)
                    ForEach(j.segments.indices, id: \.self) { idx in
                        let seg = j.segments[idx]
                        routeSegmentRail(seg: seg)
                        if idx < j.segments.count - 1, let xfrKo = seg.stations.last {
                            let xfrDisplay = MetroLineData.displayBilingual(for: xfrKo, language: displayLanguage)
                            let xfrLines   = [seg.line.number, j.segments[idx + 1].line.number]
                            routeStationRow(ko: xfrKo, display: xfrDisplay, lines: xfrLines)
                        }
                    }

                    // Destination
                    routeStationRow(ko: toKo, display: toDisplay, lines: toRelevantLines)
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

                // ── Action buttons ────────────────────────────────────
                VStack(spacing: 10) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            journeyConfirmed = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "tram.fill")
                                .font(.body).fontWeight(.semibold)
                            Text(startJourneyLabel)
                                .font(.body).fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(KORATheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button {
                        toStation = nil
                        selectedJourneyIdx = 0
                    } label: {
                        Text(changeDestinationLabel)
                            .font(.body).fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(KORATheme.accent.opacity(0.1))
                            .foregroundStyle(KORATheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
    }

    private func routeStationRow(ko: String, display: String, lines: [Int]) -> some View {
        HStack(alignment: .center, spacing: 14) {
            // Line badges — fixed-size circles
            HStack(spacing: 5) {
                ForEach(lines.prefix(3), id: \.self) { num in
                    Text(MetroLineData.lineBadgeText(num))
                        .font(.callout).fontWeight(.black)
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.45)
                        .lineLimit(1)
                        .frame(width: 36, height: 36)
                        .background(MetroLineData.lineColor(num))
                        .clipShape(Circle())
                }
            }
            .frame(minWidth: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(display)
                    .font(.title2).fontWeight(.black)
                    .foregroundStyle(KORATheme.labelPrimary)
                    .lineLimit(2)
                if displayLanguage != .korean {
                    Text(ko)
                        .font(.body)
                        .foregroundStyle(KORATheme.labelSecondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 18).padding(.vertical, 16)
    }

    private func routeSegmentRail(seg: JourneySegment) -> some View {
        HStack(spacing: 0) {
            seg.line.color.opacity(0.5)
                .frame(width: 3)
                .padding(.leading, 35)
            Text("\(seg.stopCount)\(stopsUnit)")
                .font(.body).fontWeight(.semibold)
                .foregroundStyle(KORATheme.labelSecondary)
                .padding(.leading, 10)
            Spacer()
        }
        .frame(height: 32)
    }

    private var transferLabel: String {
        switch displayLanguage {
        case .korean:   return "환승"
        case .japanese: return "乗換"
        case .english:  return "Transfer"
        case .chinese:  return "换乘"
        }
    }

    private func summaryChip(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(KORATheme.accent)
            Text(label)
                .font(.callout).fontWeight(.semibold)
                .foregroundStyle(KORATheme.labelPrimary)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(KORATheme.accent.opacity(0.08))
        .clipShape(Capsule())
    }

    private var departureLabel: String {
        switch displayLanguage {
        case .korean:   return "출발"
        case .japanese: return "出発"
        case .english:  return "From"
        case .chinese:  return "出发"
        }
    }

    private var arrivalLabel: String {
        switch displayLanguage {
        case .korean:   return "도착"
        case .japanese: return "到着"
        case .english:  return "To"
        case .chinese:  return "到达"
        }
    }

    private var stopsUnit: String {
        switch displayLanguage {
        case .korean:   return "정거장"
        case .japanese: return "駅"
        case .english:  return " stops"
        case .chinese:  return "站"
        }
    }

    private func transferSummary(_ count: Int) -> String {
        switch displayLanguage {
        case .korean:   return count == 0 ? "환승 없음" : "\(count)회 환승"
        case .japanese: return count == 0 ? "乗換なし" : "\(count)回乗換"
        case .english:  return count == 0 ? "No transfer" : "\(count) transfer\(count > 1 ? "s" : "")"
        case .chinese:  return count == 0 ? "无换乘" : "换乘\(count)次"
        }
    }

    private var startJourneyLabel: String {
        switch displayLanguage {
        case .korean:   return "출발하기"
        case .japanese: return "出発する"
        case .english:  return "Start Journey"
        case .chinese:  return "开始导航"
        }
    }

    private var changeDestinationLabel: String {
        switch displayLanguage {
        case .korean:   return "목적지 다시 선택"
        case .japanese: return "目的地を変更"
        case .english:  return "Change destination"
        case .chinese:  return "重新选择目的地"
        }
    }

    private var noRouteView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(KORATheme.labelSecondary.opacity(0.25))
            VStack(spacing: 4) {
                Text(NavLoc.noRouteFound.resolved(displayLanguage))
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(KORATheme.labelSecondary)
                Text(NavLoc.noRouteHint.resolved(displayLanguage))
                    .font(.body)
                    .foregroundStyle(KORATheme.labelSecondary.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Button {
                toStation = nil
                selectedJourneyIdx = 0
            } label: {
                Text(NavLoc.pickAnotherDestination.resolved(displayLanguage))
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(KORATheme.accent)
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Station Search Sheet

struct StationSearchSheet: View {
    let title: String
    let excluding: String?
    let displayLanguage: StationLanguage
    /// When true, a GPS-based "nearby stations" section is shown at the top
    /// (used for the departure picker).
    var showNearby: Bool = false
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selectedLineNumber: Int? = nil
    @State private var nearby: [String] = []
    @State private var isLocatingNearby = false
    private let locationService = LocationService()

    private let allLines = MetroLineData.seoulLines

    // Stations on the selected line, sorted in the display language's natural
    // order (한글 가나다 / 五十音 / A-Z / 中文). Deduped across line branches.
    private var stationsOnSelectedLine: [String] {
        guard let num = selectedLineNumber,
              let line = allLines.first(where: { $0.number == num }) else { return [] }
        var seen = Set<String>()
        var out: [String] = []
        for route in line.routes {
            for s in route.stations where seen.insert(s).inserted {
                out.append(s)
            }
        }
        return out.sorted { a, b in
            MetroLineData.sortKey(for: a, language: displayLanguage)
                < MetroLineData.sortKey(for: b, language: displayLanguage)
        }
    }

    private var filtered: [String] {
        let q = query.trimmingCharacters(in: .whitespaces)
        let base = (selectedLineNumber == nil
                    ? MetroLineData.allStationNames
                        .sorted { MetroLineData.sortKey(for: $0, language: displayLanguage)
                                < MetroLineData.sortKey(for: $1, language: displayLanguage) }
                    : stationsOnSelectedLine)
            .filter { $0 != excluding }
        guard !q.isEmpty else { return base }
        return base.filter { s in
            s.contains(q)
                || MetroLineData.displayName(for: s, language: .japanese).contains(q)
                || MetroLineData.displayName(for: s, language: .english).lowercased().contains(q.lowercased())
                || MetroLineData.displayName(for: s, language: .chinese).contains(q)
        }
    }

    /// True when the list should be grouped under section headers — uses the
    /// display language's natural collation (한글 / 五十音 / A-Z). Chinese mode
    /// uses a flat sorted list since there's no clean single-letter system.
    private var shouldUseLanguageSections: Bool {
        MetroLineData.usesSections(for: displayLanguage)
            && query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var languageSections: [(key: String, stations: [String])] {
        var dict: [String: [String]] = [:]
        for s in filtered {
            let key = MetroLineData.sectionInitial(for: s, language: displayLanguage)
            dict[key, default: []].append(s)
        }
        return MetroLineData.sectionOrder(for: displayLanguage).compactMap { key in
            guard let arr = dict[key], !arr.isEmpty else { return nil }
            return (key, arr)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                lineFilterBar
                Divider()

                if filtered.isEmpty {
                    emptyState
                } else if shouldUseLanguageSections {
                    sectionedListView
                } else {
                    flatListView
                }
            }
            .searchable(text: $query, prompt: NavLoc.searchPrompt.resolved(displayLanguage))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NavLoc.done.resolved(displayLanguage)) { dismiss() }
                }
            }
            .task { if showNearby { await loadNearby() } }
        }
    }

    // MARK: - Nearby (GPS) stations

    /// Show the GPS "nearby" section only on the unfiltered, unsearched list.
    private var showNearbySection: Bool {
        showNearby && !nearby.isEmpty
            && selectedLineNumber == nil
            && query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    @ViewBuilder private var nearbySection: some View {
        Section {
            ForEach(nearby, id: \.self) { station in
                Button {
                    onSelect(station)
                    dismiss()
                } label: {
                    stationRow(station)
                }
                .buttonStyle(.plain)
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.footnote)
                    .foregroundStyle(KORATheme.accent)
                Text(NavLoc.nearbyStations.resolved(displayLanguage))
                    .font(.body).fontWeight(.bold)
                    .foregroundStyle(KORATheme.accent)
                Spacer()
            }
        }
    }

    private func loadNearby() async {
        guard nearby.isEmpty, !isLocatingNearby else { return }
        isLocatingNearby = true
        defer { isLocatingNearby = false }
        guard let coord = try? await locationService.requestOnce() else { return }
        nearby = MetroLineData
            .nearestStations(latitude: coord.latitude, longitude: coord.longitude)
            .map(\.name)
            .filter { $0 != excluding }
    }

    // MARK: - List bodies

    private var flatListView: some View {
        List {
            if showNearbySection { nearbySection }
            ForEach(filtered, id: \.self) { station in
                Button {
                    onSelect(station)
                    dismiss()
                } label: {
                    stationRow(station)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.plain)
    }

    private var sectionedListView: some View {
        let sections = languageSections
        return ScrollViewReader { proxy in
            ZStack(alignment: .trailing) {
                List {
                    if showNearbySection { nearbySection }
                    ForEach(sections, id: \.key) { group in
                        Section {
                            ForEach(group.stations, id: \.self) { station in
                                Button {
                                    onSelect(station)
                                    dismiss()
                                } label: {
                                    stationRow(station)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            HStack(spacing: 8) {
                                Text(displayLanguage == .japanese ? group.key + "行" : group.key)
                                    .font(.body).fontWeight(.bold)
                                    .foregroundStyle(KORATheme.accent)
                                Text("\(group.stations.count)")
                                    .font(.body).fontWeight(.semibold)
                                    .foregroundStyle(KORATheme.labelSecondary)
                                Spacer()
                            }
                            .id(group.key)
                        }
                    }
                }
                .listStyle(.plain)

                kanaSideIndex(keys: sections.map(\.key), proxy: proxy)
            }
        }
    }

    private func kanaSideIndex(keys: [String], proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 1) {
            ForEach(keys, id: \.self) { key in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(key, anchor: .top)
                    }
                } label: {
                    Text(key)
                        .font(.body).fontWeight(.bold)
                        .foregroundStyle(KORATheme.accent)
                        .frame(width: 22, height: 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 2)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground).opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(KORATheme.separator, lineWidth: 0.5)
                )
        )
        .padding(.trailing, 4)
    }

    // MARK: - Line filter

    private var lineFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                allChip
                ForEach(allLines, id: \.number) { line in
                    lineChip(line)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
    }

    private var allChip: some View {
        let isSelected = (selectedLineNumber == nil)
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedLineNumber = nil }
        } label: {
            Text(NavLoc.allLines.resolved(displayLanguage))
                .font(.body).fontWeight(isSelected ? .bold : .medium)
                .foregroundStyle(isSelected ? .white : KORATheme.labelSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color(.systemGray) : Color(.secondarySystemBackground))
                .clipShape(Capsule())
        }
    }

    private func lineChip(_ line: SeoulMetroLineInfo) -> some View {
        let isSelected = (selectedLineNumber == line.number)
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedLineNumber = line.number }
        } label: {
            HStack(spacing: 6) {
                Text(line.badgeText)
                    .font(.body).fontWeight(.black)
                    .foregroundStyle(isSelected ? line.color : .white)
                    .frame(minWidth: 20, minHeight: 20)
                    .padding(.horizontal, 4)
                    .background(isSelected ? Color.white : line.color)
                    .clipShape(Capsule())
                Text(line.code != nil ? line.name : NavLoc.lineLabel(line.number, displayLanguage))
                    .font(.body).fontWeight(isSelected ? .bold : .medium)
                    .foregroundStyle(isSelected ? .white : line.color)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? line.color : line.color.opacity(0.12))
            .clipShape(Capsule())
        }
    }

    // MARK: - Row

    private func stationRow(_ station: String) -> some View {
        let primary = MetroLineData.displayName(for: station, language: displayLanguage)
        let subtitle = MetroLineData.subtitle(for: station, language: displayLanguage)
        let romaji = displayLanguage == .english
            ? nil
            : MetroLineData.displayName(for: station, language: .english)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(primary)
                    .font(.body).fontWeight(.medium)
                    .foregroundStyle(KORATheme.labelPrimary)
                HStack(spacing: 5) {
                    if let subtitle {
                        Text(subtitle)
                            .font(.body)
                            .foregroundStyle(KORATheme.labelSecondary)
                    }
                    if let romaji, !romaji.isEmpty, subtitle != romaji {
                        Text(subtitle == nil ? romaji : "· \(romaji)")
                            .font(.body)
                            .foregroundStyle(KORATheme.labelTertiary)
                    }
                }
            }
            Spacer()
            HStack(spacing: 3) {
                ForEach(linesForStation(station), id: \.self) { num in
                    Text(MetroLineData.lineBadgeText(num))
                        .font(.caption).fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .frame(minWidth: 20, minHeight: 18)
                        .background(MetroLineData.lineColor(num))
                        .clipShape(Capsule())
                }
            }
        }
        .contentShape(Rectangle())
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(KORATheme.labelSecondary.opacity(0.4))
            Text(NavLoc.noMatchingStation.resolved(displayLanguage))
                .font(.body)
                .foregroundStyle(KORATheme.labelSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func linesForStation(_ station: String) -> [Int] {
        var result: [Int] = []
        for line in MetroLineData.seoulLines {
            guard !result.contains(line.number) else { continue }
            if line.routes.contains(where: { $0.stations.contains(station) }) {
                result.append(line.number)
            }
        }
        return result
    }
}

#Preview {
    SubwayNavigatorView()
}

// MARK: - Language picker sheet

/// Bottom sheet for choosing display language. Reached by long-pressing the
/// station header (or the welcome title before a station is picked).
// MARK: - Position correction sheet

/// Lists every station in the current segment so the user can pick the one
/// they're actually at. Two hint sources surface as suggestion rows:
///   • GPS-based: nearest segment station to the device's current coordinates
///     (only useful above ground, but it's a free signal when available).
///   • Time-based: the existing schedule-derived estimate.
struct PositionCorrectionSheet: View {
    let seg: JourneySegment
    let displayLanguage: StationLanguage
    let estimatedStation: String
    let onPick: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var locationSuggestion: String? = nil
    @State private var isFetchingLocation = false
    private let locationService = LocationService()

    var body: some View {
        NavigationStack {
            List {
                // GPS-based suggestion (only if it resolved to a station inside
                // the current segment — otherwise we'd be misleading).
                if let gps = locationSuggestion, gps != estimatedStation {
                    Section {
                        suggestionRow(ko: gps, icon: "location.circle.fill", iconColor: .blue,
                                      caption: NavLoc.gpsSuggestion.resolved(displayLanguage))
                    }
                } else if isFetchingLocation {
                    Section {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text(NavLoc.searchingLocation.resolved(displayLanguage))
                                .font(.body)
                                .foregroundStyle(KORATheme.labelSecondary)
                        }
                    }
                }

                Section {
                    ForEach(seg.stations, id: \.self) { ko in
                        let display = MetroLineData.displayName(for: ko, language: displayLanguage)
                        let isEstimate = (ko == estimatedStation)
                        let isGPS = (ko == locationSuggestion)
                        Button {
                            onPick(ko)
                            dismiss()
                        } label: {
                            HStack(alignment: .center, spacing: 12) {
                                Circle()
                                    .fill(seg.line.color)
                                    .frame(width: 14, height: 14)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(display)
                                        .font(.body).fontWeight(isEstimate || isGPS ? .bold : .regular)
                                        .foregroundStyle(KORATheme.labelPrimary)
                                    if displayLanguage != .korean {
                                        Text(ko)
                                            .font(.body)
                                            .foregroundStyle(KORATheme.labelSecondary)
                                    }
                                }
                                Spacer()
                                if isGPS {
                                    Image(systemName: "location.circle.fill")
                                        .font(.body)
                                        .foregroundStyle(.blue)
                                } else if isEstimate {
                                    Image(systemName: "clock.fill")
                                        .font(.body)
                                        .foregroundStyle(seg.line.color)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .foregroundStyle(KORATheme.labelPrimary)
                    }
                } header: {
                    Text(NavLoc.pickCurrentStation.resolved(displayLanguage))
                }
            }
            .navigationTitle(NavLoc.correctPosition.resolved(displayLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NavLoc.done.resolved(displayLanguage)) { dismiss() }
                }
            }
            .task { await tryLocate() }
        }
    }

    @ViewBuilder
    private func suggestionRow(ko: String, icon: String, iconColor: Color, caption: String) -> some View {
        let display = MetroLineData.displayName(for: ko, language: displayLanguage)
        Button {
            onPick(ko)
            dismiss()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(caption)
                        .font(.body).fontWeight(.semibold)
                        .foregroundStyle(iconColor)
                    Text(display)
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(KORATheme.labelPrimary)
                    if displayLanguage != .korean {
                        Text(ko)
                            .font(.body)
                            .foregroundStyle(KORATheme.labelSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundStyle(KORATheme.labelTertiary)
            }
            .contentShape(Rectangle())
        }
        .foregroundStyle(KORATheme.labelPrimary)
    }

    private func tryLocate() async {
        guard locationSuggestion == nil, !isFetchingLocation else { return }
        isFetchingLocation = true
        defer { isFetchingLocation = false }
        do {
            let coord = try await locationService.requestOnce()
            locationSuggestion = nearestStation(in: seg.stations, to: coord)
        } catch {
            // Underground / denied / unavailable — silently skip the suggestion.
            locationSuggestion = nil
        }
    }

    /// Nearest station from the candidate list to a coordinate, using an
    /// equirectangular approximation (good enough for ranking within Seoul).
    private func nearestStation(in candidates: [String], to coord: CLLocationCoordinate2D) -> String? {
        var bestKo: String? = nil
        var bestDist = Double.infinity
        let cosLat = cos(coord.latitude * .pi / 180)
        for ko in candidates {
            guard let c = MetroLineData.stationCoordinates[ko] else { continue }
            let dlat = c.lat - coord.latitude
            let dlng = (c.lng - coord.longitude) * cosLat
            let d = dlat * dlat + dlng * dlng
            if d < bestDist {
                bestDist = d
                bestKo = ko
            }
        }
        // Reject GPS hints that put us > ~3 km from any segment station —
        // most likely indoor noise rather than a real fix.
        let metersSquared = bestDist * 111_000 * 111_000
        guard metersSquared < 3_000 * 3_000 else { return nil }
        return bestKo
    }

}

struct LanguagePickerSheet: View {
    @Binding var languagePref: String
    @Environment(\.dismiss) private var dismiss

    /// Language used to render this sheet's chrome (title, "Auto", Done button).
    /// Pinned to the user's resolved preference at sheet-open time so toggling
    /// a row instantly changes the visible labels.
    private var sheetLang: StationLanguage {
        guard !languagePref.isEmpty,
              let explicit = StationLanguage(rawValue: languagePref)
        else { return StationLanguage.resolveFromSystemLocale() }
        return explicit
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        languagePref = ""
                        dismiss()
                    } label: {
                        HStack {
                            Label(
                                "\(NavLoc.autoLabel.resolved(sheetLang)) (\(StationLanguage.resolveFromSystemLocale().displayName))",
                                systemImage: "sparkles"
                            )
                            Spacer()
                            if languagePref.isEmpty {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(KORATheme.accent)
                            }
                        }
                    }
                    .foregroundStyle(KORATheme.labelPrimary)
                }

                Section {
                    ForEach(StationLanguage.allCases, id: \.self) { lang in
                        Button {
                            languagePref = lang.rawValue
                            dismiss()
                        } label: {
                            HStack {
                                Text(lang.displayName)
                                Spacer()
                                if languagePref == lang.rawValue {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(KORATheme.accent)
                                }
                            }
                        }
                        .foregroundStyle(KORATheme.labelPrimary)
                    }
                }
            }
            .navigationTitle(NavLoc.languagePickerTitle.resolved(sheetLang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NavLoc.done.resolved(sheetLang)) { dismiss() }
                }
            }
        }
    }
}

// Horizontal shake — drives alightTargetCard warning animation.
private struct PressScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}

private struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 7
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        .init(.init(translationX: amount * sin(animatableData * .pi * shakesPerUnit), y: 0))
    }
}
