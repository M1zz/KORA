import SwiftUI
import PhotosUI
import Vision

// MARK: - Localized strings for Save section

private enum SaveLoc {
    static func listTab(_ l: StationLanguage) -> String {
        switch l { case .korean: return "목록"; case .japanese: return "リスト"; case .english: return "List"; case .chinese: return "列表" }
    }
    static func mapTab(_ l: StationLanguage) -> String {
        switch l { case .korean: return "지도"; case .japanese: return "マップ"; case .english: return "Map"; case .chinese: return "地图" }
    }
    static func navTitle(_ l: StationLanguage) -> String {
        switch l { case .korean: return "가고 싶은"; case .japanese: return "行きたい"; case .english: return "Saved"; case .chinese: return "想去的" }
    }
    static func linkFound(_ l: StationLanguage) -> String {
        switch l { case .korean: return "링크를 찾았습니다"; case .japanese: return "リンクが見つかりました"; case .english: return "Link found"; case .chinese: return "找到链接" }
    }
    static func cancel(_ l: StationLanguage) -> String {
        switch l { case .korean: return "취소"; case .japanese: return "キャンセル"; case .english: return "Cancel"; case .chinese: return "取消" }
    }
    static func add(_ l: StationLanguage) -> String {
        switch l { case .korean: return "추가"; case .japanese: return "追加"; case .english: return "Add"; case .chinese: return "添加" }
    }
    static func allFilter(_ l: StationLanguage) -> String {
        switch l { case .korean: return "전체"; case .japanese: return "すべて"; case .english: return "All"; case .chinese: return "全部" }
    }
    static func emptyTitle(_ l: StationLanguage) -> String {
        switch l { case .korean: return "가고 싶은 장소를 모아보세요"; case .japanese: return "行きたいスポットを集めよう"; case .english: return "Start collecting places"; case .chinese: return "收集想去的地方" }
    }
    static func emptySubtitle(_ l: StationLanguage) -> String {
        switch l { case .korean: return "장소명으로 검색하거나\nURL을 붙여넣어 추가할 수 있어요"; case .japanese: return "場所名で検索するか\nURLを貼り付けて追加できます"; case .english: return "Search by name or paste\na URL to add a place"; case .chinese: return "搜索地点名称或粘贴URL来添加" }
    }
    static func pasteURL(_ l: StationLanguage) -> String {
        switch l { case .korean: return "장소 추가하기"; case .japanese: return "スポットを追加"; case .english: return "Add a Place"; case .chinese: return "添加地点" }
    }
    static func delete(_ l: StationLanguage) -> String {
        switch l { case .korean: return "삭제"; case .japanese: return "削除"; case .english: return "Delete"; case .chinese: return "删除" }
    }
    static func loading(_ l: StationLanguage) -> String {
        switch l { case .korean: return "장소 정보 가져오는 중..."; case .japanese: return "スポット情報を取得中..."; case .english: return "Loading place info..."; case .chinese: return "正在获取地点信息..." }
    }
    static func instagramHint(_ l: StationLanguage) -> String {
        switch l {
        case .korean:   return "링크를 저장했어요.\n장소명으로 검색해서 저장할 장소를 찾아주세요."
        case .japanese: return "リンクを保存しました。\n場所名で検索して保存するスポットを探してください。"
        case .english:  return "Link saved.\nSearch by place name to find the spot."
        case .chinese:  return "已保存链接。\n请用地点名称搜索要保存的地点。"
        }
    }
    static func placeName(_ l: StationLanguage) -> String {
        switch l { case .korean: return "장소명 검색"; case .japanese: return "場所名で検索"; case .english: return "Search place name"; case .chinese: return "搜索地点名称" }
    }
    static func quickSave(_ l: StationLanguage) -> String {
        switch l { case .korean: return "링크만 저장"; case .japanese: return "リンクだけ保存"; case .english: return "Save link only"; case .chinese: return "仅保存链接" }
    }
    static func searchPlace(_ l: StationLanguage) -> String {
        switch l { case .korean: return "장소 검색"; case .japanese: return "場所を検索"; case .english: return "Search Place"; case .chinese: return "搜索地点" }
    }
    static func openLink(_ l: StationLanguage) -> String {
        switch l { case .korean: return "링크 열기"; case .japanese: return "リンクを開く"; case .english: return "Open link"; case .chinese: return "打开链接" }
    }
    static func addSheetTitle(_ l: StationLanguage) -> String {
        switch l { case .korean: return "장소 추가"; case .japanese: return "スポットを追加"; case .english: return "Add Place"; case .chinese: return "添加地点" }
    }
    static func close(_ l: StationLanguage) -> String {
        switch l { case .korean: return "닫기"; case .japanese: return "閉じる"; case .english: return "Close"; case .chinese: return "关闭" }
    }
    static func searchByKeyword(_ l: StationLanguage) -> String {
        switch l { case .korean: return "키워드로 장소 검색"; case .japanese: return "キーワードで場所を検索"; case .english: return "Search by keyword"; case .chinese: return "用关键词搜索" }
    }
    static func searchPlaceholder(_ l: StationLanguage) -> String {
        switch l { case .korean: return "성심당, 홍대 카페..."; case .japanese: return "城心堂、弘大カフェ..."; case .english: return "Sungsimdang, Hongdae cafe..."; case .chinese: return "圣心堂、弘大咖啡..." }
    }
    static func placeInfoFetched(_ l: StationLanguage) -> String {
        switch l { case .korean: return "장소 정보를 가져왔습니다!"; case .japanese: return "スポット情報を取得しました！"; case .english: return "Place info retrieved!"; case .chinese: return "已获取地点信息！" }
    }
    static func saveToList(_ l: StationLanguage) -> String {
        switch l { case .korean: return "목록에 저장하기"; case .japanese: return "リストに保存する"; case .english: return "Save to list"; case .chinese: return "保存到列表" }
    }
    static func checkPlace(_ l: StationLanguage) -> String {
        switch l { case .korean: return "장소 확인"; case .japanese: return "スポットを確認"; case .english: return "Confirm Place"; case .chinese: return "确认地点" }
    }
    static func noResults(_ l: StationLanguage) -> String {
        switch l { case .korean: return "검색 결과가 없습니다"; case .japanese: return "検索結果がありません"; case .english: return "No results found"; case .chinese: return "没有搜索结果" }
    }
    static func searchResults(_ l: StationLanguage) -> String {
        switch l { case .korean: return "검색 결과"; case .japanese: return "検索結果"; case .english: return "Search Results"; case .chinese: return "搜索结果" }
    }
}

