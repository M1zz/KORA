import SwiftUI

// MARK: - Navigator View

struct SubwayNavigatorView: View {
    @AppStorage("kora.current_station") private var persistedFromStation: String = ""
    @State private var fromStation: String? = nil
    @State private var toStation: String? = nil
    @State private var showFromPicker = false
    @State private var showToPicker = false
    @State private var selectedJourneyIdx = 0

    // Location detection
    @State private var isLocating = false
    @State private var locationError: String? = nil
    @State private var didAutoLocate = false
    private let locationService = LocationService()
    private let kakao = KakaoLocalService()

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
            } else {
                navigatorBody
            }
        }
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
            consumePendingDestination()
        }
        .onChange(of: fromStation) { _, new in
            persistedFromStation = new ?? ""
        }
        .onChange(of: coordinator.routeRequestNonce) { _, _ in consumePendingDestination() }
    }

    private var navigatorBody: some View {
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
    }

    // MARK: Current-station header (top of screen, line-colored)

    /// Top-of-screen current station card. Shows the line color stripe(s) for
    /// transfer stations, a large Japanese station name, the Korean subtitle,
    /// and tap-anywhere-to-change affordance. This is the user's anchor point
    /// — the source for every route they build below.
    private var currentStationHeader: some View {
        let ko = fromStation ?? ""
        let ja = MetroLineData.displayName(for: ko, language: .japanese)
        let lines = MetroLineData.linesContaining(ko)
        let primaryColor = lines.first.map { MetroLineData.lineColor($0) } ?? KORATheme.accent

        return VStack(spacing: 0) {
            // Line color stripe (segmented for transfer stations)
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

            Button {
                showFromPicker = true
            } label: {
                HStack(alignment: .center, spacing: 14) {
                    // Line badge(s)
                    VStack(spacing: 4) {
                        ForEach(lines, id: \.self) { num in
                            Text("\(num)")
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(MetroLineData.lineColor(num))
                                .clipShape(Circle())
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
                colors: [
                    KORATheme.accent.opacity(0.12),
                    Color(.systemBackground)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 18) {
                    welcomeIcon
                    VStack(spacing: 6) {
                        Text(LocalizedStringKey(welcomeTitle))
                            .font(.system(size: 24, weight: .bold))
                            .multilineTextAlignment(.center)
                        Text(LocalizedStringKey(welcomeSubtitle))
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
                            if isLocating {
                                ProgressView().tint(.white).scaleEffect(0.8)
                            } else {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            Text(isLocating ? "現在地を検索中…" : "もう一度GPSで取得")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(KORATheme.accent)
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
                            Text("🚉 駅を手動で選ぶ")
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
        .onAppear { autoLocateIfNeeded() }
    }

    private var welcomeIcon: some View {
        ZStack {
            Circle()
                .fill(KORATheme.accent.opacity(0.12))
                .frame(width: 120, height: 120)
            Image(systemName: isLocating ? "location.fill.viewfinder" : "location.viewfinder")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(KORATheme.accent)
                .symbolEffect(.pulse, options: .repeating, isActive: isLocating)
        }
    }

    private var welcomeTitle: String {
        if isLocating { return "現在地を検索中…" }
        return "今いる駅は？"
    }

    private var welcomeSubtitle: String {
        if isLocating { return "GPSと地下鉄DBから最寄り駅を割り出しています" }
        if locationError != nil { return "GPSが使えない場合は下のボタンから検索してください" }
        return "まずは出発駅を教えてください"
    }

    /// On first appearance of the welcome gate, trigger location detection
    /// automatically so the user doesn't have to tap anything. Re-tries on
    /// later appearances only when the user has manually reset.
    private func autoLocateIfNeeded() {
        guard !didAutoLocate, !isLocating else { return }
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
            let coord = try await locationService.requestOnce()

            // 1. Try local hardcoded coordinates first (works offline, instant).
            if let local = MetroLineData.nearestStation(
                latitude: coord.latitude,
                longitude: coord.longitude
            ) {
                fromStation = local.name
                selectedJourneyIdx = 0
                return
            }

            // 2. Fall back to Kakao SW8 search for areas outside our local table
            //    (e.g. brand-new stations, or user far outside Seoul region).
            if let doc = try await kakao.searchNearestSubway(
                latitude: coord.latitude,
                longitude: coord.longitude
            ) {
                fromStation = SaveViewModel.normalizeStationName(doc.placeName)
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
                ForEach(Array(j.segments.enumerated()), id: \.offset) { idx, seg in
                    directionCard(seg)
                    if seg.stations.count > 1 {
                        nextStationCard(
                            boardingKo: seg.stations[0],
                            nextKo: seg.stations[1],
                            lineColor: seg.line.color
                        )
                    }
                    if idx < j.segments.count - 1 {
                        transferCard(
                            at: seg.stations.last ?? "",
                            from: seg.line,
                            to: j.segments[idx + 1].line
                        )
                    }
                }
                destinationCard(j)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
    }

    /// Direction card: ◯◯行き — which train to board.
    private func directionCard(_ seg: JourneySegment) -> some View {
        let terminusJa = MetroLineData.displayName(for: seg.terminus, language: .japanese)

        return HStack(spacing: 12) {
            Text("\(seg.line.number)")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(seg.line.color)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text("\(terminusJa)行き")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(seg.line.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
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
    }

    /// Next station card — mirrors what's displayed on the train's in-car
    /// info ("current → next"), so the user can verify they're on the right
    /// direction's train at first stop.
    private func nextStationCard(boardingKo: String, nextKo: String, lineColor: Color) -> some View {
        let boardJa = MetroLineData.displayName(for: boardingKo, language: .japanese)
        let nextJa = MetroLineData.displayName(for: nextKo, language: .japanese)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "rectangle.split.1x2.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(KORATheme.labelTertiary)
                Text("車内表示")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(KORATheme.labelSecondary)
                Spacer()
            }

            HStack(spacing: 0) {
                VStack(spacing: 3) {
                    Text(boardJa)
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
                    Text(nextJa)
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
    }

    /// Transfer station card — the station where the user switches lines.
    private func transferCard(at station: String, from: SeoulMetroLineInfo, to: SeoulMetroLineInfo) -> some View {
        let stationJa = MetroLineData.displayName(for: station, language: .japanese)
        let allLines = MetroLineData.linesContaining(station)

        return HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.swap")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(KORATheme.accent)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("\(stationJa)で乗換")
                    .font(.system(size: 18, weight: .bold))
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
    }

    /// Final destination card.
    private func destinationCard(_ j: TransferJourney) -> some View {
        let destKo = j.segments.last?.stations.last ?? ""
        let destJa = MetroLineData.displayName(for: destKo, language: .japanese)
        let lineColor = j.segments.last?.line.color ?? KORATheme.accent

        return HStack(spacing: 12) {
            Image(systemName: "flag.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(lineColor)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("\(destJa)で下車")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(lineColor)
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
                        Text(MetroLineData.displayName(for: place.nearestStation, language: .japanese))
                            + Text("駅")
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
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(MetroLineData.displayName(for: station, language: .japanese))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(KORATheme.labelPrimary)
                Text(station)
                    .font(.system(size: 12))
                    .foregroundStyle(KORATheme.labelSecondary)
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
