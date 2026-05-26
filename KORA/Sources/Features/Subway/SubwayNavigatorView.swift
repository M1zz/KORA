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
    @State private var showEnglish = false
    @AppStorage("kora.metro.apikey") private var realtimeAPIKey: String = ""
    @State private var segmentTimings: [Int: SegmentTiming] = [:]
    @State private var realtimeArrivals: [Int: [RealtimeArrivalInfo]] = [:]
    @State private var showAPIKeySheet = false
    @State private var completedSegments: Set<Int> = []

    private var displayLanguage: StationLanguage { showEnglish ? .english : .japanese }

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
            segmentTimings = [:]
            realtimeArrivals = [:]
            completedSegments = []
        }
    }

    private var navigatorBody: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                currentStationHeader
                if let j = journey {
                    Divider()
                    journeyScroll(j)
                } else if fromStation != nil && toStation != nil {
                    noRouteView
                } else {
                    destinationFocusBody
                }
            }
            englishToggleFAB
        }
    }

    private var englishToggleFAB: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showEnglish.toggle()
            }
        } label: {
            Text("EN")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(showEnglish ? .white : KORATheme.accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(showEnglish ? KORATheme.accent : Color(.secondarySystemBackground))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(KORATheme.accent.opacity(showEnglish ? 0 : 0.4), lineWidth: 1))
            .shadow(color: KORATheme.accent.opacity(0.2), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.bottom, 24)
        .accessibilityLabel(showEnglish ? "영어 표기 중. 일본어로 전환" : "일본어 표기 중. 영어로 전환")
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
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(MetroLineData.lineColor(num))
                                .clipShape(Circle())
                                .accessibilityLabel("\(num)호선")
                        }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(ja)
                            .font(.system(size: 28, weight: .black))
                            .foregroundStyle(KORATheme.labelPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text(ko)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(KORATheme.labelSecondary)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .semibold))
                        Text("変更")
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundStyle(KORATheme.labelTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Capsule())
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
                    .font(.system(size: 32))
                    .foregroundStyle(KORATheme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("どこに行きますか？")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(KORATheme.labelPrimary)
                    Text("駅をタップして経路を表示")
                        .font(.system(size: 12))
                        .foregroundStyle(KORATheme.labelSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(KORATheme.labelSecondary)
                Text("\(places.count)")
                    .font(.system(size: 11, weight: .bold))
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
                            .font(.system(size: 56, weight: .light))
                            .foregroundStyle(KORATheme.accent)
                    }
                    VStack(spacing: 6) {
                        Text("今いる駅は？")
                            .font(.system(size: 24, weight: .bold))
                            .multilineTextAlignment(.center)
                        Text(locationError != nil ? "GPSが使えない場合は下から駅を選んでください" : "まずは出発駅を教えてください")
                            .font(.system(size: 13))
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
                                .font(.system(size: 15, weight: .semibold))
                            Text("GPSで現在地を取得")
                                .font(.system(size: 16, weight: .semibold))
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
                                .font(.system(size: 14, weight: .semibold))
                            Text("駅を手動で選ぶ")
                                .font(.system(size: 16, weight: .semibold))
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
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 24)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                Text("選んだ駅は次回起動時にも記憶されます")
                    .font(.system(size: 11))
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
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.orange)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("終電まで残り \(w.minutesRemaining) 分")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.orange)
                Text("\(w.line)号線の終電が近づいています")
                    .font(.system(size: 11))
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

    private func journeyScroll(_ j: TransferJourney) -> some View {
        ScrollView {
            VStack(spacing: 14) {
                // Completed segments pinned at top as compact rows
                let doneIndices = j.segments.indices.filter { completedSegments.contains($0) }
                if !doneIndices.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(doneIndices, id: \.self) { idx in
                            completedSegmentRow(seg: j.segments[idx])
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }
                    Divider().padding(.vertical, 4)
                }

                // Active segments
                ForEach(Array(j.segments.enumerated()), id: \.offset) { idx, seg in
                    if !completedSegments.contains(idx) {
                        segmentGroup(idx: idx, seg: seg, j: j)
                            .transition(.asymmetric(
                                insertion: .identity,
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        if idx < j.segments.count - 1 && !completedSegments.contains(idx + 1) {
                            transferCard(
                                at: seg.stations.last ?? "",
                                from: seg.line,
                                to: j.segments[idx + 1].line
                            )
                            .transition(.opacity)
                        }
                    }
                }
                destinationCard(j)
                arrivedButton
                apiKeyButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 40)
            .animation(.easeOut(duration: 0.32), value: completedSegments)
        }
        .task(id: j.id) {
            refreshTimings(journey: j)
            if !realtimeAPIKey.isEmpty {
                await refreshRealtime(journey: j)
            }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled else { break }
                refreshTimings(journey: j)
                if !realtimeAPIKey.isEmpty {
                    await refreshRealtime(journey: j)
                }
            }
        }
    }

    private func completedSegmentRow(seg: JourneySegment) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: 15))

            Text("\(seg.line.number)")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(seg.line.color)
                .clipShape(Circle())

            Text(MetroLineData.displayName(for: seg.stations.first ?? "", language: displayLanguage))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(KORATheme.labelSecondary)

            Image(systemName: "arrow.right")
                .font(.system(size: 10))
                .foregroundStyle(KORATheme.labelTertiary)

            Text(MetroLineData.displayName(for: seg.stations.last ?? "", language: displayLanguage))
                .font(.system(size: 13))
                .foregroundStyle(KORATheme.labelTertiary)
                .lineLimit(1)

            Spacer()

            Text("탑승 완료")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("완료: \(seg.line.number)호선 \(seg.stations.first ?? "")역에서 \(seg.stations.last ?? "")역 구간 탑승 완료")
    }

    // MARK: - Segment Group (swipe-left to complete)

    @ViewBuilder
    private func segmentGroup(idx: Int, seg: JourneySegment, j: TransferJourney) -> some View {
        SwipeToCompleteContainer {
            withAnimation(.easeOut(duration: 0.28)) { _ = completedSegments.insert(idx) }
        } content: {
            VStack(spacing: 14) {
                directionCard(seg)
                timingRow(for: idx, seg: seg)
                if seg.stations.count > 1 {
                    nextStationCard(
                        boardingKo: seg.stations[0],
                        nextKo: seg.stations[1],
                        lineColor: seg.line.color
                    )
                }
            }
        }
        .accessibilityAction(named: "탑승 완료") {
            withAnimation(.easeOut(duration: 0.28)) { _ = completedSegments.insert(idx) }
        }
    }