// MARK: - SaveView

struct SaveView: View {
    @State private var viewModel = SaveViewModel()
    @State private var selectedCategory: PlaceCategory? = nil
    @State private var showAddSheet: Bool = false
    @State private var showMap: Bool = false
    @State private var selectedMapPlace: Place? = nil
    @State private var listSearchText: String = ""
    @State private var editingPlace: Place? = nil
    @State private var detailPlace: Place? = nil
    @State private var coordinator = NavigationCoordinator.shared

    @AppStorage("kora.display_language") private var languagePref: String = ""

    private var lang: StationLanguage {
        guard !languagePref.isEmpty, let e = StationLanguage(rawValue: languagePref)
        else { return StationLanguage.resolveFromSystemLocale() }
        return e
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 0) {
                            if viewModel.showClipboardPrompt {
                                clipboardBanner
                                    .padding(.horizontal)
                                    .padding(.top, 12)
                                    .padding(.bottom, 4)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                            listHeader
                            placesSection
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                    }
                    .background(Color(UIColor.systemGroupedBackground))
                }

                if !viewModel.showClipboardPrompt {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2).fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(KORATheme.accent)
                            .clipShape(Circle())
                            .shadow(color: KORATheme.accent.opacity(0.4), radius: 8, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 28)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .navigationDestination(isPresented: $showMap) {
                PlaceMapView(
                    places: viewModel.places(for: selectedCategory),
                    selectedPlace: $selectedMapPlace,
                    onSaveDoc: { doc in viewModel.saveFromKakao(doc) }
                )
                .navigationTitle(mapTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.visible, for: .navigationBar)
                .ignoresSafeArea(edges: .bottom)
            }
            .sheet(item: $viewModel.parsedPlace) { place in
                ParsedPlaceSheet(place: place) {
                    viewModel.confirmSave()
                } onDismiss: {
                    viewModel.dismissParsed()
                }
            }
            .sheet(isPresented: $viewModel.showSearchResults) {
                KakaoSearchResultsSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showAddSheet) {
                AddPlaceSheet(viewModel: viewModel)
            }
            .sheet(item: $editingPlace) { place in
                EditPlaceSheet(place: place, lang: lang, viewModel: viewModel)
            }
            .sheet(item: $detailPlace) { place in
                PlaceDetailSheet(
                    place: place,
                    lang: lang,
                    onUpdate: { updated in viewModel.update(updated) },
                    onRoute: { p in
                        guard !p.nearestStation.isEmpty else { return }
                        NavigationCoordinator.shared.routeTo(station: p.nearestStation)
                    }
                )
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                viewModel.checkClipboard()
                consumePendingShare()
            }
            .onChange(of: coordinator.shareRequestNonce) { _, _ in
                consumePendingShare()
            }
            .onChange(of: viewModel.showManualNamePrompt) { _, shown in
                if shown { showAddSheet = true }
            }
        }
        .animation(.spring(response: 0.25), value: viewModel.showClipboardPrompt)
    }

    private var listHeader: some View {
        HStack(alignment: .center) {
            Text(lang == .japanese ? "行きたい" : lang == .english ? "Saved" : lang == .chinese ? "想去的" : "가고 싶은")
                .font(.title2).fontWeight(.bold)
                .foregroundStyle(KORATheme.labelPrimary)
            Spacer()
            Button {
                showMap = true
            } label: {
                Image(systemName: "map")
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(KORATheme.accent)
                    .padding(9)
                    .background(KORATheme.accent.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var mapTitle: String {
        switch lang {
        case .korean:   return "지도"
        case .japanese: return "マップ"
        case .english:  return "Map"
        case .chinese:  return "地图"
        }
    }

    private func consumePendingShare() {
        let url = coordinator.pendingShareURL ?? ""
        let sharedText = coordinator.pendingShareText
        guard !url.isEmpty || (sharedText != nil && !sharedText!.isEmpty) else { return }
        coordinator.clearShare()

        // Caption text from extension → show as suggestion chips in the name prompt
        if let caption = sharedText, !caption.isEmpty {
            viewModel.pendingCaptionText = caption
        }

        if url.isEmpty {
            // No URL extracted (Instagram didn't pass one) — go straight to
            // manual name entry using the caption as suggestions.
            viewModel.showManualNamePrompt = true
            showAddSheet = true
        } else {
            viewModel.urlInput = url
            Task { await viewModel.parseURL() }
        }
    }

    // MARK: - Clipboard Banner

    private var clipboardBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "link.circle.fill")
                    .font(.title2)
                    .foregroundStyle(KORATheme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(SaveLoc.linkFound(lang))
                        .font(.body).fontWeight(.semibold)
                        .foregroundStyle(KORATheme.labelPrimary)
                    if let url = viewModel.clipboardURL {
                        Text(url)
                            .font(.body)
                            .foregroundStyle(KORATheme.labelSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }

            HStack(spacing: 8) {
                Spacer()

                Button(SaveLoc.cancel(lang)) {
                    viewModel.dismissClipboard()
                }
                .font(.body)
                .foregroundStyle(KORATheme.labelSecondary)

                Button {
                    viewModel.acceptClipboardURL()
                } label: {
                    Text(SaveLoc.add(lang))
                        .font(.body).fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(KORATheme.accent)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(KORATheme.spacing16)
        .background(KORATheme.background)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusLG))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }

    // MARK: - List Search Bar

    private var listSearchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundStyle(KORATheme.labelTertiary)
            TextField(lang == .japanese ? "場所名で絞り込む" : lang == .english ? "Filter by name..." : lang == .chinese ? "按名称筛选" : "이름으로 검색...", text: $listSearchText)
                .font(.body)
            if !listSearchText.isEmpty {
                Button { listSearchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(KORATheme.labelTertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(KORATheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Category Filter

    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: SaveLoc.allFilter(lang), isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(PlaceCategory.allCases, id: \.self) { cat in
                    FilterChip(
                        title: cat.displayName(language: lang),
                        systemImage: cat.systemImage,
                        isSelected: selectedCategory == cat
                    ) {
                        selectedCategory = cat
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Places List (grouped by station)

    private var placesSection: some View {
        let groups = viewModel.placesGrouped(for: nil, filter: "")

        return Group {
            if groups.isEmpty {
                EmptyStateView(
                    systemImage: "bookmark",
                    title: SaveLoc.emptyTitle(lang),
                    subtitle: SaveLoc.emptySubtitle(lang),
                    actionTitle: SaveLoc.pasteURL(lang)
                ) {
                    showAddSheet = true
                }
                .frame(minHeight: 300)
            } else {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(groups, id: \.station) { group in
                        stationGroupSection(station: group.station, places: group.places)
                    }
                }
                .padding(.bottom, 88)
            }
        }
    }

    private func stationGroupSection(station: String, places: [Place]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !station.isEmpty {
                stationGroupHeader(station: station, count: places.count)
            }

            ForEach(places) { place in
                PlaceCardView(
                    place: place,
                    onRoute: { p in
                        guard !p.nearestStation.isEmpty else { return }
                        NavigationCoordinator.shared.routeTo(station: p.nearestStation)
                    },
                    onTap: { detailPlace = place }
                )
                .contextMenu {
                    Button {
                        editingPlace = place
                    } label: {
                        Label(lang == .japanese ? "編集" : lang == .english ? "Edit" : lang == .chinese ? "编辑" : "수정", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) {
                        viewModel.delete(place)
                    } label: {
                        Label(SaveLoc.delete(lang), systemImage: "trash")
                    }
                }
            }
        }
    }

    private func stationGroupHeader(station: String, count: Int) -> some View {
        let display = MetroLineData.displayName(for: station, language: lang)
        let lines = MetroLineData.linesContaining(station)
        let suffix: String = {
            switch lang {
            case .korean: return "역"
            case .japanese: return "駅"
            case .english: return " Stn."
            case .chinese: return "站"
            }
        }()
        return Button {
            // Tap station header → switch to subway tab with this station as destination
            NavigationCoordinator.shared.routeTo(station: station)
        } label: {
            HStack(spacing: 8) {
                ForEach(lines, id: \.self) { num in
                    Text(MetroLineData.lineBadgeText(num))
                        .font(.caption2).fontWeight(.black)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 4)
                        .background(MetroLineData.lineColor(num))
                        .clipShape(Capsule())
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(display + suffix)
                        .font(.body).fontWeight(.bold)
                        .foregroundStyle(KORATheme.labelPrimary)
                    if lang != .korean && display != station {
                        Text(station + (lang == .japanese ? "駅" : lang == .chinese ? "站" : ""))
                            .font(.caption)
                            .foregroundStyle(KORATheme.labelTertiary)
                    }
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("\(count)")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(KORATheme.labelSecondary)
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.body)
                        .foregroundStyle(KORATheme.accent.opacity(0.5))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.4)
                Text(SaveLoc.loading(lang))
                    .font(.body).fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            .padding(28)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

// MARK: - Add Place Sheet

struct AddPlaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isURLFieldFocused: Bool
    @Bindable var viewModel: SaveViewModel

    @AppStorage("kora.display_language") private var languagePref: String = ""
    private var lang: StationLanguage {
        guard !languagePref.isEmpty, let e = StationLanguage(rawValue: languagePref)
        else { return StationLanguage.resolveFromSystemLocale() }
        return e
    }

    @State private var showURLInput = false

    // OCR
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var isProcessingOCR = false
    @State private var ocrCandidates: [String] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Hero: keyword search on map
                    if !showURLInput && !viewModel.showManualNamePrompt {
                        heroSearchSection
                    }

                    // Shown after Instagram URL triggers manual name prompt
                    if viewModel.showManualNamePrompt {
                        manualNameSection
                    }

                    // Secondary: keyword-only Kakao search (no map)
                    if !viewModel.showManualNamePrompt && showURLInput {
                        urlInputSection
                        kakaoSearchSection
                    }

                    // Toggle between hero and URL-paste view
                    if !viewModel.showManualNamePrompt {
                        Button {
                            withAnimation(.spring(response: 0.25)) { showURLInput.toggle() }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: showURLInput ? "arrow.left.circle" : "link")
                                    .font(.body)
                                Text(showURLInput
                                     ? (lang == .japanese ? "戻る" : lang == .english ? "Back" : lang == .chinese ? "返回" : "돌아가기")
                                     : (lang == .japanese ? "URLから追加" : lang == .english ? "Add from URL" : lang == .chinese ? "从URL添加" : "URL로 추가하기"))
                                    .font(.body).fontWeight(.medium)
                            }
                            .foregroundStyle(KORATheme.labelTertiary)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(SaveLoc.addSheetTitle(lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(SaveLoc.close(lang)) {
                        viewModel.dismissManualPrompt()
                        dismiss()
                    }
                }
            }
        }
        .onAppear { isURLFieldFocused = true }
        .onChange(of: viewModel.showSearchResults) { _, shown in
            if shown { dismiss() }
        }
        .onChange(of: photoPickerItem) { _, item in
            guard let item else { return }
            Task { await processPickedPhoto(item) }
        }
    }

    private var heroSearchSection: some View {
        VStack(spacing: 12) {
            // Search field row
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.body)
                        .foregroundStyle(KORATheme.labelTertiary)
                    TextField(SaveLoc.searchPlaceholder(lang), text: $viewModel.searchQuery)
                        .font(.body)
                        .focused($isURLFieldFocused)
                        .submitLabel(.search)
                        .onSubmit { Task { await viewModel.searchKakao() } }
                    if !viewModel.searchQuery.isEmpty {
                        Button { viewModel.searchQuery = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(KORATheme.labelTertiary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(KORATheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusMD))

                Button {
                    Task { await viewModel.searchKakao() }
                } label: {
                    if viewModel.isSearching {
                        ProgressView().tint(KORATheme.accent).frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(viewModel.searchQuery.isEmpty
                                ? KORATheme.accent.opacity(0.3)
                                : KORATheme.accent
                            )
                    }
                }
                .disabled(viewModel.searchQuery.isEmpty || viewModel.isSearching)
            }

            // Screenshot OCR button
            PhotosPicker(selection: $photoPickerItem, matching: .screenshots) {
                HStack(spacing: 6) {
                    if isProcessingOCR {
                        ProgressView().scaleEffect(0.8).frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "camera.viewfinder")
                            .font(.body).fontWeight(.semibold)
                    }
                    Text(lang == .japanese ? "スクリーンショットから追加"
                         : lang == .english ? "Add from Screenshot"
                         : lang == .chinese ? "从截图添加"
                         : "스크린샷에서 추가")
                        .font(.body).fontWeight(.semibold)
                }
                .foregroundStyle(KORATheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(KORATheme.accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusMD))
            }
            .disabled(isProcessingOCR)

            // OCR candidate chips
            if !ocrCandidates.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(lang == .japanese ? "画像から検出したテキスト"
                         : lang == .english ? "Detected from image"
                         : lang == .chinese ? "从图片中检测到"
                         : "이미지에서 감지된 텍스트")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundStyle(KORATheme.labelTertiary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ocrCandidates, id: \.self) { candidate in
                                Button {
                                    viewModel.searchQuery = candidate
                                    ocrCandidates = []
                                } label: {
                                    Text(candidate)
                                        .font(.body).fontWeight(.medium)
                                        .foregroundStyle(KORATheme.labelPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(KORATheme.surface)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().strokeBorder(KORATheme.accent.opacity(0.3), lineWidth: 1))
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(KORATheme.spacing16)
        .background(KORATheme.background)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusLG))
    }

    // MARK: - OCR

    private func processPickedPhoto(_ item: PhotosPickerItem) async {
        isProcessingOCR = true
        ocrCandidates = []
        defer { isProcessingOCR = false; photoPickerItem = nil }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data),
              let cgImage = uiImage.cgImage else { return }

        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["ko-KR", "ja-JP", "en-US", "zh-Hans"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request])) != nil,
              let observations = request.results as? [VNRecognizedTextObservation]
        else { return }

        let lines = observations.compactMap { $0.topCandidates(1).first?.string }
        let candidates = extractPlaceCandidates(from: lines)
        await MainActor.run { ocrCandidates = candidates }
    }

    private func extractPlaceCandidates(from lines: [String]) -> [String] {
        var seen = Set<String>()
        return lines.compactMap { line -> String? in
            let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
            // Skip hashtags, @mentions, URLs, very long/short strings
            guard !t.hasPrefix("#"), !t.hasPrefix("@"), !t.hasPrefix("http") else { return nil }
            guard t.count >= 2 && t.count <= 20 else { return nil }
            // Skip lines that are purely numbers or punctuation
            let letterCount = t.unicodeScalars.filter { $0.value > 0x20 && !CharacterSet.punctuationCharacters.contains($0) }.count
            guard letterCount >= 2 else { return nil }
            // Deduplicate
            guard seen.insert(t).inserted else { return nil }
            return t
        }
    }

    private var manualNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.body)
                    .foregroundStyle(KORATheme.accent)
                    .padding(.top, 1)
                Text(SaveLoc.instagramHint(lang))
                    .font(.body)
                    .foregroundStyle(KORATheme.labelSecondary)
            }

            // Caption candidate chips (from Share Extension text)
            if let caption = viewModel.pendingCaptionText, !caption.isEmpty {
                let chips = extractPlaceCandidates(from: caption.components(separatedBy: .newlines))
                if !chips.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(lang == .japanese ? "キャプションから検出" : lang == .english ? "From caption" : lang == .chinese ? "从标题检测" : "캡션에서 감지됨")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundStyle(KORATheme.labelTertiary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(chips, id: \.self) { chip in
                                    Button {
                                        viewModel.manualNameInput = chip
                                    } label: {
                                        Text(chip)
                                            .font(.body).fontWeight(.medium)
                                            .foregroundStyle(KORATheme.labelPrimary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(KORATheme.surface)
                                            .clipShape(Capsule())
                                            .overlay(Capsule().strokeBorder(KORATheme.accent.opacity(0.3), lineWidth: 1))
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Name input
            HStack(spacing: 8) {
                Image(systemName: "character.cursor.ibeam")
                    .font(.body)
                    .foregroundStyle(KORATheme.labelTertiary)
                TextField(SaveLoc.searchPlaceholder(lang), text: $viewModel.manualNameInput)
                    .font(.body)
                    .submitLabel(.done)
                if !viewModel.manualNameInput.isEmpty {
                    Button { viewModel.manualNameInput = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(KORATheme.labelTertiary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(KORATheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusMD))

            // Dual action: quick save vs full Kakao search
            HStack(spacing: 10) {
                Button {
                    viewModel.saveQuickLink(name: viewModel.manualNameInput)
                    dismiss()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "bookmark.fill")
                        Text(SaveLoc.quickSave(lang))
                    }
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(viewModel.manualNameInput.isEmpty
                        ? KORATheme.labelTertiary
                        : KORATheme.labelSecondary
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(KORATheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusMD))
                }
                .disabled(viewModel.manualNameInput.isEmpty)

                Button {
                    Task { await viewModel.submitManualName() }
                } label: {
                    HStack(spacing: 5) {
                        if viewModel.isSearching {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                        Text(SaveLoc.searchPlace(lang))
                    }
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(viewModel.manualNameInput.isEmpty
                        ? KORATheme.accent.opacity(0.4)
                        : KORATheme.accent
                    )
                    .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusMD))
                }
                .disabled(viewModel.manualNameInput.isEmpty || viewModel.isSearching)
            }
        }
        .padding(KORATheme.spacing16)
        .background(KORATheme.background)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusLG))
        .overlay(
            RoundedRectangle(cornerRadius: KORATheme.radiusLG)
                .strokeBorder(KORATheme.accent.opacity(0.3), lineWidth: 1)
        )
    }

    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.body)
                        .foregroundStyle(KORATheme.labelTertiary)

                    TextField("https://...", text: $viewModel.urlInput)
                        .font(.body)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .focused($isURLFieldFocused)
                        .submitLabel(.go)
                        .onSubmit {
                            Task { await viewModel.parseURL() }
                        }

                    if !viewModel.urlInput.isEmpty {
                        Button {
                            viewModel.urlInput = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(KORATheme.labelTertiary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(KORATheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusMD))

                Button {
                    Task { await viewModel.parseURL() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(viewModel.urlInput.isEmpty
                            ? KORATheme.accent.opacity(0.3)
                            : KORATheme.accent
                        )
                }
                .disabled(viewModel.urlInput.isEmpty)
            }

            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.body)
                    .foregroundStyle(Color.red)
            }
        }
        .padding(KORATheme.spacing16)
        .background(KORATheme.background)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusLG))
    }

    private var kakaoSearchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(SaveLoc.searchByKeyword(lang))
                .font(.body).fontWeight(.semibold)
                .foregroundStyle(KORATheme.labelSecondary)

            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.body)
                        .foregroundStyle(KORATheme.labelTertiary)

                    TextField(SaveLoc.searchPlaceholder(lang), text: $viewModel.searchQuery)
                        .font(.body)
                        .submitLabel(.search)
                        .onSubmit {
                            Task { await viewModel.searchKakao() }
                        }

                    if !viewModel.searchQuery.isEmpty {
                        Button { viewModel.searchQuery = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(KORATheme.labelTertiary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(KORATheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusMD))

                Button {
                    Task { await viewModel.searchKakao() }
                } label: {
                    if viewModel.isSearching {
                        ProgressView().tint(KORATheme.accent)
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(viewModel.searchQuery.isEmpty
                                ? KORATheme.accent.opacity(0.3)
                                : KORATheme.accent
                            )
                    }
                }
                .disabled(viewModel.searchQuery.isEmpty || viewModel.isSearching)
            }
        }
        .padding(KORATheme.spacing16)
        .background(KORATheme.background)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusLG))
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    var systemImage: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let img = systemImage {
                    Image(systemName: img)
                        .font(.body)
                }
                Text(title)
                    .font(.body).fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? KORATheme.accent : KORATheme.surface)
            .foregroundStyle(isSelected ? .white : KORATheme.labelSecondary)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Parsed Place Confirmation Sheet

