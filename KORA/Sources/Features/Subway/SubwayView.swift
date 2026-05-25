import SwiftUI
import UIKit
import PDFKit

// MARK: - TransitView

struct SubwayView: View {
    @State private var selectedMode: TransitMode = .subway
    @State private var selectedTab: SubwayTab = .navigator

    enum TransitMode: String, CaseIterable {
        case subway     = "지하철"
        case hangangBus = "한강버스"
    }

    enum SubwayTab: String, CaseIterable {
        case navigator = "経路"
        case lines     = "노선"
        case map       = "路線図"
        case fare      = "料金・時間"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                modePicker
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.systemBackground))

                Divider()

                if selectedMode == .subway {
                    subwayTabPicker
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(UIColor.systemBackground))

                    Divider()

                    subwayTabContent
                } else {
                    HangangBusView()
                }
            }
            .navigationTitle("대중교통")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
            ForEach(TransitMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selectedMode = mode }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 14, weight: selectedMode == mode ? .semibold : .regular))
                        .foregroundStyle(selectedMode == mode ? KORATheme.accent : KORATheme.labelSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedMode == mode
                                ? KORATheme.accent.opacity(0.12)
                                : Color(UIColor.secondarySystemBackground)
                        )
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
    }

    private var subwayTabPicker: some View {
        Picker("", selection: $selectedTab) {
            ForEach(SubwayTab.allCases, id: \.self) { tab in
                Text(LocalizedStringKey(tab.rawValue)).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var subwayTabContent: some View {
        switch selectedTab {
        case .navigator: SubwayNavigatorView()
        case .lines:     SubwayLineBrowserView()
        case .map:       MetroMapView()
        case .fare:      FareInfoView()
        }
    }
}

// MARK: - Metro City

enum MetroCity: String, CaseIterable {
    case seoul = "ソウル"
    case busan = "釜山"
}

// MARK: - Metro Map Language

enum MapLanguage: String, CaseIterable {
    case korean   = "KO"
    case japanese = "JP"
}

// MARK: - Metro Map

struct MetroMapView: View {
    @State private var selectedCity: MetroCity = .seoul
    @State private var mapLang: MapLanguage = .japanese

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                cityPicker
                Spacer()
                if selectedCity == .seoul {
                    mapLanguageToggle
                        .padding(.trailing, 16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))

            Divider()

            mapContent
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private var cityPicker: some View {
        HStack(spacing: 4) {
            ForEach(MetroCity.allCases, id: \.self) { city in
                Button {
                    selectedCity = city
                } label: {
                    HStack(spacing: 6) {
                        if selectedCity == city {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                        }
                        Text(LocalizedStringKey(city.rawValue))
                            .font(.system(size: 14, weight: selectedCity == city ? .semibold : .regular))
                    }
                    .foregroundStyle(selectedCity == city ? KORATheme.accent : KORATheme.labelSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(selectedCity == city ? KORATheme.accent.opacity(0.12) : Color.clear)
                    .clipShape(Capsule())
                }
            }
        }
    }

    private var mapLanguageToggle: some View {
        HStack(spacing: 0) {
            ForEach(MapLanguage.allCases, id: \.self) { lang in
                Button {
                    mapLang = lang
                } label: {
                    Text(lang.rawValue)
                        .font(.system(size: 12, weight: mapLang == lang ? .bold : .regular))
                        .foregroundStyle(mapLang == lang ? .white : KORATheme.labelSecondary)
                        .frame(width: 36, height: 28)
                        .background(mapLang == lang ? KORATheme.accent : Color.clear)
                }
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(KORATheme.separator, lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private var mapContent: some View {
        switch selectedCity {
        case .seoul:
            let resource = mapLang == .japanese ? "subway_jp" : "seoul_metro"
            if let url = Bundle.main.url(forResource: resource, withExtension: "pdf") {
                PDFKitView(url: url)
            } else {
                missingPlaceholder(name: "\(resource).pdf")
            }
        case .busan:
            if let image = UIImage(named: "busan_subway") {
                SubwayMapScrollView(image: image)
            } else {
                missingPlaceholder(name: "busan_subway")
            }
        }
    }

    private func missingPlaceholder(name: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "tram.fill")
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(KORATheme.accent.opacity(0.4))
            Text("路線図が読み込めません")
                .font(.system(size: 17, weight: .semibold))
            Text("「\(name)」をバンドルに追加してください")
                .font(.system(size: 14))
                .foregroundStyle(KORATheme.labelSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Zoomable UIScrollView (for image-based maps)

struct SubwayMapScrollView: UIViewRepresentable {
    let image: UIImage

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 8.0
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .systemBackground

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView

        let doubleTap = UITapGestureRecognizer(target: context.coordinator,
                                               action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        context.coordinator.scrollView = scrollView

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let imageView = context.coordinator.imageView else { return }
        let size = scrollView.bounds.size
        guard size.width > 0, size.height > 0 else { return }

        imageView.frame = CGRect(origin: .zero, size: size)
        scrollView.contentSize = size

        let imgSize = image.size
        guard imgSize.width > 0, imgSize.height > 0 else { return }

        let fitScale = min(size.width / imgSize.width, size.height / imgSize.height)
        scrollView.minimumZoomScale = fitScale
        scrollView.maximumZoomScale = max(fitScale * 8, 4.0)
        if scrollView.zoomScale < fitScale { scrollView.zoomScale = fitScale }
    }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        var imageView: UIImageView?
        weak var scrollView: UIScrollView?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            guard let imageView else { return }
            let bounds = scrollView.bounds.size
            let content = scrollView.contentSize
            imageView.frame.origin = CGPoint(
                x: max((bounds.width  - content.width)  / 2, 0),
                y: max((bounds.height - content.height) / 2, 0)
            )
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView else { return }
            if scrollView.zoomScale > scrollView.minimumZoomScale * 1.1 {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            } else {
                let point = gesture.location(in: imageView)
                scrollView.zoom(to: CGRect(x: point.x - 60, y: point.y - 60,
                                           width: 120, height: 120), animated: true)
            }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true)
        pdfView.backgroundColor = UIColor.systemBackground
        pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit
        pdfView.maxScaleFactor = 8.0

        let doubleTap = UITapGestureRecognizer(target: context.coordinator,
                                               action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        pdfView.addGestureRecognizer(doubleTap)
        context.coordinator.pdfView = pdfView

        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        weak var pdfView: PDFView?

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let pdfView else { return }
            let fitScale = pdfView.scaleFactorForSizeToFit
            if pdfView.scaleFactor > fitScale * 1.1 {
                pdfView.scaleFactor = fitScale
            } else {
                pdfView.scaleFactor = min(fitScale * 3, pdfView.maxScaleFactor)
            }
        }
    }
}

// MARK: - Fare Info

struct FareInfoView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                basicFareCard
                operatingHoursCard
                transferRuleCard
                lineInfoCard
            }
            .padding(16)
            .padding(.bottom, 32)
        }
    }

    private var basicFareCard: some View {
        InfoCard(title: "基本運賃", icon: "creditcard.fill") {
            VStack(spacing: 0) {
                FareHeaderRow()
                Divider()
                FareRow(category: "大人（19歳以上）", card: "1,400", cash: "1,600")
                Divider()
                FareRow(category: "青少年（13-18歳）", card: "720", cash: "1,200")
                Divider()
                FareRow(category: "子供（6-12歳）", card: "450", cash: "800")
                Divider()
                FareRow(category: "未就学（〜5歳）", card: "無料", cash: "無料")
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(KORATheme.separator, lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                BulletText("10km超過：5kmごとに100ウォン追加")
                BulletText("Tマネー・交通カード使用で割引適用")
                BulletText("外国人もTマネー購入・使用可能")
            }
            .padding(.top, 8)
        }
    }

    private var operatingHoursCard: some View {
        InfoCard(title: "運行時間", icon: "clock.fill") {
            VStack(spacing: 8) {
                HoursRow(line: "1〜9号線", first: "05:30頃", last: "翌01:00頃")
                HoursRow(line: "空港鉄道", first: "05:20", last: "翌00:30")
                HoursRow(line: "新盆唐線", first: "05:32", last: "翌00:06")
                HoursRow(line: "京義中央線", first: "05:21", last: "翌00:46")
                HoursRow(line: "水仁盆唐線", first: "05:30", last: "翌00:30")
            }

            VStack(alignment: .leading, spacing: 4) {
                BulletText("始発・終電は路線・駅により異なります")
                BulletText("週末・祝日ダイヤは平日と異なる場合あり")
                BulletText("ソウルメトロ公式アプリで最新情報確認を")
            }
            .padding(.top, 8)
        }
    }

    private var transferRuleCard: some View {
        InfoCard(title: "乗り換えルール", icon: "arrow.triangle.swap") {
            VStack(spacing: 12) {
                TransferItem(icon: "clock", text: "乗り換え可能時間：30分以内（夜間1時間）")
                TransferItem(icon: "arrow.left.arrow.right", text: "地下鉄↔バスの乗り換えも割引適用")
                TransferItem(icon: "number", text: "最大4回まで乗り換え割引")
                TransferItem(icon: "creditcard", text: "交通カード使用時のみ乗り換え割引適用")
                TransferItem(icon: "xmark.circle", text: "同一路線の折り返し乗車は割引不可")
            }
        }
    }

    private var lineInfoCard: some View {
        InfoCard(title: "路線カラーガイド", icon: "tram.fill") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(SeoulMetroLine.allCases, id: \.self) { line in
                    LineChip(line: line)
                }
            }
        }
    }
}

// MARK: - Han River Bus

struct HangangBusView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                overviewCard
                routeCard
                fareCard
                tipsCard
            }
            .padding(16)
            .padding(.bottom, 32)
        }
    }

    private var overviewCard: some View {
        InfoCard(title: "漢江バスとは", icon: "ferry.fill") {
            VStack(alignment: .leading, spacing: 10) {
                Text("漢江バスは、漢江を水上バスで移動できる新しい都市交通です。主要ナルター（乗り場）を結び、観光・通勤の両方に利用できます。")
                    .font(.system(size: 14))
                    .foregroundStyle(KORATheme.labelSecondary)

                HStack(spacing: 20) {
                    StatPill(label: "運航開始", value: "2024年")
                    StatPill(label: "ナルター数", value: "6箇所")
                    StatPill(label: "所要時間", value: "最短15分")
                }
            }
        }
    }

    private var routeCard: some View {
        InfoCard(title: "主要ナルター（乗り場）", icon: "mappin.circle.fill") {
            VStack(spacing: 0) {
                ForEach(HangangStop.allCases.indices, id: \.self) { idx in
                    let stop = HangangStop.allCases[idx]
                    HangangStopRow(stop: stop, isLast: idx == HangangStop.allCases.count - 1)
                }
            }
        }
    }

    private var fareCard: some View {
        InfoCard(title: "運賃", icon: "wonsign.circle.fill") {
            VStack(spacing: 8) {
                FareSimpleRow(label: "大人（一般）", value: "3,000ウォン")
                Divider()
                FareSimpleRow(label: "子供（12歳以下）", value: "1,500ウォン")
                Divider()
                FareSimpleRow(label: "定期券（月）", value: "未定（検討中）")
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(KORATheme.separator, lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                BulletText("地下鉄・バスとの乗り換え割引は現在非対応")
                BulletText("アプリ「漢江バス」で予約・決済が便利")
                BulletText("現場窓口・キオスクでも購入可能")
            }
            .padding(.top, 8)
        }
    }

    private var tipsCard: some View {
        InfoCard(title: "利用のコツ", icon: "lightbulb.fill") {
            VStack(spacing: 12) {
                TransferItem(icon: "sun.max", text: "日没後のナイトクルーズが特に人気")
                TransferItem(icon: "camera", text: "漢江橋からの夜景は絶景スポット")
                TransferItem(icon: "clock", text: "週末は混雑するため早めに乗り場へ")
                TransferItem(icon: "app", text: "公式アプリで混雑状況・時刻表を確認")
                TransferItem(icon: "leaf", text: "自転車持ち込み可能（1台）")
            }
        }
    }
}

