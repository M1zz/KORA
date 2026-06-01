import SwiftUI

struct ShareView: View {
    private var store = PlaceStore.shared
    @State private var selectedPlace: Place? = nil
    @State private var reviews: [Review] = []
    @State private var showWriteReview: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // 커뮤니티 헤더
                    communityHeader
                        .padding(.horizontal)

                    if store.places.isEmpty {
                        emptyState
                            .padding(.horizontal)
                    } else {
                        // 장소 선택
                        placeSelector

                        // 리뷰 리스트
                        reviewsList
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showWriteReview = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(KORATheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showWriteReview) {
                WriteReviewSheet()
            }
            .onAppear {
                if selectedPlace == nil {
                    selectedPlace = store.places.first
                }
            }
        }
    }

    // MARK: - Community Header

    private var communityHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("日本人旅行者のリアルな声")
                    .font(.body).fontWeight(.semibold)
                Text("実際に行った人だけが書けるレビュー")
                    .font(.body)
                    .foregroundStyle(KORATheme.labelSecondary)
            }
            Spacer()
            HStack(spacing: -8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(KORATheme.surface)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(["🗼","⛩️","🦌"][i])
                                .font(.body)
                        )
                        .overlay(Circle().strokeBorder(Color(UIColor.systemBackground), lineWidth: 2))
                }
            }
        }
        .padding(KORATheme.spacing16)
        .background(KORATheme.background)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusLG))
    }

    // MARK: - Place Selector

    private var placeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(store.places) { place in
                    Button {
                        selectedPlace = place
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: place.category.systemImage)
                                .font(.body)
                            Text(place.nameJP)
                                .font(.body).fontWeight(.medium)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedPlace?.id == place.id
                            ? KORATheme.accent
                            : KORATheme.surface
                        )
                        .foregroundStyle(selectedPlace?.id == place.id
                            ? .white
                            : KORATheme.labelSecondary
                        )
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.largeTitle).fontWeight(.thin)
                .foregroundStyle(KORATheme.accent.opacity(0.5))
                .padding(.top, 40)
            Text("まだレビューがありません")
                .font(.body).fontWeight(.semibold)
                .foregroundStyle(KORATheme.labelPrimary)
            Text("Saveタブでスポットを保存すると\nここでレビューを書けます")
                .font(.body)
                .foregroundStyle(KORATheme.labelSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            Spacer()
        }
    }

    // MARK: - Reviews List

    private var reviewsList: some View {
        VStack(spacing: 14) {
            if reviews.isEmpty {
                Text("このスポットのレビューはまだありません")
                    .font(.body)
                    .foregroundStyle(KORATheme.labelSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(reviews) { review in
                    ReviewCardView(review: review)
                }
                KORASecondaryButton("もっと見る", icon: "arrow.down") {}
            }
        }
    }
}

// MARK: - Review Card

struct ReviewCardView: View {
    let review: Review

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(KORATheme.accentLight)
                        .frame(width: 40, height: 40)
                    Text(String(review.authorName.prefix(1)))
                        .font(.body).fontWeight(.semibold)
                        .foregroundStyle(KORATheme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(review.authorName)
                            .font(.body).fontWeight(.semibold)
                        if review.isVerified {
                            Label("訪問済み", systemImage: "checkmark.seal.fill")
                                .font(.body)
                                .foregroundStyle(Color(hex: "#185FA5"))
                        }
                    }
                    Text("\(review.authorRegion)出身")
                        .font(.body)
                        .foregroundStyle(KORATheme.labelSecondary)
                }

                Spacer()

                KORARatingView(rating: review.rating, style: .body)
            }

            // 본문
            Text(review.body)
                .font(.body)
                .foregroundStyle(KORATheme.labelPrimary)
                .lineSpacing(4)

            // 태그
            if !review.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(review.tags, id: \.self) { tag in
                            Text("\(Text(verbatim: tag.emoji + " "))\(Text(LocalizedStringKey(tag.rawValue)))")
                                .font(.body)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(KORATheme.surface)
                                .foregroundStyle(KORATheme.labelSecondary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // 푸터
            HStack {
                Text(review.visitDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.body)
                    .foregroundStyle(KORATheme.labelTertiary)

                Spacer()

                Button {
                } label: {
                    Label("\(review.helpfulCount)人が参考になった", systemImage: "hand.thumbsup")
                        .font(.body)
                        .foregroundStyle(KORATheme.labelSecondary)
                }
            }
        }
        .padding(KORATheme.spacing16)
        .background(KORATheme.background)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusLG))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 1)
    }
}

// MARK: - Write Review Sheet

struct WriteReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var rating: Double = 5.0
    @State private var reviewText: String = ""
    @State private var selectedTags: Set<ReviewTag> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 별점
                    VStack(spacing: 8) {
                        Text("評価")
                            .font(.body).fontWeight(.semibold)
                            .foregroundStyle(KORATheme.labelSecondary)
                        KORARatingView(rating: rating, style: .title)
                        Slider(value: $rating, in: 1...5, step: 0.5)
                            .tint(Color(hex: "#EF9F27"))
                    }
                    .padding()
                    .background(KORATheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusLG))

                    // 태그 선택
                    VStack(alignment: .leading, spacing: 10) {
                        Text("タグを選ぶ")
                            .font(.body).fontWeight(.semibold)
                            .foregroundStyle(KORATheme.labelSecondary)
                        FlowLayout(spacing: 8) {
                            ForEach(ReviewTag.allCases, id: \.self) { tag in
                                Button {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                } label: {
                                    Text("\(Text(verbatim: tag.emoji + " "))\(Text(LocalizedStringKey(tag.rawValue)))")
                                        .font(.body)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedTags.contains(tag)
                                            ? KORATheme.accent
                                            : KORATheme.surface
                                        )
                                        .foregroundStyle(selectedTags.contains(tag)
                                            ? .white
                                            : KORATheme.labelPrimary
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // 본문
                    VStack(alignment: .leading, spacing: 8) {
                        Text("レビューを書く")
                            .font(.body).fontWeight(.semibold)
                            .foregroundStyle(KORATheme.labelSecondary)
                        TextEditor(text: $reviewText)
                            .frame(minHeight: 120)
                            .font(.body)
                            .padding(8)
                            .background(KORATheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusMD))
                    }

                    KORAPrimaryButton("レビューを投稿する") {
                        dismiss()
                    }
                }
                .padding()
            }
            .navigationTitle("レビューを書く")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Flow Layout (태그용)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width {
                y += maxHeight + spacing
                x = 0
                maxHeight = 0
            }
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
        height = y + maxHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                y += maxHeight + spacing
                x = bounds.minX
                maxHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
    }
}

#Preview {
    ShareView()
}