struct ParsedPlaceSheet: View {
    let place: Place
    let onSave: () -> Void
    let onDismiss: () -> Void

    @AppStorage("kora.display_language") private var languagePref: String = ""
    private var lang: StationLanguage {
        guard !languagePref.isEmpty, let e = StationLanguage(rawValue: languagePref)
        else { return StationLanguage.resolveFromSystemLocale() }
        return e
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color(hex: "#1D9E75"))
                        Text(SaveLoc.placeInfoFetched(lang))
                            .font(.body).fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#E1F5EE"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    PlaceCardView(place: place)

                    VStack(spacing: 12) {
                        KORAPrimaryButton(SaveLoc.saveToList(lang), icon: "bookmark.fill") {
                            onSave()
                        }
                        KORASecondaryButton(SaveLoc.cancel(lang)) {
                            onDismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(SaveLoc.checkPlace(lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(SaveLoc.close(lang)) { onDismiss() }
                }
            }
        }
    }
}

// MARK: - Kakao Search Results Sheet

struct KakaoSearchResultsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: SaveViewModel

    @AppStorage("kora.display_language") private var languagePref: String = ""
    private var lang: StationLanguage {
        guard !languagePref.isEmpty, let e = StationLanguage(rawValue: languagePref)
        else { return StationLanguage.resolveFromSystemLocale() }
        return e
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle).fontWeight(.thin)
                            .foregroundStyle(KORATheme.labelTertiary)
                        Text(SaveLoc.noResults(lang))
                            .font(.body)
                            .foregroundStyle(KORATheme.labelSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.searchResults) { doc in
                        KakaoResultRow(doc: doc)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.saveFromKakao(doc)
                                dismiss()
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(SaveLoc.searchResults(lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(SaveLoc.cancel(lang)) {
                        viewModel.dismissSearch()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct KakaoResultRow: View {
    let doc: KakaoDocument

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(KORATheme.categoryColor(PlaceCategory.from(kakaoCode: doc.categoryGroupCode)).opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: PlaceCategory.from(kakaoCode: doc.categoryGroupCode).systemImage)
                    .font(.title3)
                    .foregroundStyle(KORATheme.categoryColor(PlaceCategory.from(kakaoCode: doc.categoryGroupCode)))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(doc.placeName)
                    .font(.body).fontWeight(.semibold)
                    .foregroundStyle(KORATheme.labelPrimary)
                Text(doc.displayAddress)
                    .font(.body)
                    .foregroundStyle(KORATheme.labelSecondary)
                    .lineLimit(1)
                if !doc.categoryName.isEmpty {
                    Text(doc.categoryName.components(separatedBy: " > ").last ?? doc.categoryName)
                        .font(.body)
                        .foregroundStyle(KORATheme.labelTertiary)
                }
            }

            Spacer()

            if !doc.distance.isEmpty, let m = Int(doc.distance) {
                Text(m >= 1000 ? String(format: "%.1fkm", Double(m) / 1000) : "\(m)m")
                    .font(.body)
                    .foregroundStyle(KORATheme.labelTertiary)
            }

            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(KORATheme.accent)
        }
        .padding(KORATheme.spacing12)
        .background(KORATheme.background)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusMD))
    }
}