// MARK: - Data Models

enum SeoulMetroLine: String, CaseIterable {
    case line1 = "1号線"
    case line2 = "2号線"
    case line3 = "3号線"
    case line4 = "4号線"
    case line5 = "5号線"
    case line6 = "6号線"
    case line7 = "7号線"
    case line8 = "8号線"
    case line9 = "9号線"
    case airport = "空港鉄道"
    case sinbundang = "新盆唐線"
    case gyeongui = "京義中央線"
    case jungang = "京春線"
    case uijeongbu = "議政府軽電鉄"

    var color: Color {
        switch self {
        case .line1:      return Color(red: 0.17, green: 0.46, blue: 0.82)
        case .line2:      return Color(red: 0.21, green: 0.72, blue: 0.31)
        case .line3:      return Color(red: 1.00, green: 0.60, blue: 0.00)
        case .line4:      return Color(red: 0.24, green: 0.64, blue: 0.94)
        case .line5:      return Color(red: 0.51, green: 0.24, blue: 0.73)
        case .line6:      return Color(red: 0.77, green: 0.40, blue: 0.15)
        case .line7:      return Color(red: 0.40, green: 0.55, blue: 0.22)
        case .line8:      return Color(red: 0.87, green: 0.13, blue: 0.42)
        case .line9:      return Color(red: 0.80, green: 0.67, blue: 0.20)
        case .airport:    return Color(red: 0.05, green: 0.58, blue: 0.90)
        case .sinbundang: return Color(red: 0.86, green: 0.06, blue: 0.24)
        case .gyeongui:   return Color(red: 0.47, green: 0.71, blue: 0.47)
        case .jungang:    return Color(red: 0.47, green: 0.71, blue: 0.47)
        case .uijeongbu:  return Color(red: 0.58, green: 0.29, blue: 0.60)
        }
    }
}

