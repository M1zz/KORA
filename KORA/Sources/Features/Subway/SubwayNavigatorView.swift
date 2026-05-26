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

    // Cross-tab navigation intent
    @State private var coordinator = NavigationCoordinator.shared
    @State private var placeStore = PlaceStore.shared

    private var journeys: [TransferJourney] {
        guard let f = fromStation, let t = toStation else { return [] }
        return MetroLineData.findAnyJourneys(from: f, to: t)
    }
    private var journey: TransferJourney? {
        journeys.indices.contains(selectedJourneyIdx) ? journeys[selectedJourneyIdx] : nil
    }

    // Saved places attached to the current "from" station — quick destination suggestions.
    private var savedPlacesNearby: [Place] {
        guard let f = fromStation else { return [] }
        return placeStore.places.filter { !$0.nearestStation.isEmpty && $0.nearestStation != f }
    }
    private var savedPlacesAtFromStation: [Place] {
        guard let f = fromStation else { return [] }
        return placeStore.places.filter { $0.nearestStation == f }
    }

    var body: some View {
        Group {
            if fromStation == nil {
                welcomeGate
                    .transition(.opacity)
            } else {
                navigatorBody
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: fromStation == nil)
        .sheet(isPresented: $showFromPicker) {
            StationSearchSheet(
                title: NavLoc.currentStationTitle.resolved(displayLanguage),
                excluding: toStation,
                displayLanguage: displayLanguage
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
            if fromStation == nil, !persistedFromStation.isEmpty {
                fromStation = persistedFromStation
            }
            if toStation == nil, !persistedToStation.isEmpty {
                toStation = persistedToStation
                selectedJourneyIdx = 0
            }
            consumePendingDestination()
            autoLocateIfNeeded()
        }
        .onChange(of: fromStation) { _, new in
            persistedFromStation = new ?? ""
        }
        .onChange(of: toStation) { _, new in
            persistedToStation = new ?? ""
        }
        .onChange(of: coordinator.routeRequestNonce) { _, _ in consumePendingDestination() }
        .onChange(of: journey?.id) { _, _ in
            currentBlockIdx = 0
            boardedAt = nil
        }
    }

    // MARK: - Boarding state machine (one tap = one segment)

    /// Two-tap boarding flow:
    ///   tap 1 → mark `boardedAt` (now shows in-transit view)
    ///   tap 2 → user has alighted, advance to next segment, clear `boardedAt`
    /// On the finished card, tap = reset for a re-do.
    private func advanceBoarding(in j: TransferJourney) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            if currentBlockIdx >= j.segments.count {
                // Finished — tap = reset for a re-do.
                currentBlockIdx = 0
                boardedAt = nil
                resetJourney()
            } else if boardedAt == nil {
                boardedAt = Date()
                let haptic = UIImpactFeedbackGenerator(style: .light)
                haptic.impactOccurred()
                Task { await NextStopVerifyTip.didBoardOnce.donate() }
            } else {
                currentBlockIdx += 1
                boardedAt = nil
                let haptic = UIImpactFeedbackGenerator(style: .medium)
                haptic.impactOccurred()
            }
        }
    }

    private var navigatorBody: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if let j = journey {
                    activeStepHost(for: j)
                } else if fromStation != nil && toStation != nil {
                    currentStationHeader
                    noRouteView
                } else {
                    destinationFocusBody
                }
            }
            if let j = journey {
                boardingActionBar(for: j)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Single-block UI (one block per subway ride)

    /// Shows ONLY the current ride block. Past blocks have folded away.
    /// After the last ride is boarded, the arrived block is shown.
    @ViewBuilder
    private func activeStepHost(for j: TransferJourney) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if currentBlockIdx < j.segments.count {
                    rideBlock(
                        seg: j.segments[currentBlockIdx],
                        isLast: currentBlockIdx == j.segments.count - 1
                    )
                } else {
                    finishedBlock(j: j)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 22)
            .padding(.bottom, 200) // sticky action bar clearance
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.hidden)
        .animation(.easeInOut(duration: 0.3), value: currentBlockIdx)
    }

    // MARK: One ride block

    /// Self-contained block for ONE subway ride: direction + next station +
    /// where to get off (with transfer hint or destination indicator).
    private func rideBlock(seg: JourneySegment, isLast: Bool) -> some View {
        let alightKo = seg.stations.last ?? ""
        let alightDisplay = MetroLineData.displayName(for: alightKo, language: displayLanguage)
        let nextKo: String? = seg.stations.count > 1 ? seg.stations[1] : nil
        let nextDisplay = nextKo.map { MetroLineData.displayName(for: $0, language: displayLanguage) } ?? ""
        let timing = SubwayScheduleService.timing(for: seg, at: Date())
        let alightLineColor = seg.line.color
        let nextLines = MetroLineData.linesContaining(alightKo)

        return VStack(spacing: 18) {
            // Direction header — which train.
            // The direction text gets layout priority so it never truncates;
            // the line-number badge shrinks (min 44pt) if space is tight.
            HStack(spacing: 14) {
                Text(seg.line.badgeText)
                    .font(.largeTitle).fontWeight(.black)
                    .foregroundStyle(.white)
                    .frame(minWidth: 44, idealWidth: 64, maxWidth: 64,
                           minHeight: 44, idealHeight: 64, maxHeight: 64)
                    .background(seg.line.color)
                    .clipShape(Circle())
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .layoutPriority(0)
                VStack(alignment: .leading, spacing: 4) {
                    Text(directionLabel(terminus: seg.terminus))
                        .font(.largeTitle).fontWeight(.black)
                        .foregroundStyle(seg.line.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    // Secondary line: always show Korean Hangul so the user
                    // can match the platform signage in any UI language.
                    if displayLanguage != .korean {
                        Text("\(seg.terminus)행")
                            .font(.title3)
                            .foregroundStyle(KORATheme.labelSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
                .layoutPriority(1)
                Spacer(minLength: 0)
            }

            Divider()

            // After "boarded" was tapped: show live in-transit position +
            // stops remaining + ETA, refreshed every few seconds.
            if let bt = boardedAt {
                inTransitSection(seg: seg, boardedAt: bt)
                Divider()
            } else if let nk = nextKo {
                // HERO verification card — the single most important pre-boarding
                // action. Hangul is the largest text because the in-train LED
                // shows Korean. The display language sits below as a phonetic aid.
                verifyNextStopCard(nextKo: nk, nextDisplay: nextDisplay, lineColor: seg.line.color)
                Divider()
            }

            // Pre-boarding only: "where to get off" overview + train approach
            // visual. After boarding, `inTransitSection`'s alight target card
            // already conveys this info more prominently with escalation —
            // showing it twice would just push other content offscreen.
            if boardedAt == nil {
                HStack(spacing: 12) {
                    Image(systemName: isLast ? "flag.checkered" : "arrow.triangle.swap")
                        .font(.title2).fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(isLast ? alightLineColor : KORATheme.accent)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(isLast
                             ? NavLoc.getOffStation.resolved(displayLanguage)
                             : NavLoc.transferStation.resolved(displayLanguage))
                            .font(.body).fontWeight(.semibold)
                            .foregroundStyle(KORATheme.labelSecondary)
                        Text(alightDisplay)
                            .font(.title2).fontWeight(.black)
                            .foregroundStyle(KORATheme.labelPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        HStack(spacing: 6) {
                            if displayLanguage != .korean {
                                Text(alightKo)
                                    .font(.body)
                                    .foregroundStyle(KORATheme.labelSecondary)
                            }
                            // Show all line dots for transfer stations.
                            // Capsule (not Circle) so multi-letter codes like
                            // "AR" (AREX) or "GJ" (경의중앙선) aren't clipped.
                            if !isLast && nextLines.count > 1 {
                                HStack(spacing: 3) {
                                    ForEach(nextLines, id: \.self) { num in
                                        Text(MetroLineData.lineBadgeText(num))
                                            .font(.caption).fontWeight(.black)
                                            .foregroundStyle(.white)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.5)
                                            .padding(.horizontal, 5)
                                            .frame(minWidth: 20, minHeight: 18)
                                            .background(MetroLineData.lineColor(num))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    Spacer()
                }

                trainApproachVisual(seg: seg, timing: timing)
            }
        }
        .padding(20)
        .background(seg.line.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(seg.line.color.opacity(0.25), lineWidth: 1.2))
    }

    /// Two-line station label (display name + Korean Hangul). Single-line +
    /// minimum-scale to preserve layout proportions on long station names.
    @ViewBuilder
    private func stationCol(primary: String, secondary: String, tint: Color?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(primary)
                .font(.title2).fontWeight(.bold)
                .foregroundStyle(tint ?? KORATheme.labelPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.leading)
            Text(secondary)
                .font(.body)
                .foregroundStyle(KORATheme.labelSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.leading)
        }
    }

    // MARK: Pre-boarding verification (wrong-direction defense)

    /// Compact next-stop card. Just the station name — large Hangul (the LED
    /// verification target) over a smaller display-language reading. The
    /// teaching for *what to do with this* lives in `NextStopVerifyTip`, shown
    /// once via TipKit popover instead of repeating on every ride.
    @ViewBuilder
    private func verifyNextStopCard(nextKo: String, nextDisplay: String, lineColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "tram.fill")
                    .font(.body).fontWeight(.bold)
                    .foregroundStyle(lineColor)
                Text(NavLoc.nextStopShort.resolved(displayLanguage))
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(lineColor)
            }
            Text(nextKo)
                .font(.system(size: 44, weight: .black))
                .foregroundStyle(KORATheme.labelPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if displayLanguage != .korean && nextDisplay != nextKo {
                Text(nextDisplay)
                    .font(.title2).fontWeight(.semibold)
                    .foregroundStyle(KORATheme.labelSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(lineColor.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(lineColor.opacity(0.45), lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("다음 정거장 \(nextKo)역")
        .popoverTip(NextStopVerifyTip(lang: displayLanguage), arrowEdge: .top)
    }

    // MARK: In-transit section (post-boarding)

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
            let stopsTraveled = min(elapsed / secsPerStop, totalStops)
            let stopsRemaining = max(totalStops - stopsTraveled, 0)
            let currentStationIdx = min(stopsTraveled, seg.stations.count - 1)
            let currentKo = seg.stations[currentStationIdx]
            let currentDisplay = MetroLineData.displayName(for: currentKo, language: displayLanguage)
            let alightKo = seg.stations.last ?? ""
            let alightDisplay = MetroLineData.displayName(for: alightKo, language: displayLanguage)
            let secsRemaining = max((totalStops - stopsTraveled) * secsPerStop - (elapsed % secsPerStop), 0)
            let minsRemaining = (secsRemaining + 30) / 60

            VStack(alignment: .leading, spacing: 14) {
                // Current position — tappable to correct
                Button {
                    showPositionCorrection = true
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(seg.line.color)
                                .frame(width: 44, height: 44)
                            Image(systemName: "tram.fill")
                                .font(.title3).fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(NavLoc.currentlyAt.resolved(displayLanguage))
                                    .font(.body).fontWeight(.semibold)
                                    .foregroundStyle(KORATheme.labelSecondary)
                                Image(systemName: "pencil.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(KORATheme.labelTertiary)
                            }
                            Text(currentDisplay)
                                .font(.title2).fontWeight(.black)
                                .foregroundStyle(KORATheme.labelPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            if displayLanguage != .korean {
                                Text(currentKo)
                                    .font(.body).fontWeight(.medium)
                                    .foregroundStyle(KORATheme.labelSecondary)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("현재 \(currentKo)역 근처")
                .accessibilityHint(NavLoc.correctPosition.resolved(displayLanguage))
                .accessibilityAddTraits(.isButton)

                // Progress bar — stations remaining
                if totalStops > 0 {
                    GeometryReader { geo in
                        let progress = min(max(Double(stopsTraveled) / Double(totalStops), 0), 1)
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(seg.line.color.opacity(0.18))
                            Capsule()
                                .fill(seg.line.color)
                                .frame(width: geo.size.width * progress)
                        }
                    }
                    .frame(height: 8)
                    .accessibilityHidden(true)
                }

                // Stops remaining + ETA
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(NavLoc.stopsToAlight.resolved(displayLanguage))
                            .font(.body)
                            .foregroundStyle(KORATheme.labelSecondary)
                        Text(NavLoc.stopsRemaining(stopsRemaining, displayLanguage))
                            .font(.title).fontWeight(.black)
                            .foregroundStyle(KORATheme.labelPrimary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(NavLoc.etaLabel.resolved(displayLanguage))
                            .font(.body)
                            .foregroundStyle(KORATheme.labelSecondary)
                        Text(minsRemaining == 0
                             ? NavLoc.arrivingSoon.resolved(displayLanguage)
                             : NavLoc.aboutMinutes(minsRemaining, displayLanguage))
                            .font(.title2).fontWeight(.bold)
                            .foregroundStyle(seg.line.color)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(alightKo)역까지 \(stopsRemaining)정거장, 약 \(minsRemaining)분 남음")

                // Alight target — escalates as we approach.
                //   > 3 stops away: calm informational card
                //   2-3 stops:      orange "prepare" warning
                //   1 stop:         red "next stop!" alert
                //   0 stops:        green "get off NOW!" arrival
                alightTargetCard(
                    alightKo: alightKo,
                    alightDisplay: alightDisplay,
                    stopsRemaining: stopsRemaining,
                    lineColor: seg.line.color
                )
            }
        }
    }

    /// Visual representation of how urgent it is to get off. Color/size/copy
    /// escalate from calm → prepare → imminent → now as `stopsRemaining` drops.
    @ViewBuilder
    private func alightTargetCard(alightKo: String, alightDisplay: String, stopsRemaining: Int, lineColor: Color) -> some View {
        let level = AlightWarningLevel.from(stopsRemaining: stopsRemaining)

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: level.icon)
                    .font(.title3).fontWeight(.bold)
                    .foregroundStyle(level.accent)
                Text(level.headline(lang: displayLanguage))
                    .font(.body).fontWeight(.bold)
                    .foregroundStyle(level.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            Text(alightKo)
                .font(.system(size: level.koSize, weight: .black))
                .foregroundStyle(KORATheme.labelPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if displayLanguage != .korean && alightDisplay != alightKo {
                Text(alightDisplay)
                    .font(.title3).fontWeight(.semibold)
                    .foregroundStyle(KORATheme.labelSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
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
        // Aim for the middle of the chosen station's window so a small clock
        // tick doesn't immediately bump it to the next stop.
        let elapsedSecs = idx * secsPerStop + secsPerStop / 2
        boardedAt = Date(timeIntervalSinceNow: -Double(elapsedSecs))
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
    }

    // MARK: Finished block

    private func finishedBlock(j: TransferJourney) -> some View {
        let destKo = j.segments.last?.stations.last ?? ""
        let destDisplay = MetroLineData.displayName(for: destKo, language: displayLanguage)
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
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(color.opacity(0.25), lineWidth: 1.2))
    }

    // MARK: Arrival badge

    /// Compute the 3 previous stations a train passes through before
    /// reaching the boarding station, in arrival order (earliest → latest).
    /// For circular routes (e.g. Line 2), wraps around the array.
    private func previousStations(for seg: JourneySegment, count: Int = 3) -> [String] {
        let boarding = seg.stations.first ?? ""
        guard let route = seg.line.routes.first(where: {
            $0.stations.contains(boarding) && $0.stations.contains(seg.terminus)
        }), let boardingIdx = route.stations.firstIndex(of: boarding) else { return [] }

        let terminusIdx = route.stations.firstIndex(of: seg.terminus) ?? boardingIdx
        // The train comes FROM the side opposite to terminus.
        let step = terminusIdx < boardingIdx ? 1 : -1
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
        let isFarAway = trainIdx == nil

        return VStack(alignment: .leading, spacing: 12) {
            Text(NavLoc.trainCurrentLocation.resolved(displayLanguage))
                .font(.body).fontWeight(.semibold)
                .foregroundStyle(KORATheme.labelSecondary)

            HStack(alignment: .center, spacing: 0) {
                if isFarAway {
                    VStack(spacing: 2) {
                        Image(systemName: "tram.fill")
                            .font(.title3)
                            .foregroundStyle(seg.line.color)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(KORATheme.labelTertiary)
                    }
                    .frame(width: 28)
                    Rectangle()
                        .fill(seg.line.color.opacity(0.4))
                        .frame(width: 16, height: 3)
                }
                ForEach(Array(allStops.enumerated()), id: \.offset) { idx, st in
                    visualStationDot(
                        station: st,
                        isBoarding: idx == allStops.count - 1,
                        isTrainHere: trainIdx == idx,
                        lineColor: seg.line.color
                    )
                    if idx < allStops.count - 1 {
                        Rectangle()
                            .fill(seg.line.color.opacity(0.4))
                            .frame(height: 3)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel(approachAccessibility(seg: seg, trainAt: trainAt))
    }

    private func visualStationDot(station: String, isBoarding: Bool, isTrainHere: Bool, lineColor: Color) -> some View {
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

            Text(MetroLineData.displayName(for: station, language: displayLanguage))
                .font(.body).fontWeight(isBoarding ? .bold : .regular)
                .foregroundStyle(isBoarding ? KORATheme.labelPrimary : KORATheme.labelSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
    }

    private func approachAccessibility(seg: JourneySegment, trainAt: String?) -> String {
        guard let at = trainAt else { return "전철이 멀리 떨어져 있습니다" }
        return "전철이 현재 \(at)에 있습니다"
    }

    /// Direction label translated for current display language.
    private func directionLabel(terminus: String) -> String {
        let display = MetroLineData.displayName(for: terminus, language: displayLanguage)
        switch displayLanguage {
        case .korean:   return "\(display)행"
        case .japanese: return "\(display)行き"
        case .english:  return "Toward \(display)"
        case .chinese:  return "开往\(display)"
        }
    }

    /// Offline-computed arrival prediction.
    private func arrivalBadge(timing: SegmentTiming, lineColor: Color) -> some View {
        let m = timing.minutesUntilArrival
        return HStack(spacing: 10) {
            Image(systemName: m <= 1 ? "tram.fill" : "clock.fill")
                .font(.title3)
                .foregroundStyle(m <= 1 ? .orange : lineColor)
            VStack(alignment: .leading, spacing: 1) {
                if m <= 0 {
                    Text(NavLoc.arrivingSoon.resolved(displayLanguage))
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(.orange)
                } else if m == 1 {
                    Text(NavLoc.aboutMinutes(1, displayLanguage))
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(.orange)
                } else {
                    Text(NavLoc.aboutMinutes(m, displayLanguage))
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(lineColor)
                }
                Text(NavLoc.nextTrain.resolved(displayLanguage))
                    .font(.body)
                    .foregroundStyle(KORATheme.labelSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func resetJourney() {
        withAnimation(.easeInOut(duration: 0.3)) {
            toStation = nil
            currentBlockIdx = 0
            selectedJourneyIdx = 0
            boardedAt = nil
        }
    }

    // MARK: - Boarding action bar (sticky bottom)

    @ViewBuilder
    private func boardingActionBar(for j: TransferJourney) -> some View {
        let isFinished = currentBlockIdx >= j.segments.count
        let activeColor: Color = isFinished
            ? .green
            : (j.segments[safe: currentBlockIdx]?.line.color ?? KORATheme.accent)

        VStack(spacing: 0) {
            Button {
                advanceBoarding(in: j)
            } label: {
                actionBarLabel(j: j, isFinished: isFinished)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .padding(.horizontal, 18)
                    .background(activeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 22)
            }
            .buttonStyle(.plain)
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
        .frame(maxWidth: .infinity, alignment: .bottom)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    @ViewBuilder
    private func actionBarLabel(j: TransferJourney, isFinished: Bool) -> some View {
        if isFinished {
            HStack(spacing: 12) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title3)
                    .foregroundStyle(.white)
                Text(NavLoc.startOver.resolved(displayLanguage))
                    .font(.title3).fontWeight(.bold)
                    .foregroundStyle(.white)
                Spacer()
            }
        } else {
            let seg = j.segments[currentBlockIdx]
            let terminus = MetroLineData.displayName(for: seg.terminus, language: displayLanguage)
            let alight = MetroLineData.displayName(for: seg.stations.last ?? "", language: displayLanguage)
            let isBoarded = boardedAt != nil
            HStack(spacing: 12) {
                Image(systemName: isBoarded ? "figure.walk" : "tram.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text(isBoarded
                         ? NavLoc.didYouGetOff.resolved(displayLanguage)
                         : NavLoc.didYouBoard.resolved(displayLanguage))
                        .font(.body).fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.85))
                    Text(isBoarded
                         ? "\(alight) — \(NavLoc.tapWhenOff.resolved(displayLanguage))"
                         : NavLoc.tapWhenBoarded(terminus, displayLanguage))
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }

    // MARK: Current-station header (top of screen, line-colored)

    /// Top-of-screen current station card. Modeled after the iconic Seoul
    /// subway station sign — thick colored border on a white capsule with the
    /// line number badge on the left, station name centered, and a tap
    /// affordance on the right.
    private var currentStationHeader: some View {
        let ko = fromStation ?? ""
        let display = MetroLineData.displayName(for: ko, language: displayLanguage)
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
                        Text(MetroLineData.lineBadgeText(num))
                            .font(.body).fontWeight(.black)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .padding(.horizontal, 4)
                            .frame(minWidth: 36, minHeight: 36)
                            .background(MetroLineData.lineColor(num))
                            .clipShape(Capsule())
                            .accessibilityLabel(MetroLineData.lineBadgeText(num))
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(display)
                        .font(.title).fontWeight(.black)
                        .foregroundStyle(KORATheme.labelPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if displayLanguage != .korean {
                        Text(ko)
                            .font(.body).fontWeight(.medium)
                            .foregroundStyle(KORATheme.labelSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
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
            .background(
                Capsule()
                    .fill(Color(.systemBackground))
            )
            .overlay(
                Capsule()
                    .strokeBorder(primaryColor, lineWidth: 4)
            )
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

    /// From + To capsules centered vertically as one hero pair, with optional
    /// saved-place quick routes pinned to the bottom.
    private var destinationFocusBody: some View {
        let hasSaved = !savedPlacesAtFromStation.isEmpty || !savedPlacesNearby.isEmpty

        return VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(spacing: 0) {
                currentStationHeader
                destinationCTA
            }
            Spacer(minLength: 0)

            if hasSaved {
                ScrollView {
                    VStack(spacing: 16) {
                        if !savedPlacesAtFromStation.isEmpty {
                            savedSection(
                                title: NavLoc.savedAtThisStation.resolved(displayLanguage),
                                places: savedPlacesAtFromStation,
                                atStation: true
                            )
                        }

                        if !savedPlacesNearby.isEmpty {
                            savedSection(
                                title: NavLoc.savedGoTo.resolved(displayLanguage),
                                places: savedPlacesNearby,
                                atStation: false
                            )
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 32)
                }
                .frame(maxHeight: 320)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Destination capsule — visual twin of `currentStationHeader` styled
    /// after the Seoul subway station sign (thick accent border, white
    /// capsule fill, circular leading badge).
    private var destinationCTA: some View {
        Button {
            showToPicker = true
        } label: {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(KORATheme.accent)
                        .frame(width: 36, height: 36)
                    Image(systemName: "magnifyingglass")
                        .font(.body).fontWeight(.black)
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(NavLoc.whereToGo.resolved(displayLanguage))
                        .font(.title).fontWeight(.black)
                        .foregroundStyle(KORATheme.labelPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(NavLoc.tapStationForRoute.resolved(displayLanguage))
                        .font(.body).fontWeight(.medium)
                        .foregroundStyle(KORATheme.labelSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.body).fontWeight(.bold)
                    .foregroundStyle(KORATheme.accent.opacity(0.6))
            }
            .padding(.vertical, 12)
            .padding(.leading, 10)
            .padding(.trailing, 20)
            .background(
                Capsule()
                    .fill(Color(.systemBackground))
            )
            .overlay(
                Capsule()
                    .strokeBorder(KORATheme.accent, lineWidth: 4)
            )
        }
        .buttonStyle(.plain)
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

    private func savedSection(title: String, places: [Place], atStation: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(LocalizedStringKey(title))
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(KORATheme.labelSecondary)
                Text("\(places.count)")
                    .font(.body).fontWeight(.bold)
                    .foregroundStyle(KORATheme.accent)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(KORATheme.accent.opacity(0.12))
                    .clipShape(Capsule())
                Spacer()
            }
            ForEach(places) { place in
                if atStation {
                    atStationRow(place)
                } else {
                    quickRouteRow(place)
                }
            }
        }
    }

    // MARK: Welcome gate (first launch / no current station)

    private var welcomeGate: some View {
        ZStack {
            LinearGradient(
                colors: [KORATheme.accent.opacity(0.12), Color(.systemBackground)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .fill(KORATheme.accent.opacity(0.12))
                            .frame(width: 120, height: 120)
                        Image(systemName: "location.viewfinder")
                            .font(.largeTitle).fontWeight(.light)
                            .foregroundStyle(KORATheme.accent)
                    }
                    VStack(spacing: 6) {
                        Text(NavLoc.welcomeTitle.resolved(displayLanguage))
                            .font(.title).fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        Text(locationError != nil
                             ? NavLoc.welcomeHintNoGPS.resolved(displayLanguage)
                             : NavLoc.welcomeHintDefault.resolved(displayLanguage))
                            .font(.body)
                            .foregroundStyle(KORATheme.labelSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityHint("길게 누르면 언어를 바꿀 수 있어요")
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                            let haptic = UIImpactFeedbackGenerator(style: .medium)
                            haptic.impactOccurred()
                            showLanguagePicker = true
                            Task { await LanguageLongPressTip.didLongPress.donate() }
                        }
                    )
                    .accessibilityAction(named: "언어 변경") { showLanguagePicker = true }
                    .popoverTip(LanguageLongPressTip(lang: displayLanguage), arrowEdge: .top)
                }

                VStack(spacing: 12) {
                    Button {
                        Task { await detectCurrentStation() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.body).fontWeight(.semibold)
                            Text(NavLoc.useGPS.resolved(displayLanguage))
                                .font(.body).fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isLocating ? KORATheme.accent.opacity(0.5) : KORATheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isLocating)

                    Button {
                        showFromPicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.body).fontWeight(.semibold)
                            Text(NavLoc.pickStationManually.resolved(displayLanguage))
                                .font(.body).fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(KORATheme.accent.opacity(0.12))
                        .foregroundStyle(KORATheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)

                if let err = locationError {
                    Label(err, systemImage: "exclamationmark.triangle.fill")
                        .font(.body)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 24)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                Text(NavLoc.footerNote.resolved(displayLanguage))
                    .font(.body)
                    .foregroundStyle(KORATheme.labelTertiary)
                    .padding(.bottom, 24)
            }
        }
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
            case .calm:     return Color(.secondarySystemBackground)
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
            case .calm:     return 14
            case .prepare:  return 16
            case .imminent: return 18
            case .now:      return 20
            }
        }

        var koSize: CGFloat {
            switch self {
            case .calm:     return 28
            case .prepare:  return 36
            case .imminent: return 44
            case .now:      return 52
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

    // MARK: Last-train warning

    private struct LastTrainWarning {
        let line: Int
        let lineColor: Color
        let minutesRemaining: Int
    }

    /// If any line used by the current journey is within 60 minutes of its
    /// approximate last train, surface a banner.
    private var lastTrainWarning: LastTrainWarning? {
        guard let j = journey else { return nil }
        let now = MetroLineData.currentMinutesPastMidnight()
        var tightest: LastTrainWarning? = nil
        for seg in j.segments {
            let last = MetroLineData.lastTrainMinutesPastMidnight(for: seg.line.number) + 24 * 60
            let remaining = last - now
            guard remaining > 0, remaining <= 60 else { continue }
            if tightest == nil || remaining < tightest!.minutesRemaining {
                tightest = LastTrainWarning(
                    line: seg.line.number,
                    lineColor: seg.line.color,
                    minutesRemaining: remaining
                )
            }
        }
        return tightest
    }

    private func lastTrainBanner(_ w: LastTrainWarning) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.badge.exclamationmark.fill")
                .font(.body).fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.orange)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(NavLoc.lastTrainRemaining(w.minutesRemaining, displayLanguage))
                    .font(.body).fontWeight(.bold)
                    .foregroundStyle(.orange)
                Text(NavLoc.lastTrainApproaching(line: w.line, displayLanguage))
                    .font(.body)
                    .foregroundStyle(KORATheme.labelSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.08))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(w.line)호선 막차까지 \(w.minutesRemaining)분 남았습니다. 서둘러 주세요.")
        .accessibilityAddTraits(.isStaticText)
    }

    private func consumePendingDestination() {
        guard let dest = coordinator.pendingDestination, !dest.isEmpty else { return }
        toStation = dest
        selectedJourneyIdx = 0
        coordinator.clearPending()
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

    // MARK: Summary header (covers direct + transfer journeys)

    // MARK: Journey cards — strictly direction + next station + transfer + destination.


    private func atStationRow(_ place: Place) -> some View {
        HStack(spacing: 12) {
            Image(systemName: place.category.systemImage)
                .font(.body)
                .foregroundStyle(KORATheme.categoryColor(place.category))
                .frame(width: 32, height: 32)
                .background(KORATheme.categoryColor(place.category).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(place.nameJP)
                    .font(.body).fontWeight(.semibold)
                    .lineLimit(2)
                Text(place.name)
                    .font(.body)
                    .foregroundStyle(KORATheme.labelSecondary)
                    .lineLimit(2)
            }
            Spacer()

            Text(NavLoc.walkingArrived.resolved(displayLanguage))
                .font(.body).fontWeight(.semibold)
                .foregroundStyle(KORATheme.accent)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(KORATheme.accent.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(10)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(KORATheme.separator, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func quickRouteRow(_ place: Place) -> some View {
        Button {
            toStation = place.nearestStation
            selectedJourneyIdx = 0
        } label: {
            HStack(spacing: 12) {
                Image(systemName: place.category.systemImage)
                    .font(.body)
                    .foregroundStyle(KORATheme.categoryColor(place.category))
                    .frame(width: 32, height: 32)
                    .background(KORATheme.categoryColor(place.category).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(place.nameJP)
                        .font(.body).fontWeight(.semibold)
                        .foregroundStyle(KORATheme.labelPrimary)
                        .lineLimit(2)
                    HStack(spacing: 4) {
                        Image(systemName: "tram.fill")
                            .font(.body)
                        Text(MetroLineData.displayName(for: place.nearestStation, language: displayLanguage))
                    }
                    .font(.body)
                    .foregroundStyle(KORATheme.labelSecondary)
                    .lineLimit(2)
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(KORATheme.accent)
            }
            .padding(10)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(KORATheme.separator, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
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

// MARK: - Train Approach Card

private struct TrainApproachCard: View {
    let timing: SegmentTiming
    let boardingStation: String
    let terminus: String
    let lineNumber: Int
    let lineColor: Color
    let displayLanguage: StationLanguage

    private let dotSize: CGFloat = 40
    private let iconH: CGFloat  = 22
    private let trackH: CGFloat = 14

    // VoiceOver: static description of train position (no live region — avoids
    // second-by-second interruption). User re-focuses to get fresh countdown.
    private var accessibilityPositionLabel: String {
        let approach = MetroLineData.approachStations(before: boardingStation, toward: terminus, lineNumber: lineNumber)
        let all = approach + [boardingStation]
        if let trainStation = timing.currentTrainStation,
           let trainIdx = all.firstIndex(of: trainStation) {
            let stopsAway = all.count - 1 - trainIdx
            return "\(boardingStation)역 열차 접근 정보. 현재 \(stopsAway)정거장 전 \(trainStation)역 통과 중."
        } else if timing.currentTrainStation != nil {
            return "\(boardingStation)역 열차 접근 정보. 열차 접근 중."
        } else {
            return "\(boardingStation)역 열차 접근 정보. \(timing.currentTrainTerminus)역에서 발차 대기 중."
        }
    }

    // VoiceOver value: countdown at moment of focus (not live-announced)
    private var accessibilityCountdownValue: String {
        let secs = max(0, Int(timing.nextArrivalAtBoarding.timeIntervalSince(Date())))
        let m = secs / 60; let s = secs % 60
        return secs == 0 ? "곧 도착" : "\(m)분 \(s)초 후 도착"
    }

    var body: some View {
        let approach = MetroLineData.approachStations(before: boardingStation, toward: terminus, lineNumber: lineNumber)
        let all = approach + [boardingStation]
        let trainIdx = timing.currentTrainStation.flatMap { all.firstIndex(of: $0) }

        VStack(alignment: .leading, spacing: 10) {
            // Track row
            HStack(alignment: .top, spacing: 0) {
                ForEach(0..<all.count, id: \.self) { idx in
                    let isBoarding = idx == all.count - 1
                    let isTrain   = idx == trainIdx
                    let isPassed  = idx < (trainIdx ?? 0)

                    // Station column (fixed width)
                    VStack(spacing: 4) {
                        // Train icon slot
                        if isTrain {
                            Image(systemName: "tram.fill")
                                .font(.body).fontWeight(.bold)
                                .foregroundStyle(lineColor)
                                .frame(height: iconH)
                        } else {
                            Color.clear.frame(height: iconH)
                        }
                        // Dot
                        if isBoarding {
                            ZStack {
                                Circle().strokeBorder(lineColor, lineWidth: 2.5)
                                if trainIdx == nil || isTrain {
                                    Circle().fill(lineColor.opacity(0.15))
                                }
                            }
                            .frame(width: trackH, height: trackH)
                        } else if isTrain {
                            Circle()
                                .fill(lineColor)
                                .frame(width: 13, height: 13)
                                .shadow(color: lineColor.opacity(0.45), radius: 4)
                        } else {
                            Circle()
                                .fill(isPassed ? lineColor.opacity(0.35) : Color(.systemGray4))
                                .frame(width: 9, height: 9)
                        }
                    }
                    .frame(width: dotSize)

                    // Connector between stations
                    if idx < all.count - 1 {
                        let passed = idx < (trainIdx ?? 0)
                        Capsule()
                            .fill(passed ? lineColor.opacity(0.5) : Color(.systemGray5))
                            .frame(height: 2.5)
                            // push connector down to dot center:
                            // iconH(22) + spacing(4) + dot_center(7) - line_half(1.25) ≈ 31.75
                            .padding(.top, iconH + 4 + 6.75)
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            // Station name row (same fixed-width cells)
            HStack(spacing: 0) {
                ForEach(0..<all.count, id: \.self) { idx in
                    let isBoarding = idx == all.count - 1
                    let stopsAway  = all.count - 1 - idx
                    VStack(spacing: 2) {
                        Text(MetroLineData.displayName(for: all[idx], language: displayLanguage))
                            .font(.body).fontWeight(isBoarding ? .semibold : .regular)
                            .foregroundStyle(isBoarding ? KORATheme.labelPrimary : KORATheme.labelTertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Text(isBoarding
                             ? NavLoc.boardingShort.resolved(displayLanguage)
                             : NavLoc.stopsBefore(stopsAway, displayLanguage))
                            .font(.body)
                            .foregroundStyle(KORATheme.labelTertiary)
                    }
                    .frame(width: dotSize)

                    if idx < all.count - 1 { Spacer() }
                }
            }

            // Countdown (TimelineView → only this part redraws each second)
            HStack(alignment: .bottom) {
                if trainIdx == nil {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(MetroLineData.displayName(for: timing.currentTrainTerminus, language: displayLanguage))
                            .font(.body).fontWeight(.medium)
                            .foregroundStyle(KORATheme.labelTertiary)
                            .accessibilityHidden(true)
                        Text(NavLoc.waitingToDepart.resolved(displayLanguage))
                            .font(.body)
                            .foregroundStyle(KORATheme.labelTertiary)
                            .accessibilityHidden(true)
                    }
                }
                Spacer()
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    let secs = max(0, Int(timing.nextArrivalAtBoarding.timeIntervalSince(ctx.date)))
                    let m = secs / 60
                    let s = secs % 60
                    Text(String(format: "%02d:%02d", m, s))
                        .font(.system(.largeTitle, design: .monospaced).weight(.black))
                        .foregroundStyle(secs < 60 ? .orange : lineColor)
                        .contentTransition(.numericText(countsDown: true))
                        .accessibilityHidden(true)  // value surfaced via card-level accessibilityValue
                }
            }
        }
        .padding(16)
        .background(lineColor.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(lineColor.opacity(0.2), lineWidth: 1))
        // Single accessible element: position label + countdown value read together on focus.
        // No live region — avoids interrupting the user every second.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityPositionLabel)
        .accessibilityValue(accessibilityCountdownValue)
    }
}

// MARK: - Station Search Sheet

struct StationSearchSheet: View {
    let title: String
    let excluding: String?
    let displayLanguage: StationLanguage
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selectedLineNumber: Int? = nil

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
        }
    }

    // MARK: - List bodies

    private var flatListView: some View {
        List(filtered, id: \.self) { station in
            Button {
                onSelect(station)
                dismiss()
            } label: {
                stationRow(station)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
    }

    private var sectionedListView: some View {
        let sections = languageSections
        return ScrollViewReader { proxy in
            ZStack(alignment: .trailing) {
                List {
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
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
                            .lineLimit(2)
                    }
                }
            }
            Spacer()
            HStack(spacing: 3) {
                ForEach(linesForStation(station), id: \.self) { num in
                    Text(MetroLineData.lineBadgeText(num))
                        .font(.caption).fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 4)
                        .frame(minWidth: 20, minHeight: 18)
                        .background(MetroLineData.lineColor(num))
                        .clipShape(Capsule())
                }
            }
        }
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

// MARK: - Preview

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
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
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
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
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
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