// MARK: - Edit Place Sheet

struct EditPlaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    let lang: StationLanguage
    let viewModel: SaveViewModel

    @State private var name: String
    @State private var category: PlaceCategory
    @State private var nearestStation: String
    @State private var linkedURL: String?
    @State private var clipboardURL: String?

    private let place: Place

    init(place: Place, lang: StationLanguage, viewModel: SaveViewModel) {
        self.place = place
        self.lang = lang
        self.viewModel = viewModel
        _name = State(initialValue: place.name)
        _category = State(initialValue: place.category)
        _nearestStation = State(initialValue: place.nearestStation)
        _linkedURL = State(initialValue: place.sourceURL)
        _clipboardURL = State(initialValue: nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(nameHeader) {
                    TextField(nameHeader, text: $name)
                        .autocorrectionDisabled()
                }

                Section(categoryHeader) {
                    Picker(categoryHeader, selection: $category) {
                        ForEach(PlaceCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName(language: lang), systemImage: cat.systemImage)
                                .tag(cat)
                        }
                    }
                }

                Section(stationHeader) {
                    TextField(stationPlaceholder, text: $nearestStation)
                        .autocorrectionDisabled()
                }

                Section(linkHeader) {
                    if let url = linkedURL {
                        HStack {
                            Text(url)
                                .font(.body)
                                .foregroundStyle(KORATheme.labelSecondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            Button {
                                linkedURL = nil
                                detectClipboard()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    } else if let cbURL = clipboardURL {
                        Button {
                            linkedURL = cbURL
                            clipboardURL = nil
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.body)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(pasteLinkLabel)
                                        .fontWeight(.medium)
                                    Text(cbURL)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                Spacer()
                            }
                            .foregroundStyle(KORATheme.accent)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(noLinkLabel)
                            .foregroundStyle(KORATheme.labelTertiary)
                    }
                }
            }
            .onAppear { detectClipboard() }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(cancelLabel) { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(saveLabel) {
                        var updated = place
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        updated.name = trimmed
                        updated.nameJP = trimmed
                        updated.category = category
                        updated.nearestStation = nearestStation.trimmingCharacters(in: .whitespacesAndNewlines)
                        updated.sourceURL = linkedURL
                        viewModel.update(updated)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func detectClipboard() {
        guard linkedURL == nil else { return }
        let pb = (UIPasteboard.general.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pb.isEmpty, pb.hasPrefix("http"), URL(string: pb) != nil else { return }
        clipboardURL = pb
    }

    private var title: String {
        switch lang {
        case .korean: return "장소 수정"
        case .japanese: return "スポットを編集"
        case .english: return "Edit Place"
        case .chinese: return "编辑地点"
        }
    }
    private var nameHeader: String {
        switch lang {
        case .korean: return "장소 이름"
        case .japanese: return "スポット名"
        case .english: return "Place Name"
        case .chinese: return "地点名称"
        }
    }
    private var categoryHeader: String {
        switch lang {
        case .korean: return "카테고리"
        case .japanese: return "カテゴリ"
        case .english: return "Category"
        case .chinese: return "类别"
        }
    }
    private var stationHeader: String {
        switch lang {
        case .korean: return "가까운 역"
        case .japanese: return "最寄り駅"
        case .english: return "Nearest Station"
        case .chinese: return "最近车站"
        }
    }
    private var stationPlaceholder: String {
        switch lang {
        case .korean: return "강남, 홍대입구..."
        case .japanese: return "江南、弘大入口..."
        case .english: return "Gangnam, Hongik Univ..."
        case .chinese: return "江南、弘大入口..."
        }
    }
    private var saveLabel: String {
        switch lang {
        case .korean: return "저장"
        case .japanese: return "保存"
        case .english: return "Save"
        case .chinese: return "保存"
        }
    }
    private var linkHeader: String {
        switch lang {
        case .korean: return "링크"
        case .japanese: return "リンク"
        case .english: return "Link"
        case .chinese: return "链接"
        }
    }
    private var cancelLabel: String {
        switch lang {
        case .korean: return "취소"
        case .japanese: return "キャンセル"
        case .english: return "Cancel"
        case .chinese: return "取消"
        }
    }
    private var pasteLinkLabel: String {
        switch lang {
        case .korean: return "클립보드 링크 연결"
        case .japanese: return "クリップボードのリンクを追加"
        case .english: return "Attach clipboard link"
        case .chinese: return "添加剪贴板链接"
        }
    }
    private var noLinkLabel: String {
        switch lang {
        case .korean: return "링크 없음"
        case .japanese: return "リンクなし"
        case .english: return "No link"
        case .chinese: return "无链接"
        }
    }
}

#Preview {
    SaveView()
}
