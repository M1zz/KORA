import SwiftUI
import CoreLocation

// MARK: - Navigator View

struct SubwayNavigatorView: View {
    @AppStorage("kora.current_station") private var persistedFromStation: String = ""
    @AppStorage("kora.destination_station") private var persistedToStation: String = ""
    @State private var fromStation: String? = nil
    @State private var toStation: String? = nil
    @State private var showFromPicker = false
    @State private var showToPicker = false
    @State private var selectedJourneyIdx = 0
    /// "" = auto-detect from system locale; otherwise StationLanguage.rawValue
    @AppStorage("kora.display_language") private var languagePref: String = ""
    /// Index of the current "ride block" (= one subway segment). Increments by 1
    /// every time the user confirms they've boarded a train. When equal to
    /// `journey.segments.count`, the journey is finished.
    @State private var currentBlockIdx: Int = 0

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
            StationSearchSheet(title: "現在地 / 현재 역", excluding: toStation) {
                fromStation = $0
                selectedJourneyIdx = 0
            }
        }
        .sheet(isPresented: $showToPicker) {
            StationSearchSheet(title: "目的地 / 목적지", excluding: fromStation) {
                toStation = $0
                selectedJourneyIdx = 0
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
        }
        .toolbar { languageToolbar }
    }

    // MARK: - Boarding state machine (one tap = one segment)

    /// Advance to the next ride block when the user confirms they've boarded
    /// the current train. After the last segment's tap, the journey is done.
    private func advanceBoarding(in j: TransferJourney) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            if currentBlockIdx >= j.segments.count {
                // Finished — tap = reset for a re-do.
                currentBlockIdx = 0
                resetJourney()
            } else {
                currentBlockIdx += 1
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
                    currentStationHeader
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
                resetRow
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

    /// Subtle reset row at the very top.
    private var resetRow: some View {
        HStack {
            Spacer()
            Button {
                resetJourney()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(KORATheme.labelTertiary)
            }
            .accessibilityLabel("경로 초기화")
        }
    }

    // MARK: One ride block

    /// Self-contained block for ONE subway ride: direction + next station +
    /// where to get off (with transfer hint or destination indicator).
    private func rideBlock(seg: JourneySegment, isLast: Bool) -> some View {
        let terminusDisplay = MetroLineData.displayName(for: seg.terminus, language: displayLanguage)
        let boardingKo = seg.stations.first ?? ""
        let boardingDisplay = MetroLineData.displayName(for: boardingKo, language: displayLanguage)
        let alightKo = seg.stations.last ?? ""
        let alightDisplay = MetroLineData.displayName(for: alightKo, language: displayLanguage)
        let nextKo: String? = seg.stations.count > 1 ? seg.stations[1] : nil
        let nextDisplay = nextKo.map { MetroLineData.displayName(for: $0, language: displayLanguage) } ?? ""
        let timing = SubwayScheduleService.timing(for: seg, at: Date())
        let alightLineColor = seg.line.color
        let nextLines = MetroLineData.linesContaining(alightKo)

        return VStack(spacing: 18) {
            // Direction header — which train
            HStack(spacing: 14) {
                Text(seg.line.badgeText)
                    .font(.largeTitle).fontWeight(.black)
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(seg.line.color)
                    .clipShape(Circle())
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                VStack(alignment: .leading, spacing: 4) {
                    Text(directionLabel(terminus: seg.terminus))
                        .font(.largeTitle).fontWeight(.black)
                        .foregroundStyle(seg.line.color)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                    // Secondary line: always show Korean Hangul so the user
                    // can match the platform signage in any UI language.
                    if displayLanguage != .korean {
                        Text("\(seg.terminus)행")
                            .font(.title3)
                            .foregroundStyle(KORATheme.labelSecondary)
                    }
                }
                Spacer()
            }

            Divider()

            // In-car display verification — boarding → next stop
            if let nk = nextKo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("車内表示で確認")
                        .font(.body).fontWeight(.semibold)
                        .foregroundStyle(KORATheme.labelSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 0) {
                        VStack(spacing: 2) {
                            Text(boardingDisplay)
                                .font(.title2).fontWeight(.bold)
                                .lineLimit(1).minimumScaleFactor(0.6)
                            Text(boardingKo)
                                .font(.body)
                                .foregroundStyle(KORATheme.labelSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        Image(systemName: "arrow.right")
                            .font(.title2).fontWeight(.black)
                            .foregroundStyle(seg.line.color)
                            .padding(.horizontal, 8)
                        VStack(spacing: 2) {
                            Text(nextDisplay)
                                .font(.title2).fontWeight(.bold)
                                .foregroundStyle(seg.line.color)
                                .lineLimit(1).minimumScaleFactor(0.6)
                            Text(nk)
                                .font(.body)
                                .foregroundStyle(KORATheme.labelSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                Divider()
            }

            // Where to get off — transfer station or destination
            HStack(spacing: 12) {
                Image(systemName: isLast ? "flag.checkered" : "arrow.triangle.swap")
                    .font(.title2).fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(isLast ? alightLineColor : KORATheme.accent)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(isLast ? "降りる駅" : "乗換駅で下車")
                        .font(.body).fontWeight(.semibold)
                        .foregroundStyle(KORATheme.labelSecondary)
                    Text(alightDisplay)
                        .font(.title2).fontWeight(.black)
                        .foregroundStyle(KORATheme.labelPrimary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    HStack(spacing: 6) {
                        Text(alightKo)
                            .font(.body)
                            .foregroundStyle(KORATheme.labelSecondary)
                        // Show all line dots for transfer stations
                        if !isLast && nextLines.count > 1 {
                            HStack(spacing: 3) {
                                ForEach(nextLines, id: \.self) { num in
                                    Text("\(num)")
                                        .font(.body).fontWeight(.black)
                                        .foregroundStyle(.white)
                                        .frame(width: 18, height: 18)
                                        .background(MetroLineData.lineColor(num))
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                }
                Spacer()
            }

            trainApproachVisual(seg: seg, timing: timing)
        }
        .padding(20)
        .background(seg.line.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(seg.line.color.opacity(0.25), lineWidth: 1.2))
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

            Text("到着!")
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
            Text(LocalizedStringKey("電車の現在位置"))
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
                    Text("まもなく到着")
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(.orange)
                } else if m == 1 {
                    Text("約1分後")
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(.orange)
                } else {
                    Text("約\(m)分後")
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(lineColor)
                }
                Text("次の電車")
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
                Text("最初からもう一度")
                    .font(.title3).fontWeight(.bold)
                    .foregroundStyle(.white)
                Spacer()
            }
        } else {
            let seg = j.segments[currentBlockIdx]
            let terminus = MetroLineData.displayName(for: seg.terminus, language: displayLanguage)
            HStack(spacing: 12) {
                Image(systemName: "tram.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("乗車しましたか？")
                        .font(.body).fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("\(terminus)行きに乗ったらタップ")
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }

    // MARK: - Language picker (toolbar)

    /// Apple-standard Menu on the navigation bar's trailing edge. Tap to
    /// choose between 한국어 / 日本語 / English / 中文 — or "Auto" to follow
    /// the system locale.
    @ToolbarContentBuilder
    var languageToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Picker("Language", selection: $languagePref) {
                    Label("Auto (\(StationLanguage.resolveFromSystemLocale().displayName))", systemImage: "sparkles")
                        .tag("")
                    ForEach(StationLanguage.allCases, id: \.self) { lang in
                        Text(lang.displayName).tag(lang.rawValue)
                    }
                }
            } label: {
                Image(systemName: "globe")
                    .accessibilityLabel("Display language: \(displayLanguage.displayName)")
            }
        }
    }

    // MARK: Current-station header (top of screen, line-colored)

    /// Top-of-screen current station card. Shows the line color stripe(s) for
    /// transfer stations, a large Japanese station name, the Korean subtitle,
    /// and tap-anywhere-to-change affordance. This is the user's anchor point
    /// — the source for every route they build below.
    private var currentStationHeader: some View {
        let ko = fromStation ?? ""
        let ja = MetroLineData.displayName(for: ko, language: displayLanguage)
        let lines = MetroLineData.linesContaining(ko)
        let primaryColor = lines.first.map { MetroLineData.lineColor($0) } ?? KORATheme.accent

        let lineNames = lines.map { "\($0)호선" }.joined(separator: ", ")
        let headerLabel = lines.isEmpty
            ? "\(ko)역. 현재역 변경하려면 탭하세요."
            : "\(ko)역, \(lineNames). 현재역 변경하려면 탭하세요."

        return VStack(spacing: 0) {
            // Decorative color stripe — hidden from VoiceOver
            HStack(spacing: 0) {
                if lines.isEmpty {
                    Rectangle().fill(KORATheme.accent).frame(height: 6)
                } else {
                    ForEach(lines, id: \.self) { num in
                        Rectangle()
                            .fill(MetroLineData.lineColor(num))
                            .frame(height: 6)
                    }
                }
            }
            .accessibilityHidden(true)

            Button {
                showFromPicker = true
            } label: {
                HStack(alignment: .center, spacing: 14) {
                    VStack(spacing: 4) {
                        ForEach(lines, id: \.self) { num in
                            Text("\(num)")
                                .font(.body).fontWeight(.black)
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(MetroLineData.lineColor(num))
                                .clipShape(Circle())
                                .accessibilityLabel("\(num)호선")
                        }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(ja)
                            .font(.title).fontWeight(.black)
                            .foregroundStyle(KORATheme.labelPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text(ko)
                            .font(.body).fontWeight(.medium)
                            .foregroundStyle(KORATheme.labelSecondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(primaryColor.opacity(0.08))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(headerLabel)
        }
    }

    // MARK: Destination-focused body (no journey yet)

    /// Big destination CTA when no destination is set, plus saved-place
    /// quick routes below. Replaces the old fromOnlyView/emptyStateView split.
    private var destinationFocusBody: some View {
        ScrollView {
            VStack(spacing: 16) {
                destinationCTA

                if !savedPlacesAtFromStation.isEmpty {
                    savedSection(
                        title: "この駅にあるスポット",
                        places: savedPlacesAtFromStation,
                        atStation: true
                    )
                }

                if !savedPlacesNearby.isEmpty {
                    savedSection(
                        title: "保存スポットへ行く",
                        places: savedPlacesNearby,
                        atStation: false
                    )
                }
            }
            .padding(16)
            .padding(.bottom, 32)
        }
    }

    private var destinationCTA: some View {
        Button {
            showToPicker = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(KORATheme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("どこに行きますか？")
                        .font(.title3).fontWeight(.bold)
                        .foregroundStyle(KORATheme.labelPrimary)
                    Text("駅をタップして経路を表示")
                        .font(.body)
                        .foregroundStyle(KORATheme.labelSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.body).fontWeight(.bold)
                    .foregroundStyle(KORATheme.accent.opacity(0.5))
            }
            .padding(20)
            .background(KORATheme.accent.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(KORATheme.accent.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
                        Text("今いる駅は？")
                            .font(.title).fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        Text(locationError != nil ? "GPSが使えない場合は下から駅を選んでください" : "まずは出発駅を教えてください")
                            .font(.body)
                            .foregroundStyle(KORATheme.labelSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                VStack(spacing: 12) {
                    Button {
                        Task { await detectCurrentStation() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.body).fontWeight(.semibold)
                            Text("GPSで現在地を取得")
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
                            Text("駅を手動で選ぶ")
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

                Text("選んだ駅は次回起動時にも記憶されます")
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
                Text("終電まで残り \(w.minutesRemaining) 分")
                    .font(.body).fontWeight(.bold)
                    .foregroundStyle(.orange)
                Text("\(w.line)号線の終電が近づいています")
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

            locationError = String(localized: "近くに駅が見つかりませんでした")
        } catch let e as LocationService.LocationError {
            locationError = e.errorDescription
        } catch {
            locationError = String(localized: "現在地の取得に失敗しました")
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
                    .lineLimit(1)
                Text(place.name)
                    .font(.body)
                    .foregroundStyle(KORATheme.labelSecondary)
                    .lineLimit(1)
            }
            Spacer()

            Text("徒歩で到着")
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
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "tram.fill")
                            .font(.body)
                        Text(MetroLineData.displayName(for: place.nearestStation, language: displayLanguage))
                    }
                    .font(.body)
                    .foregroundStyle(KORATheme.labelSecondary)
                    .lineLimit(1)
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
                Text("経路が見つかりません")
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(KORATheme.labelSecondary)
                Text("最大2回までの乗換で到達できる経路がありません")
                    .font(.body)
                    .foregroundStyle(KORATheme.labelSecondary.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Button {
                toStation = nil
                selectedJourneyIdx = 0
            } label: {
                Text("別の目的地を選ぶ")
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
                        Text(isBoarding ? "乗車" : "\(stopsAway)前")
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
                        Text("発車待ち")
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
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selectedLineNumber: Int? = nil

    private let allLines = MetroLineData.seoulLines

    // Stations on the selected line, sorted by katakana for consistent gojuon
    // ordering with the all-lines mode. Deduped across line branches.
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
            MetroLineData.displayName(for: a, language: .japanese)
                < MetroLineData.displayName(for: b, language: .japanese)
        }
    }

    private var filtered: [String] {
        let q = query.trimmingCharacters(in: .whitespaces)
        let base = (selectedLineNumber == nil
                    ? MetroLineData.allStationNames
                    : stationsOnSelectedLine)
            .filter { $0 != excluding }
        guard !q.isEmpty else { return base }
        return base.filter { s in
            s.contains(q)
                || MetroLineData.displayName(for: s, language: .japanese).contains(q)
                || MetroLineData.displayName(for: s, language: .english).lowercased().contains(q.lowercased())
        }
    }

    /// True when the list should be grouped under gojuon (kana) section
    /// headers. Applied whenever the search box is empty — both all-lines
    /// and line-selected modes share the same katakana ordering for
    /// predictability.
    private var shouldUseKanaSections: Bool {
        query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var kanaSections: [(key: String, stations: [String])] {
        var dict: [String: [String]] = [:]
        for s in filtered {
            let key = MetroLineData.kanaInitial(for: s)
            dict[key, default: []].append(s)
        }
        return MetroLineData.kanaIndexOrder.compactMap { key in
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
                } else if shouldUseKanaSections {
                    sectionedListView
                } else {
                    flatListView
                }
            }
            .searchable(text: $query, prompt: "역 이름 (한국어 · 日本語 · English)")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
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
        let sections = kanaSections
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
                                Text(group.key + "行")
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
            Text("全路線")
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
                Text(line.code != nil ? line.name : "号線")
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
        let enName = MetroLineData.displayName(for: station, language: .english)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(MetroLineData.displayName(for: station, language: .japanese))
                    .font(.body).fontWeight(.medium)
                    .foregroundStyle(KORATheme.labelPrimary)
                HStack(spacing: 5) {
                    Text(station)
                        .font(.body)
                        .foregroundStyle(KORATheme.labelSecondary)
                    if !enName.isEmpty {
                        Text("· \(enName)")
                            .font(.body)
                            .foregroundStyle(KORATheme.labelTertiary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            HStack(spacing: 3) {
                ForEach(linesForStation(station), id: \.self) { num in
                    Text("\(num)")
                        .font(.body).fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(MetroLineData.lineColor(num))
                        .clipShape(Circle())
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
            Text("該当する駅が見つかりません")
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
