import SwiftUI

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
        switch l { case .korean: return "아직 저장된 장소가 없습니다"; case .japanese: return "まだ保存したスポットがありません"; case .english: return "No saved places yet"; case .chinese: return "还没有保存的地点" }
    }
    static func emptySubtitle(_ l: StationLanguage) -> String {
        switch l { case .korean: return "Instagram URL을 붙여넣으면\n자동으로 장소 정보가 추가됩니다"; case .japanese: return "InstagramのURLを貼り付けると\n自動でスポット情報が追加されます"; case .english: return "Paste an Instagram URL\nto automatically add a place"; case .chinese: return "粘贴Instagram URL\n可自动添加地点信息" }
    }
    static func pasteURL(_ l: StationLanguage) -> String {
        switch l { case .korean: return "URL 붙여넣기"; case .japanese: return "URLを貼り付ける"; case .english: return "Paste URL"; case .chinese: return "粘贴URL" }
    }
    static func delete(_ l: StationLanguage) -> String {
        switch l { case .korean: return "삭제"; case .japanese: return "削除"; case .english: return "Delete"; case .chinese: return "删除" }
    }
    static func loading(_ l: StationLanguage) -> String {
        switch l { case .korean: return "장소 정보 가져오는 중..."; case .japanese: return "スポット情報を取得中..."; case .english: return "Loading place info..."; case .chinese: return "正在获取地点信息..." }
    }
    static func instagramHint(_ l: StationLanguage) -> String {
        switch l {
        case .korean:   return "Instagram 링크를 저장했어요.\n장소명으로 검색해서 저장할 장소를 찾아주세요."
        case .japanese: return "Instagramリンクを保存しました。\n場所名で検索して保存するスポットを探してください。"
        case .english:  return "Instagram link saved.\nSearch by place name to find the spot."
        case .chinese:  return "已保存Instagram链接。\n请用地点名称搜索要保存的地点。"
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
        switch l { case .korean: return "Instagram URL 붙여넣기"; case .japanese: return "InstagramのURLを貼り付ける"; case .english: return "Paste Instagram URL"; case .chinese: return "粘贴Instagram URL" }
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
                    Picker("", selection: $showMap) {
                        Text(SaveLoc.listTab(lang)).tag(false)
                        Text(SaveLoc.mapTab(lang)).tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.systemGroupedBackground))

                    if showMap {
                        PlaceMapView(
                            places: viewModel.places(for: selectedCategory),
                            selectedPlace: $selectedMapPlace
                        )
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                if viewModel.showClipboardPrompt {
                                    clipboardBanner
                                        .padding(.horizontal)
                                        .padding(.top, 12)
                                        .padding(.bottom, 4)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                }
                                categoryFilterSection
                                    .padding(.top, 8)
                                    .padding(.bottom, 8)
                                placesSection
                                    .padding(.horizontal)
                            }
                        }
                        .background(Color(UIColor.systemGroupedBackground))
                    }
                }
                .navigationTitle(SaveLoc.navTitle(lang))
                .navigationBarTitleDisplayMode(.inline)
                .overlay {
                    if viewModel.isLoading {
                        loadingOverlay
                    }
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

                if !viewModel.showClipboardPrompt || showMap {
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
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.25), value: viewModel.showClipboardPrompt)
        .animation(.easeInOut(duration: 0.2), value: showMap)
    }

    private func consumePendingShare() {
        guard let url = coordinator.pendingShareURL, !url.isEmpty else { return }
        coordinator.clearShare()
        viewModel.urlInput = url
        Task { await viewModel.parseURL() }
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

    // MARK: - Places List

    private var placesSection: some View {
        let places = viewModel.places(for: selectedCategory)

        return Group {
            if places.isEmpty {
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
                LazyVStack(spacing: 12) {
                    ForEach(places) { place in
                        PlaceCardView(place: place, onRoute: { p in
                            guard !p.nearestStation.isEmpty else { return }
                            NavigationCoordinator.shared.routeTo(station: p.nearestStation)
                        })
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.delete(place)
                            } label: {
                                Label(SaveLoc.delete(lang), systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.bottom, 88)
            }
        }
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    urlInputSection
                    if viewModel.showManualNamePrompt {
                        manualNameSection
                    }
                    if !viewModel.showManualNamePrompt {
                        kakaoSearchSection
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

                    TextField("https://instagram.com/p/...", text: $viewModel.urlInput)
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

#Preview {
    SaveView()
}