enum HangangStop: String, CaseIterable {
    case jamwon    = "蚕院ナルター"
    case yeouido   = "汝矣島ナルター"
    case yanghwa   = "楊花ナルター"
    case nanji     = "난지ナルター"
    case ttukseom  = "뚝섬ナルター"
    case gwangnaru = "広津ナルター"

    var nearbyStation: String {
        switch self {
        case .jamwon:    return "高速ターミナル駅（3・7・9号線）"
        case .yeouido:   return "汝矣島駅（5・9号線）"
        case .yanghwa:   return "合井駅（2・6号線）"
        case .nanji:     return "上岩DMC（6号線）"
        case .ttukseom:  return "纛島駅（2号線）"
        case .gwangnaru: return "天湖駅（5号線）"
        }
    }

    var highlight: String {
        switch self {
        case .jamwon:    return "盤浦大橋噴水ショー近く"
        case .yeouido:   return "63ビル・花火大会会場"
        case .yanghwa:   return "月드リフレクション夜景"
        case .nanji:     return "서울월드컵경기장近く"
        case .ttukseom:  return "漢江公園・自転車道"
        case .gwangnaru: return "아차산등산・家族向き"
        }
    }
}

// MARK: - Reusable Components

struct InfoCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(KORATheme.accent)
                Text(LocalizedStringKey(title))
                    .font(.system(size: 16, weight: .semibold))
            }
            content()
        }
        .padding(16)
        .background(KORATheme.background)
        .clipShape(RoundedRectangle(cornerRadius: KORATheme.radiusLG))
    }
}