// MARK: - Swipe container (independent gesture state per card)

private struct SwipeToCompleteContainer<Content: View>: View {
    let onComplete: () -> Void
    @ViewBuilder let content: () -> Content

    @GestureState private var dragX: CGFloat = 0

    private var progress: CGFloat { min(1.0, abs(dragX) / 80.0) }

    var body: some View {
        content()
            .overlay(alignment: .trailing) {
                Label("탑승 완료", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
                    .padding(.trailing, 4)
                    .opacity(Double(progress))
                    .scaleEffect(0.8 + 0.2 * Double(progress))
            }
            .offset(x: dragX)
            .gesture(
                DragGesture(minimumDistance: 15, coordinateSpace: .local)
                    .updating($dragX) { v, state, _ in
                        guard abs(v.translation.width) > abs(v.translation.height) else { return }
                        guard v.translation.width < 0 else { return }
                        state = max(v.translation.width, -110)
                    }
                    .onEnded { v in
                        if v.translation.width < -60 {
                            onComplete()
                        }
                    }
            )
    }
}

    // MARK: - Journey Summary Banner

    private func journeySummaryBanner(_ j: TransferJourney) -> some View {
        let arrival = SubwayScheduleService.estimatedArrival(for: j)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let totalMins = j.segments.reduce(0) { $0 + max(1, $1.stopCount * 2) }
            + j.segments.dropFirst().reduce(0) { $0 + MetroLineData.transferWalkingMinutes(at: $1.stations[0]) }

        return HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("所要時間 約\(totalMins)分")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(KORATheme.labelPrimary)
                if let arr = arrival {
                    Text("到着予定 \(formatter.string(from: arr))")
                        .font(.system(size: 11))
                        .foregroundStyle(KORATheme.labelSecondary)
                }
            }
            Spacer()
            Image(systemName: "clock")
                .font(.system(size: 14))
                .foregroundStyle(KORATheme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(KORATheme.accent.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Timing Row

    @ViewBuilder
    private func timingRow(for idx: Int, seg: JourneySegment) -> some View {
        let timing = segmentTimings[idx]
        let realtime = realtimeArrivals[idx] ?? []
        let lineColor = seg.line.color

        if let rt = realtime.first {
            // Real-time API path: simple pill
            HStack(spacing: 8) {
                Circle().fill(rt.minutesUntilArrival == 0 ? Color.orange : lineColor).frame(width: 8, height: 8)
                if rt.minutesUntilArrival == 0 {
                    Text("まもなく到着").font(.system(size: 12, weight: .semibold)).foregroundStyle(.orange)
                } else if let m = rt.minutesUntilArrival {
                    Text("⚡ \(m)分後到着").font(.system(size: 12, weight: .semibold)).foregroundStyle(lineColor)
                } else {
                    Text("⚡ \(rt.message)").font(.system(size: 12, weight: .semibold)).foregroundStyle(lineColor).lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else if let t = timing {
            TrainApproachCard(
                timing: t,
                boardingStation: seg.stations[0],
                terminus: seg.terminus,
                lineNumber: seg.line.number,
                lineColor: lineColor,
                displayLanguage: displayLanguage
            )
        } else {
            HStack(spacing: 8) {
                ProgressView().scaleEffect(0.7).tint(lineColor)
                Text("スケジュール読込中…").font(.system(size: 11)).foregroundStyle(KORATheme.labelTertiary)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - API Key Button

    private var apiKeyButton: some View {
        Button { showAPIKeySheet = true } label: {
            HStack(spacing: 6) {
                Image(systemName: realtimeAPIKey.isEmpty ? "bolt.slash" : "bolt.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(realtimeAPIKey.isEmpty ? KORATheme.labelTertiary : .orange)
                Text(realtimeAPIKey.isEmpty ? "リアルタイム設定" : "リアルタイム接続中")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(realtimeAPIKey.isEmpty ? KORATheme.labelTertiary : .orange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemBackground))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showAPIKeySheet) { apiKeySheet }
        .accessibilityLabel(realtimeAPIKey.isEmpty ? "실시간 도착 정보 API 키 설정" : "실시간 도착 정보 연결됨. 설정 변경")
    }

    private var apiKeySheet: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("서울 열린데이터광장(data.seoul.go.kr)에서 API 키를 발급받으세요.\n「서울시 지하철 실시간 도착정보」")
                    .font(.system(size: 13))
                    .foregroundStyle(KORATheme.labelSecondary)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 6) {
                    Text("API Key")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(KORATheme.labelSecondary)
                    TextField("API 키를 입력하세요", text: $realtimeAPIKey)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                if !realtimeAPIKey.isEmpty {
                    Button(role: .destructive) {
                        realtimeAPIKey = ""
                    } label: {
                        Text("연결 해제")
                            .font(.system(size: 14))
                    }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("リアルタイム設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { showAPIKeySheet = false }
                }
            }
        }
    }

    // MARK: - Data Loading

    private func refreshTimings(journey: TransferJourney) {
        let now = Date()
        var result: [Int: SegmentTiming] = [:]
        for (idx, seg) in journey.segments.enumerated() {
            result[idx] = SubwayScheduleService.timing(for: seg, at: now)
        }
        segmentTimings = result
    }

    private func refreshRealtime(journey: TransferJourney) async {
        let key = realtimeAPIKey
        guard !key.isEmpty else { return }
        var result: [Int: [RealtimeArrivalInfo]] = [:]
        for (idx, seg) in journey.segments.enumerated() {
            let station = seg.stations[0]
            let lineNum = seg.line.number
            if let arrivals = try? await RealtimeArrivalService.fetch(station: station, lineNumber: lineNum, apiKey: key) {
                result[idx] = arrivals
            }
        }
        realtimeArrivals = result
    }

    /// Direction card: ◯◯行き — which train to board.
    private func directionCard(_ seg: JourneySegment) -> some View {
        let terminusDisplay = MetroLineData.displayName(for: seg.terminus, language: displayLanguage)

        return HStack(spacing: 12) {
            Text("\(seg.line.number)")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(seg.line.color)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                if showEnglish {
                    Text(terminusDisplay)
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(seg.line.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else {
                    Text("\(terminusDisplay)行き")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(seg.line.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Text("\(seg.terminus)行")
                    .font(.system(size: 12))
                    .foregroundStyle(KORATheme.labelSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(seg.line.color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(seg.line.color.opacity(0.25), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(seg.line.number)호선 \(seg.terminus) 방면 열차를 타세요")
        .accessibilityAddTraits(.isHeader)
    }

    /// Next station card — mirrors what's displayed on the train's in-car
    /// info ("current → next"), so the user can verify they're on the right
    /// direction's train at first stop.
    private func nextStationCard(boardingKo: String, nextKo: String, lineColor: Color) -> some View {
        let boardDisplay = MetroLineData.displayName(for: boardingKo, language: displayLanguage)
        let nextDisplay = MetroLineData.displayName(for: nextKo, language: displayLanguage)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 0) {
                VStack(spacing: 3) {
                    Text(boardDisplay)
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(KORATheme.labelPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(boardingKo)
                        .font(.system(size: 12))
                        .foregroundStyle(KORATheme.labelSecondary)
                }
                .frame(maxWidth: .infinity)

                Image(systemName: "arrow.right")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(lineColor)
                    .padding(.horizontal, 10)

                VStack(spacing: 3) {
                    Text(nextDisplay)
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(lineColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(nextKo)
                        .font(.system(size: 12))
                        .foregroundStyle(KORATheme.labelSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(lineColor.opacity(0.4), lineWidth: 1.5)
        )
        .shadow(color: lineColor.opacity(0.12), radius: 6, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("탑승역 \(boardingKo), 다음역 \(nextKo). 열차 방향 확인용.")
    }

    /// Transfer station card — the station where the user switches lines.
    private func transferCard(at station: String, from: SeoulMetroLineInfo, to: SeoulMetroLineInfo) -> some View {
        let stationDisplay = MetroLineData.displayName(for: station, language: displayLanguage)
        let allLines = MetroLineData.linesContaining(station)

        return HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.swap")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(KORATheme.accent)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                if showEnglish {
                    Text("Transfer at \(stationDisplay)")
                        .font(.system(size: 18, weight: .bold))
                } else {
                    Text("\(stationDisplay)で乗換")
                        .font(.system(size: 18, weight: .bold))
                }
                HStack(spacing: 6) {
                    Text(station)
                        .font(.system(size: 12))
                        .foregroundStyle(KORATheme.labelSecondary)
                    HStack(spacing: 3) {
                        ForEach(allLines, id: \.self) { num in
                            Text("\(num)")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 16, height: 16)
                                .background(MetroLineData.lineColor(num))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(16)
        .background(KORATheme.accent.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(station)역에서 \(to.number)호선으로 환승하세요")
    }

    /// Final destination card.
    private func destinationCard(_ j: TransferJourney) -> some View {
        let destKo = j.segments.last?.stations.last ?? ""
        let destDisplay = MetroLineData.displayName(for: destKo, language: displayLanguage)
        let lineColor = j.segments.last?.line.color ?? KORATheme.accent

        return HStack(spacing: 12) {
            Image(systemName: "flag.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(lineColor)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                if showEnglish {
                    Text("Get off at \(destDisplay)")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(lineColor)
                } else {
                    Text("\(destDisplay)で下車")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(lineColor)
                }
                Text(destKo)
                    .font(.system(size: 12))
                    .foregroundStyle(KORATheme.labelSecondary)
            }
            Spacer()
        }
        .padding(16)
        .background(lineColor.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(lineColor.opacity(0.35), lineWidth: 1.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("목적지: \(destKo)역에서 내리세요")
        .accessibilityAddTraits(.isStaticText)
    }

    private var arrivedButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                toStation = nil
                completedSegments = []
                selectedJourneyIdx = 0
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 14, weight: .semibold))
                Text("도착했습니다")
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .foregroundStyle(KORATheme.labelSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("목적지 도착. 탭하면 목적지가 초기화됩니다.")
    }

    // MARK: Saved-place rows

    private func atStationRow(_ place: Place) -> some View {
        HStack(spacing: 12) {
            Image(systemName: place.category.systemImage)
                .font(.system(size: 14))
                .foregroundStyle(KORATheme.categoryColor(place.category))
                .frame(width: 32, height: 32)
                .background(KORATheme.categoryColor(place.category).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(place.nameJP)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                Text(place.name)
                    .font(.system(size: 11))
                    .foregroundStyle(KORATheme.labelSecondary)
                    .lineLimit(1)
            }
            Spacer()

            Text("徒歩で到着")
                .font(.system(size: 11, weight: .semibold))
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
                    .font(.system(size: 14))
                    .foregroundStyle(KORATheme.categoryColor(place.category))
                    .frame(width: 32, height: 32)
                    .background(KORATheme.categoryColor(place.category).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(place.nameJP)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(KORATheme.labelPrimary)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "tram.fill")
                            .font(.system(size: 9))
                        if showEnglish {
                            Text(MetroLineData.displayName(for: place.nearestStation, language: .english))
                        } else {
                            Text(MetroLineData.displayName(for: place.nearestStation, language: .japanese))
                                + Text("駅")
                        }
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(KORATheme.labelSecondary)
                    .lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 22))
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
                .font(.system(size: 44))
                .foregroundStyle(KORATheme.labelSecondary.opacity(0.25))
            VStack(spacing: 4) {
                Text("経路が見つかりません")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(KORATheme.labelSecondary)
                Text("最大2回までの乗換で到達できる経路がありません")
                    .font(.system(size: 12))
                    .foregroundStyle(KORATheme.labelSecondary.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Button {
                toStation = nil
                selectedJourneyIdx = 0
            } label: {
                Text("別の目的地を選ぶ")
                    .font(.system(size: 13, weight: .semibold))
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
                                .font(.system(size: 13, weight: .bold))
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
                            .font(.system(size: 9, weight: isBoarding ? .semibold : .regular))
                            .foregroundStyle(isBoarding ? KORATheme.labelPrimary : KORATheme.labelTertiary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                        Text(isBoarding ? "乗車" : "\(stopsAway)前")
                            .font(.system(size: 8))
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
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(KORATheme.labelTertiary)
                            .accessibilityHidden(true)
                        Text("発車待ち")
                            .font(.system(size: 10))
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
                        .font(.system(size: 38, weight: .black, design: .monospaced))
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
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(KORATheme.accent)
                                Text("\(group.stations.count)")
                                    .font(.system(size: 10, weight: .semibold))
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
                        .font(.system(size: 11, weight: .bold))
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
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
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
                Text("\(line.number)")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(isSelected ? line.color : .white)
                    .frame(width: 20, height: 20)
                    .background(isSelected ? Color.white : line.color)
                    .clipShape(Circle())
                Text("号線")
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
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
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(KORATheme.labelPrimary)
                HStack(spacing: 5) {
                    Text(station)
                        .font(.system(size: 12))
                        .foregroundStyle(KORATheme.labelSecondary)
                    if !enName.isEmpty {
                        Text("· \(enName)")
                            .font(.system(size: 11))
                            .foregroundStyle(KORATheme.labelTertiary)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            HStack(spacing: 3) {
                ForEach(linesForStation(station), id: \.self) { num in
                    Text("\(num)")
                        .font(.system(size: 9, weight: .bold))
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
                .font(.system(size: 36))
                .foregroundStyle(KORATheme.labelSecondary.opacity(0.4))
            Text("該当する駅が見つかりません")
                .font(.system(size: 14))
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

#Preview {
    SubwayNavigatorView()
}
