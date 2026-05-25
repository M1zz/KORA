import SwiftUI

struct SaveView: View {
    @State private var viewModel = SaveViewModel()
    @State private var selectedCategory: PlaceCategory? = nil
    @State private var showAddSheet: Bool = false
    @State private var coordinator = NavigationCoordinator.shared

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 0) {
                        // 클립보드 링크 감지 배너
                        if viewModel.showClipboardPrompt {
                            clipboardBanner
                                .padding(.horizontal)
                                .padding(.top, 12)
                                .padding(.bottom, 4)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // 카테고리 필터
                        categoryFilterSection
                            .padding(.top, 8)
                            .padding(.bottom, 8)

                        // 저장된 장소 리스트
                        placesSection
                            .padding(.horizontal)
                    }
                }
                .background(Color(UIColor.systemGroupedBackground))
                .navigationTitle("Save")
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

                // + FAB — 클립보드 배너가 없을 때만 표시
                if !viewModel.showClipboardPrompt {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold))
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
                    .font(.system(size: 22))
                    .foregroundStyle(KORATheme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("リンクが見つかりました")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(KORATheme.labelPrimary)
                    if let url = viewModel.clipboardURL {
                        Text(url)
                            .font(.system(size: 12))
                            .foregroundStyle(KORATheme.labelSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            }

            HStack(spacing: 8) {
                Spacer()

                Button("キャンセル") {
                    viewModel.dismissClipboard()
                }
                .font(.system(size: 13))
                .foregroundStyle(KORATheme.labelSecondary)

                Button {
                    viewModel.acceptClipboardURL()
                } label: {
                    Text("追加")
                        .font(.system(size: 13, weight: .semibold))
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
                FilterChip(title: "すべて", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(PlaceCategory.allCases, id: \.self) { cat in
                    FilterChip(
                        title: cat.displayNameJP,
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
                    title: "まだ保存したスポットがありません",
                    subtitle: "InstagramのURLを貼り付けると\n自動でスポット情報が追加されます",
                    actionTitle: "URLを貼り付ける"
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
                                Label("削除", systemImage: "trash")
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
                Text("スポット情報を取得中...")
                    .font(.system(size: 15, weight: .medium))
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    urlInputSection
                    kakaoSearchSection
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("InstagramのURLを貼り付ける")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .onAppear { isURLFieldFocused = true }
        .onChange(of: viewModel.showSearchResults) { _, shown in
            if shown { dismiss() }
        }
    }

    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .font(.system(size: 15))
                        .foregroundStyle(KORATheme.labelTertiary)

                    TextField("https://instagram.com/p/...", text: $viewModel.urlInput)
                        .font(.system(size: 15))
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
                        .font(.system(size: 36))
                        .foregroundStyle(viewModel.urlInput.isEmpty
                            ? KORATheme.accent.opacity(0.3)
                            : KORATheme.accent
                        )
                }
                .disabled(viewModel.urlInput.isEmpty)
            }

            if let error = viewModel.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.red)
            }
        }
        .padding(KORATheme.spacing16)
        .background(KORATheme.background)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusLG))
    }

    private var kakaoSearchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("キーワードで場所を検索")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(KORATheme.labelSecondary)

            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                        .foregroundStyle(KORATheme.labelTertiary)

                    TextField("城心堂、弘大カフェ...", text: $viewModel.searchQuery)
                        .font(.system(size: 15))
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
                            .font(.system(size: 36))
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
                        .font(.system(size: 12))
                }
                Text(LocalizedStringKey(title))
                    .font(.system(size: 13, weight: .medium))
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 파싱 성공 배너
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(hex: "#1D9E75"))
                        Text("スポット情報を取得しました！")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#E1F5EE"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    PlaceCardView(place: place)

                    VStack(spacing: 12) {
                        KORAPrimaryButton("リストに保存する", icon: "bookmark.fill") {
                            onSave()
                        }
                        KORASecondaryButton("キャンセル") {
                            onDismiss()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("スポットを確認")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { onDismiss() }
                }
            }
        }
    }
}

// MARK: - Kakao Search Results Sheet

struct KakaoSearchResultsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: SaveViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48, weight: .thin))
                            .foregroundStyle(KORATheme.labelTertiary)
                        Text("検索結果がありません")
                            .font(.system(size: 17))
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
            .navigationTitle("検索結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
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
                    .font(.system(size: 18))
                    .foregroundStyle(KORATheme.categoryColor(PlaceCategory.from(kakaoCode: doc.categoryGroupCode)))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(doc.placeName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(KORATheme.labelPrimary)
                Text(doc.displayAddress)
                    .font(.system(size: 12))
                    .foregroundStyle(KORATheme.labelSecondary)
                    .lineLimit(1)
                if !doc.categoryName.isEmpty {
                    Text(doc.categoryName.components(separatedBy: " > ").last ?? doc.categoryName)
                        .font(.system(size: 11))
                        .foregroundStyle(KORATheme.labelTertiary)
                }
            }

            Spacer()

            if !doc.distance.isEmpty, let m = Int(doc.distance) {
                Text(m >= 1000 ? String(format: "%.1fkm", Double(m) / 1000) : "\(m)m")
                    .font(.system(size: 12))
                    .foregroundStyle(KORATheme.labelTertiary)
            }

            Image(systemName: "plus.circle.fill")
                .font(.system(size: 22))
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