struct FareHeaderRow: View {
    var body: some View {
        HStack {
            Text("区分")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("カード")
                .frame(width: 80, alignment: .center)
            Text("現金")
                .frame(width: 80, alignment: .center)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(KORATheme.labelSecondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
    }
}

struct FareRow: View {
    let category: String
    let card: String
    let cash: String

    var body: some View {
        HStack {
            Text(LocalizedStringKey(category))
                .font(.system(size: 13))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(card)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 80, alignment: .center)
            Text(cash)
                .font(.system(size: 13))
                .foregroundStyle(KORATheme.labelSecondary)
                .frame(width: 80, alignment: .center)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemBackground))
    }
}

struct FareSimpleRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(LocalizedStringKey(label))
                .font(.system(size: 13))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(KORATheme.accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(UIColor.systemBackground))
    }
}

struct HoursRow: View {
    let line: String
    let first: String
    let last: String

    var body: some View {
        HStack {
            Text(LocalizedStringKey(line))
                .font(.system(size: 13))
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing, spacing: 2) {
                Text("始発 " + first)
                    .font(.system(size: 11))
                Text("終電 " + last)
                    .font(.system(size: 11))
            }
            .foregroundStyle(KORATheme.labelSecondary)
        }
        .padding(.vertical, 4)
    }
}

struct TransferItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(KORATheme.accent)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(KORATheme.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct BulletText: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.system(size: 12))
                .foregroundStyle(KORATheme.accent)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(KORATheme.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct LineChip: View {
    let line: SeoulMetroLine

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(line.color)
                .frame(width: 10, height: 10)
            Text(LocalizedStringKey(line.rawValue))
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(line.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(KORATheme.accent)
            Text(LocalizedStringKey(label))
                .font(.system(size: 11))
                .foregroundStyle(KORATheme.labelSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HangangStopRow: View {
    let stop: HangangStop
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Color(red: 0.05, green: 0.58, blue: 0.85))
                    .frame(width: 10, height: 10)
                    .padding(.top, 5)
                if !isLast {
                    Rectangle()
                        .fill(Color(red: 0.05, green: 0.58, blue: 0.85).opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(stop.rawValue))
                    .font(.system(size: 14, weight: .semibold))
                Text(stop.nearbyStation)
                    .font(.system(size: 12))
                    .foregroundStyle(KORATheme.labelSecondary)
                Text(stop.highlight)
                    .font(.system(size: 11))
                    .foregroundStyle(KORATheme.accent)
                    .padding(.bottom, isLast ? 0 : 12)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Preview

#Preview {
    SubwayView()
}
